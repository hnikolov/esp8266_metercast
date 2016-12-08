local modname = "ds18b20"
local M = {}
_G[modname] = M

local table = table
local string = string
local ow = ow
setfenv(1,M)

function readNumber(pin)
  ow.setup(pin)
  ow.reset(pin)
  ow.write(pin, 0xCC, 1)
  ow.write(pin, 0xBE, 1)
  
  local data = ""

  for i = 1, 2 do
    data = data .. string.char(ow.read(pin))
  end
  
  local t = (data:byte(1) + data:byte(2) * 256) / 16
  
  if (t>100) then
    t=t-4096
  end

  ow.reset(pin)
  ow.write(pin,0xcc,1)
  ow.write(pin, 0x44,1)

  return t
end

return M
