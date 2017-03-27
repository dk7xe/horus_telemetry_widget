# horus_telemetry_widget
horus telemetry widget originally by johfla
http://fpv-community.de/showthread.php?47985-LUA-scripts-zum-testen&p=989044&viewfull=1#post989044

Example widget definition for KISS FC

widgetDefinition = {{"rssi1", "battery1"},{"vfas","curr","fuel"}, {"lost", "armed", "timer"}}
defines the following widget:
![](https://github.com/dk7xe/horus_telemetry_widget/blob/master/development/telemetry_widget_kiss.JPG)

To use it u need to 
1) copy the content of the WIDGETS directory to the SD card folder of your Horus.
2) And adjust the widget definition according your model names and needs in the /WIDGETS/Telemetry/main.lua file.
3) To make it finally working with your adjusted settings OpenTX needs to be installed with the "luac" (LUA compile) besides the "lua" option.

![](https://github.com/dk7xe/horus_telemetry_widget/blob/master/development/luac_option.JPG)
