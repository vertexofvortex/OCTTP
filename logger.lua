local component = require("component")
local os = require("os")

local gpu = component.gpu

local logger = {}

function logger.info(s)
  print("[" .. os.date() .. "] [INFO] " .. s)
end

function logger.warn(s)
  local prev_c = gpu.getForeground()

  gpu.setForeground(0xFFFF00)
  print("[" .. os.date() .. "] [WARN] " .. s)
  gpu.setForeground(prev_c)
end

function logger.error(s)
  local prev_c = gpu.getForeground()

  gpu.setForeground(0xFF0000)
  print("[" .. os.date() .. "] [ERROR] " .. s)
  gpu.setForeground(prev_c)
end

return logger
