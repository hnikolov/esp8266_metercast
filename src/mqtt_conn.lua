local module = {}  

local tmr = tmr
local gpio = gpio
local table = table

local HOST = "192.168.2.100"  
local PORT = 1883
local ID = node.chipid()

local LED_RED = 0  -- NodeMCU-12
local LED_BLUE = 4 --

local T_MQTT = 2
local T_FLASH = 3

local m = nil

local TDATA = {}  
local led_status = 0
local mqtt_connected = 0

local function send_table()
  if TDATA[1] == nil then return end
  tmr.stop(T_MQTT)
  gpio.write(LED_BLUE, gpio.LOW)
  m:publish(TDATA[1][1], TDATA[1][2], 0, 0, function(client)
    gpio.write(LED_BLUE, gpio.HIGH)
    tmr.alarm(T_MQTT, 500, 1, send_table)     
  end)
  table.remove(TDATA, 1)
  collectgarbage('collect')
--  print(collectgarbage("count")*1024)
end

local function flash_led()
  gpio.write(LED_RED, led_status)
  if led_status == 0 then led_status = 1
  else                    led_status = 0 end
end

function module.SEND(topic, payload)
  if wifi.sta.status() ~= 5 or wifi.sta.getip() == nil then re_init() end
  if mqtt_connected == 0 then re_init() end
  table.insert(TDATA, {topic, payload})
end

local function re_init()
  tmr.stop(T_FLASH)
  -- disable interrupts
  tmr.stop(T_T)
  gpio.mode(pin1, gpio.OUTPUT)
  gpio.mode(pin2, gpio.OUTPUT)
  gpio.mode(pin3, gpio.OUTPUT)

  m.close()   
  m = nil	
  wifi.sta.disconnect()

  node.restart() 
end

local function register_myself()    
  m:subscribe('power_meter/ping', 0)
end

function module.start()
  tmr.alarm(T_FLASH, 200, 1, flash_led) 
  m = mqtt.Client(ID.."_"..tmr.now(), 120)

  m:on("message", function(conn, topic, payload) 
    gpio.write(LED_RED, gpio.LOW)
    -- Ping request received, send response
    module.SEND(payload, 'power_meter/'..ID)
    gpio.write(LED_RED, gpio.HIGH)
  end)

  m:on("offline", function(con)
    mqtt_connected = 0
    tmr.alarm(T_FLASH, 200, 1, flash_led)
  end)
  
  m:connect(HOST, PORT, 0, 1, function(con)
    mqtt_connected = 1
    tmr.stop(T_FLASH)
    register_myself()
    gpio.write(LED_RED, gpio.HIGH) 
    tmr.alarm(T_MQTT, 500, 1, send_table) -- every 500ms
    application.start()
  end) 
end

return module
