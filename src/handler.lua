local BasePlugin = require "kong.plugins.base_plugin"
local http = require "resty.http"
local cjson = require "cjson"
local kong = kong
local ExternalAuthHandler = BasePlugin:extend()

function ExternalAuthHandler:new()
  ExternalAuthHandler.super.new(self, "kong-ext-auth")
end

function ExternalAuthHandler:access(conf)
  ExternalAuthHandler.super.access(self)
  local client = http.new()
  client:set_timeouts(conf.connect_timeout, conf.send_timeout, conf.read_timeout)

  local res, err = client:request_uri(conf.url, {
    method = conf.method,
    path = conf.path,
    query = kong.request.get_raw_query(),
    headers = kong.request.get_headers(),
    body = kong.request.get_raw_body()
  })
  if not res then
    return kong.response.exit(500, {message=err})
  end
  
  if res.status ~= 200 then
    return kong.response.exit(401, {message="Invalid authentication credentials"})
  end

  local token = cjson.decode(res.body)
  kong.service.request.set_header(conf.header_request, "Bearer " .. token[conf.json_token_key])

end

ExternalAuthHandler.PRIORITY = 900
ExternalAuthHandler.VERSION = "0.2.0"

return ExternalAuthHandler
