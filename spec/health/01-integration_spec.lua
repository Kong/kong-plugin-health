local helpers = require "spec.helpers"


local PLUGIN_NAME = "health"


for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })
      local mock_host = helpers.mock_upstream_host
      local mock_port = helpers.mock_upstream_port

      -- case 1: service.host is not an upstream
      local service1 = bp.services:insert({
        name = "service1",
        host = mock_host,
        port = mock_port,
      })
      local route1 = bp.routes:insert({
        hosts = { "case1.test" },
        service = service1,
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }

      -- case 2: service.host is a healthy  upstream
      local upstream2 = bp.upstreams:insert({
        name = "upstream2",
      })
      bp.targets:insert({
        upstream = upstream2,
        target = mock_host .. ":" .. mock_port,
      })
      local service2 = bp.services:insert({
        name = "service2",
        host = "upstream2",
        port = 80,
      })
      local route2 = bp.routes:insert({
        hosts = { "case2.test" },
        service = service2,
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = {},
      }

      -- case 3: service.host is an unhealthy  upstream
      bp.upstreams:insert({
        name = "upstream3",
      })
      -- no target added, which makes it unhealthy
      local service3 = bp.services:insert({
        name = "service3",
        host = "upstream3",
        port = 80,
      })
      local route3 = bp.routes:insert({
        hosts = { "case3.test" },
        service = service3,
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route3.id },
        config = {},
      }

      -- case 4: service.host is not an upstream, but plugin configured with a upstream-name


      -- start kong
      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }))
    end)


    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)


    before_each(function()
      helpers.clean_logfile()
      client = helpers.proxy_client()
    end)


    after_each(function()
      if client then client:close() end
    end)



    it("throws an error on non-upstream", function()
      local r = client:get("/request", {
        headers = {
          host = "case1.test"
        }
      })
      assert.response(r).has.status(500)
      assert.logfile().has.line("no upstream entity found for hostname '"..helpers.mock_upstream_host.."'")
      -- assert.logfile().has.no.line("no service found for route ")
    end)


    it("return 200 Ok on a healthy upstream", function()
      local r = client:get("/request", {
        headers = {
          host = "case2.test"
        }
      })
      assert.response(r).has.status(200)
      local value = assert.response(r).has.header("Content-Type")
      assert.equal("application/json; charset=utf-8", value)
      local body = assert.response(r).has.jsonbody()
      assert.same({ message = "service is healthy" }, body)
      -- assert.logfile().has.no.line("no upstream entity found for hostname '")
      -- assert.logfile().has.no.line("no service found for route ")
    end)


    it("return 503 Service Unavailable on an unhealthy upstream", function()
      local r = client:get("/request", {
        headers = {
          host = "case3.test"
        }
      })
      assert.response(r).has.status(503)
      local value = assert.response(r).has.header("Content-Type")
      assert.equal("application/json; charset=utf-8", value)
      local body = assert.response(r).has.jsonbody()
      assert.same({ message = "service is unhealthy" }, body)
      -- assert.logfile().has.no.line("no upstream entity found for hostname '")
      -- assert.logfile().has.no.line("no service found for route ")
    end)

  end)

end end
