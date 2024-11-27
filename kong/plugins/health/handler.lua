local plugin = {
  PRIORITY = 2400, -- after bot-detection, before auth plugins
  VERSION = "0.1",
}


local balancers = require "kong.runloop.balancer.balancers"



-- return 200 Ok, 503 Service Unavailable, 500 Internal Server Error
function plugin:access(conf)

  local hostname = conf.upstream_name
  if not hostname then
    local service = kong.router.get_service()
    if not service then
      kong.log.err("no service found for route ", kong.router.get_route().id)
      return kong.response.exit(500)
    end

    hostname = service.host
  end

  local balancer = balancers.get_balancer({ host = hostname }, false)
  if not balancer then
    kong.log.err("no upstream entity found for hostname '", hostname, "'")
    return kong.response.exit(500)
  end

  local balancer_status = balancer:getStatus()
  if balancer_status.healthy then
    return kong.response.exit(200, { message = "service is healthy" })
  else
    return kong.response.exit(503, { message = "service is unhealthy" })
  end
end



return plugin
