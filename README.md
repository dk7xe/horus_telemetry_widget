# horus_telemetry_widget
horus telemetry widget originally by johfla
http://fpv-community.de/showthread.php?47985-LUA-scripts-zum-testen&p=989044&viewfull=1#post989044

To use it u need to copy the content of the WIDGET directory to the SD card folder of your Horus and adjust the widget definition according your model names and needs.

To make it finally working with your adjusted settings OpenTX needs to be installed with the "luac" (LUA compile) option.
![](https://github.com/dk7xe/horus_telemetry_widget/blob/master/development/luac_option.JPG)

Example for KISS FC

widgetDefinition = {{"rssi1", "battery1"},{"vfas","curr","fuel"}, {"lost", "armed", "timer"}}
defines the following widget:
![](https://github.com/dk7xe/horus_telemetry_widget/blob/master/development/telemetry_widget_kiss.JPG)

