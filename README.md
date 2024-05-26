# OCTTP
A simple network protocol implementation for OpenComputers mod. Works under OpenOS.

OCTTP stands for OpenComputers Text Transfer Protocol. Very original, I know.

## Installation
Use `gitrepo` program, which can be installed from OPPM (which can be installed from a floppy), or any other tool you desire to clone this repo. I recommend to put these scripts inside `/lib/octtp/` or `/usr/lib/octtp/` directory, so you can directly `require()` them from your own programs.

`gitrepo` tool is also useful for updating OCTTP library. Just repeat the installation process again and now you have a fresh version.

## Usage
This library consist from two modules: server and client.

### On server
Server module provides a friendly declarative API to create your very own web-server:

```lua
local router = require("octtp/server")

router:GET("/resources/{id}", function(request, params)
    print("Request address:", request.from_addr)
    print("Request port:", request.from_port)
    print("Request ID param:", params.id)

    local response_data = {
        friendly = true,
        convenient = true,
        well_tested = false,
        project_started_date = 1716588944
    }

    return response_data
end)

...
```

You can use the following router methods: `GET`, `POST`, `PUT` and `DELETE`. Method accepts two arguments:
- URL pattern string, which will be used to route the request to a corresponding handler
- a handler callback, which in turn accepts two args: request table and params table (can be `nil` if no URL params are used in the pattern)

A handler function should return one ore two [serializable](https://ocdoc.cil.li/api:serialization) values. First is a response data, second is an error. See example below:

```lua
...

router:POST("/resources/{id}/info", function(request, params)
    print("Request data, name:", request.data.name)
    print("Request data, description:". request.data.description)

    return nil, {
        status = 501,
        error = "This method has not been implemented yet"
    }
end)

...
```

After you finished the endpoints of your API, just run the server:

```lua
...

-- Specify the port number or omit to use the default one (80)
router:run(80)

-- Dont't forget to stop your server!
-- This piece of code will wait for you to press any button:
local _, _, char, code, playername = event.pull("key_down")

-- Otherwise, server's event listener won't be cleared
-- and will remain functional even after the program is terminated!
router:stop()
logger.info("User " .. playername .. " has terminated the server process")
```

### On client
Making requests is even easier than handling them! Look:

```lua
local client = require("octtp/client")
local serialization = require("serialization")

SERVER_ADDRESS = "8278b941-a5c2-48c1-bdef-b4b316d06944"
local response

print("GET /resources/{id}:")
response = client.GET(SERVER_ADDRESS, "/resources/35672")
print(serialization.serialize(response, true))

print("\n")

print("POST /resources/{id}/info with some data:")
response = client.POST(SERVER_ADDRESS, "/resources/35672/info", {
    name = "My new resource",
    description = "For testing purposes only"
})
print(serialization.serialize(response, true))
```

This code will give you output:

```
GET /resources/{id}:
{
    status = 200,
    data = {
        friendly = true,
        convenient = true,
        well_tested = false,
        project_started_date = 1716588944
    }
}

POST /resources/{id}/info with some data:
{
    status = 501,
    error = "This method has not been implemented yet"
}
```

The `data` property is present in succeeded responses only and `error` property is only present in failed responses accordingly. You can check the status of a response by `status` field, which contains an error code implemented by the original HTTP.

But keep in mind, OCTTP client is synchronous and making requests will block the thread execution!