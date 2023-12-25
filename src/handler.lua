local ExternalAuthHandler = {
  VERSION  = "0.2.1",
  PRIORITY = 900,
}
local http = require "resty.http"
local cjson = require "cjson"
local kong = kong

function ExternalAuthHandler:access(config)
  local client = http.new()
  client:set_timeouts(config.connect_timeout, config.send_timeout, config.read_timeout)

  local res, err = client:request_uri(conf.url, {
    method = config.method,
    path = config.path,
    query = kong.request.get_raw_query(),
    headers = kong.request.get_headers(),
    body = kong.request.get_raw_body()
  })
  if not res then
    return kong.response.exit(500, {message=err})
  end
  
  if res.status ~= 200 then
    return kong.response.exit(401, {message="Invalid authentication credentials."})
  end

  local token = cjson.decode(res.body)
  kong.service.request.set_header(config.header_request, "Bearer " .. token[config.json_token_key])

end

return ExternalAuthHandler
