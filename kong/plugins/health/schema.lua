local typedefs = require "kong.db.schema.typedefs"


local schema = {
  name = "health",
  fields = {
    { consumer = typedefs.no_consumer },
    { route = { type = "foreign", reference = "routes", ne = ngx.null, on_delete = "cascade" }, },
    { service = typedefs.no_service },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { upstream_name = typedefs.host {
            required = false,
            description = "Upstream name to check health. If not specified, the hostname of the active 'service' will be used.",
          } },
        },
      },
    },
  },
}

return schema
