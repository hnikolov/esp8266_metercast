application = require("application")
mqtt_conn = require("mqtt_conn")  
set_wifi = require("set_wifi")

set_wifi.start()

set_wifi = nil
package.loaded["set_wifi"] = nil
collectgarbage('collect')
