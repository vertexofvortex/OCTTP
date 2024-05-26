local component = require("component")
local event = require("event")
local serialization = require("serialization")

local modem = component.modem

local client = {}

function client._generateport()
    return math.floor(math.random(49152, 65535))
end

function client._makerequest(addr, endpoint, payload, method)
    local client_port = client._generateport()
    local request

    modem.open(client_port)

    if payload ~= nil then
        request = {
            method = method,
            endpoint = endpoint,
            from_port = client_port,
            data = payload
        }
    else
        request = {
            method = method,
            endpoint = endpoint,
            from_port = client_port,
        }
    end

    local sent = modem.send(addr, 80, serialization.serialize(request))
    local event_name, _, _, _, _, message = event.pull(5, "modem_message")

    modem.close(client_port)

    if sent == false then
        return {
            status = -1,
            error = "Not Sent"
        }
    end

    if event_name == nil then
        return {
            status = 408,
            error = "Request Timeout"
        }
    end

    local response = serialization.unserialize(message)

    return response
end

function client.GET(addr, endpoint)
    return client._makerequest(addr, endpoint, nil, "GET")
end

function client.POST(addr, endpoint, payload)
    return client._makerequest(addr, endpoint, payload, "POST")
end

function client.PUT(addr, endpoint, payload)
    return client._makerequest(addr, endpoint, payload, "PUT")
end

function client.DELETE(addr, endpoint)
    return client._makerequest(addr, endpoint, nil, "DELETE")
end

return client
