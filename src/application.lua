local module = {}

local tmr = tmr
local gpio = gpio

local pin1 = 1 -- D1, GPIO5
local pin2 = 2 -- D2, GPIO4
local pin3 = 3 -- D3, GPIO0
local pin5 = 5 -- D5, GPIO14

local LED_RED = 0  -- NodeMCU-12
local LED_BLUE = 4 --

local T_T = 4
local T_E = 5
local T_G = 6
local T_W = 0

local c_timer = 2147483648 -- 31-bit timer, roll back to 0
local last_time = tmr.now()

function onElectricity()
  if gpio.read(pin1) == 1 then
    local now = tmr.now()
    local period = now - last_time
    if period <= 0 then period = period + c_timer end
    period = period / 1000000 -- Sec
    last_time = now
    mqtt_conn.SEND('power_meter/electricity', period)
  end
end

function onGas()
  if gpio.read(pin3) == 1 then
    mqtt_conn.SEND('power_meter/gas', 1)
  end
end

function onWater()
  if gpio.read(pin2) == 0 then
    mqtt_conn.SEND('power_meter/water', 1)
  end
  gpio.mode(pin2, gpio.INT)
  gpio.trig(pin2, 'down', function()
    gpio.mode(pin2, gpio.OUTPUT)
    tmr.alarm(T_W, 1000, tmr.ALARM_SINGLE, onWater) 
  end)
end

function onTemperature()
  local t = require("ds18b20")
  local tempC = t.readNumber(pin5)
  t = nil
  ds18b20 = nil
  package.loaded["ds18b20"] = nil
  collectgarbage('collect')
  mqtt_conn.SEND('power_meter/temperature', tempC)
end

function module.start()
  tmr.alarm(T_T, 60000, 1, onTemperature)
  
  gpio.mode(pin1, gpio.INT)
  gpio.trig(pin1, 'up', function() tmr.alarm(T_E, 100, tmr.ALARM_SINGLE, onElectricity) end)

  gpio.mode(pin3, gpio.INT)
  gpio.trig(pin3, 'up', function() tmr.alarm(T_G, 100, tmr.ALARM_SINGLE, onGas) end)

  gpio.mode(pin2, gpio.INT)
  gpio.trig(pin2, 'down', function() 
    gpio.mode(pin2, gpio.OUTPUT)
    tmr.alarm(T_W, 1000, tmr.ALARM_SINGLE, onWater) 
  end)
end

gpio.mode(LED_BLUE, gpio.OUTPUT)

return module
