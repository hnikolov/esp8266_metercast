local module = {}

local wifi = wifi
local tmr = tmr
local gpio = gpio

local SSID = {}  
SSID["H368N76C083"] = "CE7793554CC2"

local LED_RED = 0  -- NodeMCU-12
local LED_BLUE = 4 --

local T_WIFI = 1

local function wifi_wait_ip()  
  if wifi.sta.getip() ~= nil then
    gpio.write(LED_RED, gpio.HIGH)
    tmr.stop(T_WIFI)
    mqtt_conn.start()
  end
end

local function wifi_start(list_aps) 
  if list_aps then
    for key,value in pairs(list_aps) do
      if SSID and SSID[key] then
        wifi.setmode(wifi.STATION);
        wifi.sta.config(key, SSID[key], 0) -- No autoconnect
        wifi.sta.connect()
        tmr.alarm(T_WIFI, 2500, 1, wifi_wait_ip)
        SSID = nil
      end
    end
  end
end

function module.start()
  gpio.write(LED_RED, gpio.LOW) -- 'on' while connecting
  wifi.setmode(wifi.STATION)
  wifi.sta.getap(wifi_start)
end

return module
