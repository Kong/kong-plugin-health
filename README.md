[![Unix build](https://img.shields.io/github/actions/workflow/status/Kong/kong-plugin-health/test.yml?branch=master&label=Test&logo=linux)](https://github.com/Kong/kong-plugin-health/actions/workflows/test.yml)
[![Luacheck](https://github.com/Kong/kong-plugin-health/workflows/Lint/badge.svg)](https://github.com/Kong/kong-plugin-health/actions/workflows/lint.yml)

kong-plugin-health
==================

Kong plugin to expose `upstream` health as an endpoint.


The status of Kong health-checks is exposed through the status-api. But this is only for internal users to consume. This plugin can be used to expose the health of a loadbalancer (`upstream` entity) on an endpoint to Kong clients.

To enable the plugin, create a route, for example on path `"/healthcheck"`. Then configure the plugin on this path.

When invoked the plugin will;

1. collect the currently active `service` entity
2. from the `service` it will collect the `host`
3. it will lookup the `upstream` entity that matches the `host` name
4. it will check the health status of the selected `upstream`
5. it will return "200 Ok" if the upstream is healthy, or "503 Service Unavailable" if the upstream is unhealthy.

Good to know:

- it has a single configuration property; `upstream_name`, if set, it will report the health of that specific `upstream` entity, instead of the currently active one
- it can only be configured on a `route` (no service, nor consumer)
- it will return a 500 (and log an error) if the `route` doesn't have a `service`
- it will return a 500 (and log an error) if the `host` doesn't refer to an `upstream`

