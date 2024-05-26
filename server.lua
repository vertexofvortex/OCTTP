local component = require("component")
local event = require("event")
local serialization = require("serialization")
local utils = require('utils')

local logger = require("logger")

local modem = component.modem

local router = {}

router._listenerId = nil
router._enabled = true

router._handlers = {
  GET = {},
  POST = {},
  PUT = {},
  DELETE = {},
}

router._handlers_method_metatable = {
  __index = function(self, url)
    for url_pattern, handler in pairs(self) do
      if utils.matchurl(url, url_pattern) then
        return { handler = self[url_pattern], url_pattern = url_pattern }
      end
    end

    return nil
  end
}

function router._init()
  for _, handlers in pairs(router._handlers) do
    setmetatable(handlers, router._handlers_method_metatable)
  end
end

function router._serverequest(x, y, from_addr, z, v, message)
  local result, err = pcall(function()
    if message == nil then
      logger.warn("Request does not contain any data. Ignoring")

      return
    end

    local request = serialization.unserialize(message)

    if request == nil or request.method == nil or request.endpoint == nil or request.from_port == nil then
      logger.warn("[" ..
        string.sub(from_addr, 0, 6) ..
        ":" .. request.from_port .. "] One ore more of the required fields are missing from the request. Ignoring")

      if request.endpoint ~= nil then
        modem.send(from_addr, request.from_port, serialization.serialize({
          status = 400,
          error = "Bad Request"
        }))
      end

      return
    end

    request.from_addr = from_addr

    if router._handlers[string.upper(request.method)] == nil then
      logger.warn("[" ..
        string.sub(from_addr, 0, 6) .. ":" .. request.from_port .. "] Unknown request method: " .. request.method)
      modem.send(from_addr, request.from_port, serialization.serialize({
        status = 405,
        error = "Method Not Allowed"
      }))

      return
    end

    if router._handlers[string.upper(request.method)][request.endpoint] == nil then
      logger.warn("[" ..
        string.sub(from_addr, 0, 6) .. ":" .. request.from_port .. "] Endpoint " .. request.endpoint .. " not found")
      modem.send(from_addr, request.from_port, serialization.serialize({
        status = 404,
        error = "Not Found"
      }))

      return
    end

    local handler_search_result = router._handlers[string.upper(request.method)][request.endpoint]
    local response_data, response_error

    if type(handler_search_result) == "table" then
      response_data, response_error = handler_search_result.handler(request,
        utils.parseurlparams(request.endpoint, handler_search_result.url_pattern))
    end

    if type(handler_search_result) == "function" then
      response_data, response_error = handler_search_result(request, {})
    end

    if response_error == nil then
      modem.send(from_addr, request.from_port, serialization.serialize({
        status = 200,
        data = response_data
      }))

      logger.info("[" ..
        string.sub(from_addr, 0, 6) ..
        ":" .. request.from_port .. "] [" .. request.method .. "] [" .. 200 .. "] " .. request.endpoint)
    else
      modem.send(from_addr, request.from_port, serialization.serialize(response_error))

      logger.info("[" ..
        string.sub(from_addr, 0, 6) ..
        ":" .. request.from_port .. "] [" .. request.method .. "] [" .. response_error.status .. "] " .. request
        .endpoint)
    end
  end)

  if err ~= nil then
    -- TODO: make 500 response
    logger.error("Fatal error occured: " .. err)
    logger.info("Router recovered")
  end
end

function router:run(port)
  router._init()

  if port == nil then port = 80 end

  modem.open(port)
  print("The server is listening for requests on " .. port .. " port")

  self._listenerId = event.listen("modem_message", router._serverequest)
end

function router:stop()
  event.cancel(router._listenerId)
end

function router:GET(url, handler)
  self._handlers.GET[url] = handler
end

function router:POST(url, handler)
  self._handlers.POST[url] = handler
end

function router:PUT(url, handler)
  self._handlers.PUT[url] = handler
end

function router:DELETE(url, handler)
  self._handlers.DELETE[url] = handler
end

return router
