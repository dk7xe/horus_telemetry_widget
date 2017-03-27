
-- ######################################################
-- ## Script by dk7xe.g                                ##
-- ## V 1.2, 2017/03/23                                ## 
-- ##                                                  ##
-- ## based on Script by johfla                        ##
-- ##                                                  ##
-- ## Dynamic design via initial values and functions  ##
-- ## Some of the Widgets based on work by Ollicious   ##
-- ##							                 ##
-- ######################################################


local transparency = 1				-- Hintergrund transparent
local imagePath = "/WIDGETS/Telemetry/images/"  -- Pfad zu den Bildern auf der SD-Card

local col_std = BLACK			-- standard value color: `WHITE`,`GREY`,`LIGHTGREY`,`DARKGREY`,`BLACK`,`YELLOW`,`BLUE`,`RED`,`DARKRED`
local col_min = BLUE				-- standard min value color
local col_max = YELLOW				-- standard max value color
local col_alm = RED					-- standard alarm value color

local homeLat = 0     -- L?ngengrad der Home Position
local homeLon = 0	-- Breitengrad der Home Position  

-- Parameter f?r die Schriftgr??e und Korrekturfaktoren der Werte und Einheiten
local modeSize = {sml = SMLSIZE, mid = MIDSIZE, dbl = DBLSIZE}
local modeAlign = {ri = RIGHT, le = LEFT}
local yCorr = {sml = 16, mid = 8,  dbl = 0}
local xCorr = {value = 0.75, value1 = 0.50, center = 7}

local options = {
	{ "Akku", VALUE, 1300, 800, 1800 }	-- Wert f?r die Kapazit?t des Akkus, f?r Widget fuel
}

function create(zone, options)
	local thisZone  = { zone=zone, options=options }
		lipoCapa = thisZone.options.Akku
		widget()
	return thisZone
end

function update(thisZone, options)
  thisZone.options = options
end

-- #################### Definition der Widgets #################
-- Definition der angezeigten Telemetrie-Werte in Abh?ngigkeit des aktiven Modells
-- Der Modellname und die Telemetriewerte m?ssen auf die eigenen Bed?rfnisse angepasst werden

function widget()
	local switchPos = getValue("sg")
	modelName = model.getInfo().name
	
	if modelName == "Xugong" and switchPos <= 0 then
		-- Naza V2
		widgetDefinition = {{"gps","battery1"},{"fm1","dist1","alt","speed"}, {"rssi1", "heading", "timer", "latlon"}}
	elseif modelName == "Xugong" and switchPos > 0 then
		-- Naza V2
		widgetDefinition = {{"gps","battery1"},{"fm1","dist1","alt","speed"}, {"rssi1", "dist", "timer", "latlon"}}
	elseif modelName == "RQR-HoneyBadger" or "RQR-Hive      1" or "RQR-Hive      2" then
		-- Kiss FC
		widgetDefinition = {{"rssi1", "battery1"},{"vfas","curr","fuel"}, {"lost", "armed", "timer"}}
	else
	--local widgetDefinition = {{"vfas","timer","curr","fuel"},{"fm1","alt","speed"}, {"timer","curr"}}

	end
end

------------------
-- Telemetry ID --
------------------
local function getTelemetryId(name)
	field = getFieldInfo(name)
	if field then
	  return field.id
	else
	  return -1
	end
end

---------------
-- Get Value --
--------------- 
local function getValueOrDefault(value)
	local tmp = getValue(value)
	
	if tmp == nil then
		return 0
	end
	
	return tmp
end

----------------------
-- Get Value Rounded--
---------------------- 
local function round(num, decimal)
    local mult = 10^(decimal or 0)
    return math.floor(num * mult + 0.5) / mult
 end

------------------------------------
-- Get Value from AnySense for Naza V2 --
------------------------------------
local function anyFuel()
	local fuel = getValueOrDefault("Fuel")

	local myLS1 = { func=1 ; v1=31 ; v2=100 ; v3=0 ; ["and"]=0; delay=0; duration=0}
	local myLS0 = { func=1 ; v1=31 ; v2=0 ; v3=0 ; ["and"]=0; delay=0; duration=0}

	
	sats = fuel % 100 
	fuel = math.floor((fuel - sats) / 100)

	satfix = fuel % 10
	fuel = math.floor((fuel - satfix) / 10)
	
	fmode = fuel % 10
	fuel = math.floor((fuel - fmode) / 10)
				
	armed = bit32.band(fuel, 1) == 1
	homeSet = bit32.band(fuel, 2) == 2
	
	--Logischer Schalter f?r Timer Ein/Aus, LS64/INPUT30
	if armed then
		model.setLogicalSwitch(63,myLS1) 
	else 
		model.setLogicalSwitch(63,myLS0)
	end
end


-- ############################# Widgets #################################

------------------------------------------------- 
-- Voltage Lipo	------------------------- vfas --
------------------------------------------------- 
local function vfasWidget(xCoord, yCoord, cellHeight, name)
	local myVoltage = getValueOrDefault("VFAS") 
	local myMinVoltage = getValueOrDefault("VFAS-")
			
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
		
	lcd.drawText(xCoord + 4, yCoord + 2, "Spannung", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMinVoltage,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myVoltage,2), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "V", modeSize.sml + modeAlign.le)
end

-------------------------------------------------  
-- Fuel --------------------------------- fuel --
------------------------------------------------- 
local function fuelWidget(xCoord, yCoord, cellHeight, name)
	local myFuel = getValueOrDefault("Fuel")
	local myFuelID = getTelemetryId("Fuel")
		
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	
	if myFuel > lipoCapa * 0.8 then
		lcd.setColor(CUSTOM_COLOR, col_alm)
	else
		lcd.setColor(CUSTOM_COLOR, col_std)
	end
		
	lcd.drawText(xCoord + 4, yCoord + 2, "Verbrauch", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, round(myFuel), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "mAh", modeSize.sml + modeAlign.le)
end

-------------------------------------------------  
-- Current ------------------------------ curr --
------------------------------------------------- 
local function currWidget(xCoord, yCoord, cellHeight, name)
	local myCurrent = getValueOrDefault("Curr")
	local myMaxCurrent = getValueOrDefault("Curr+")
				
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
		
	lcd.drawText(xCoord + 4, yCoord + 2, "Strom", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMaxCurrent,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myCurrent,2), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "A", modeSize.sml + modeAlign.le)
end

-------------------------------------------------  
-- RxBat ------------------------------- rxbat --
------------------------------------------------- 
local function rxbatWidget(xCoord, yCoord, cellHeight, name)
	local myRxBat = getValueOrDefault("RxBt")
	local myMinRxBat = getValueOrDefault("RxBt-")
	
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
		
	lcd.drawText(xCoord + 4, yCoord + 2, "RxBat", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMinRxBat,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myRxBat,1), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "V", modeSize.sml + modeAlign.le)
end

------------------------------------------------- 
-- Speed ------------------------------- speed --
------------------------------------------------- 
local function speedWidget(xCoord, yCoord, cellHeight, name)

	local mySpeed = getValueOrDefault("GSpd") * 1.852 -- Umrechnung von Knoten in kmh
	local myMaxSpeed = getValueOrDefault("GSpd+") * 1.852 
		
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xCoord + 4, yCoord + 2, "Geschw.", SMLSIZE)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMaxSpeed,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(mySpeed,1), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "kmh", modeSize.sml + modeAlign.le) 
end

------------------------------------------------- 
-- Vertical Speed --------------------- vspeed --
-------------------------------------------------
local function vspeedWidget(xCoord, yCoord, cellHeight, name)
	local myVSpeed = getValueOrDefault("VSpd")
	local myMaxVSpeed = getValueOrDefault("VSpd+") 
		
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xCoord + 4, yCoord + 2, "Steigen", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMaxVSpeed,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myVSpeed,1), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "m/s", modeSize.sml + modeAlign.le) 
end

------------------------------------------------- 
-- RPM ----------------------------------- rpm --
-------------------------------------------------
local function rpmWidget(xCoord, yCoord, cellHeight, name)
	local myRpm = getValueOrDefault("RPM")
	local myMaxRpm = getValueOrDefault("RPM+") 
		
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xCoord + 4, yCoord + 2, "RPM", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMaxRpm,0), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myRpm,0), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "UpM", modeSize.sml + modeAlign.le) 
end

------------------------------------------------- 
-- Timer ------------------------------- timer --
------------------------------------------------- 
local function timerWidget(xCoord, yCoord, cellHeight, name)
	local teleV_tmp = model.getTimer(0) -- Timer 1
	local myTimer = teleV_tmp.value
	
	local minute = math.floor(myTimer/60)
	local sec = myTimer - (minute*60)
	if sec > 9 then
		valTxt = string.format("%i",minute)..":"..string.format("%i",sec)
	else
		valTxt = string.format("%i",minute)..":0"..string.format("%i",sec)
	end 
	
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xCoord + 4, yCoord + 2, "Flugzeit", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "m:s", modeSize.sml + modeAlign.le) 
end

------------------------------------------------- 
-- Alt ----------------------------- alt --
-------------------------------------------------
local function altWidget(xCoord, yCoord, cellHeight, name)
	local myAlt = getValueOrDefault("Alt")
	local myMaxAlt = getValueOrDefault("Alt+")
	
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xCoord + 4, yCoord + 2, "Hoehe", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMaxAlt,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myAlt,1), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "m", modeSize.sml + modeAlign.le) 
end

------------------------------------------------- 
-- Flightmode ------------------------ fm, fm1 --
------------------------------------------------- 
local function fmWidget(xCoord, yCoord, cellHeight, name)
	local modeDesc = {[0]="Manual", [1]="GPS", [2]="RTH", [3]="ATTI"}
	
	if name == "fm" then --set by Naza V2
		local flm,FM = getFlightMode()	-- FlightMode
		valTxt = FM
	else --set by AnySense
		valTxt = modeDesc[fmode]
	end
		
	if valTxt == "CAL" then		-- Kalibrierungsmodus bei Seglern
		xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.dbl
		lcd.setColor(CUSTOM_COLOR, col_alm)
		Size = modeSize.dbl
	else
		xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.mid
		lcd.setColor(CUSTOM_COLOR, col_std)
		Size = modeSize.mid
	end
				
	lcd.drawText(xCoord + 4, yCoord + 2, "Mode [SB]", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, Size  + CUSTOM_COLOR)
end

------------------------------------------------- 
-- Armed/Disarmed (Switch) ------------- armed --
------------------------------------------------- 
local function armedWidget(xCoord, yCoord, cellHeight, name)
	local switchPos = getValueOrDefault("sf")
	if switchPos < 0 then
		valTxt = "Disarmed"
		lcd.setColor(CUSTOM_COLOR, col_std)	
	else
		valTxt = "Armed" 
		lcd.setColor(CUSTOM_COLOR, col_alm)	
	end
	
	xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.mid
		
	lcd.drawText(xCoord + 4, yCoord + 2, "Motor", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.mid  + CUSTOM_COLOR) 
end

------------------------------------------------- 
-- Lost Copter sound (Switch) ----------- lost --
------------------------------------------------- 
local function lostWidget(xCoord, yCoord, cellHeight, name)
	local switchPos = getValueOrDefault("sd")
	if switchPos <= 0 then
		valTxt = "Beep off"
		lcd.setColor(CUSTOM_COLOR, col_std)	
	else
		valTxt = "Beep SOS" 
		lcd.setColor(CUSTOM_COLOR, col_alm)	
	end
		
	xTxt1 = xCoord + cellWide*0.5 - (xCorr.center * string.len(valTxt)); yTxt1 = cellHeight + yCorr.mid
		
	lcd.drawText(xCoord + 4, yCoord + 2, "LostSnd [SD]", modeSize.sml) 
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.mid  + CUSTOM_COLOR) 
end


------------------------------------------------- 
-- Distance-OpenTx ---------------------- dist --
------------------------------------------------- 
local function distWidget(xCoord,yCoord, cellHeight, name)
	local myDistance = getValueOrDefault("Dist")
	local myMaxDistance = getValueOrDefault("Dist+") 
	--local myDistance = getValueOrDefault (212)
	
	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xCoord + 4, yCoord + 2, "Entf. OTx", modeSize.sml)
	lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMaxDistance,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myDistance), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "m", modeSize.sml + modeAlign.le) 
end

------------------------------------------------- 
--- Distance calculated	---------------- dist1 --
------------------------------------------------- 
local function distCalcWidget(xCoord, yCoord, cellHeight, name)
	local myLatLon = getValueOrDefault("GPS")
	
	
	if type(myLatLon) == "table" and myLatLon["lat"] * myLatLon["lon"] ~= 0 then
		LocationLat = myLatLon["lat"]
		LocationLon = myLatLon["lon"]
	else
		LocationLat = 0
		LocationLon = 0
	end

	if homeSet and armed and homeLat==0 then
		homeLat = LocationLat
		homeLon = LocationLon
	end
			
	-- Distanz berechnen
	local d2r = math.pi/180
	local d_lon = (LocationLon - homeLon) * d2r ;
	local d_lat = (LocationLat - homeLat) * d2r ;
	local a = math.pow(math.sin(d_lat/2.0), 2) + math.cos(homeLat*d2r) * math.cos(LocationLat*d2r) * math.pow(math.sin(d_lon/2.0), 2);
	local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
	local myDistance = 6371000 * c;

	xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	
	if not armed or not homeSet then
		homeLat = 0
		homeLon = 0
		myDistance = 0
		myMaxDistance = 0
	end
	
	if myMaxDistance < myDistance then myMaxDistance = myDistance end
	
	lcd.setColor(CUSTOM_COLOR, col_std)
	
		
	lcd.drawText(xCoord + 4, yCoord + 2, "Entf. Ber.", modeSize.sml)
	lcd.drawText(xCoord  + cellWide - 5, yCoord + 2, round(myMaxDistance,1), modeSize.sml + modeAlign.ri)
	lcd.drawText(xTxt1, yTxt1, round(myDistance), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "m", modeSize.sml + modeAlign.le)
end

---------------------------------- 
-- GPS Koordinaten        3/4 Widget --
----------------------------------
local function LatLonWidget(xCoord,yCoord, cellHeight, name)

	local LocationLat, LocationLon			-- GPS coord
	local LocLat_txt = ""					-- tmp txt var
	local LocLon_txt = ""					-- tmp txt var
	local preLat = ""						-- filler spce
	local preLon ="" 						-- filler spce
	
	local myLatLon = getValueOrDefault("GPS")
	
	if type(myLatLon) == "table" and myLatLon["lat"] * myLatLon["lon"] ~= 0 then
		LocationLat = myLatLon["lat"]
		LocationLon = myLatLon["lon"]
	else
		LocationLat = 102.12356
		LocationLon = 25.12356
	end
	
		-- check if lat <10 and build substring
	if LocationLat < 10 then
			LocLat_txt = string.sub(LocationLat,3 ,4) .. "." .. string.sub(LocationLat,5 ,8)
			preLat = "  "
	elseif LocationLat < 100 then
			LocLat_txt = string.sub(LocationLat,4 ,5) .. "." .. string.sub(LocationLat,6 ,9)
			preLat = " "
	else
			LocLat_txt = string.sub(LocationLat,5 ,6) .. "." .. string.sub(LocationLat,7 ,10)
	end

		-- check if lon <10 and build substring
	if LocationLon < 10 then
		LocLon_txt = string.sub(LocationLon,3 ,4) .. "." .. string.sub(LocationLon,5 ,8)
		preLon = "  "
	elseif LocationLon < 100 then
		LocLon_txt = string.sub(LocationLon,4 ,5) .. "." .. string.sub(LocationLon,6 ,9)
		preLon = " "
	else
		LocLon_txt = string.sub(LocationLon,5 ,6) .. "." .. string.sub(LocationLon,7 ,10)
	end
	
	local gpsLat = preLat .. string.format("%i",math.floor(LocationLat)).. "'" .. LocLon_txt .. "  "
	local gpsLon = preLon .. string.format("%i",math.floor(LocationLon)).. "'" .. LocLon_txt .. "  "
	
	
	xTxt1 = xCoord + 15; yTxt1 = yCoord + 10; xTxt2 = xCoord + 140; yTxt2 = yCoord + 35
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xTxt1, yTxt1, "Lat: ", modeSize.sml + modeAlign.le)
	lcd.drawText(xTxt1, yTxt2, "Lon: ", modeSize.sml + modeAlign.le) 
	lcd.drawText(xTxt2, yTxt1, "  " .. gpsLat, modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt2, yTxt2, "  " .. gpsLon, modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
end

------------------------------------------------- 
-- Battery ----------------- battery, battery1 --
-------------------------------------------------
local function batteryWidget(xCoord, yCoord, cellHeight, name)
	local myVoltage = getValueOrDefault("VFAS") 
	local fourLow = 13.4     -- 4 cells 4s | Warning
    local fourHigh = 16.8    -- 4 cells 4s
    local threeLow = 10.4    -- 3 cells 3s | Warning
    local threeHigh = 12.6   -- 3 cells 3s
	local battCell = "4S"
	local battType = 3
	local myPercent = 0
    	
	if myVoltage > 3 then
        battType = math.ceil(myVoltage/4.25)
		if battType == 4 then
			battCell = "4S"
			myPercent = math.floor((myVoltage-fourLow) * (100/(fourHigh-fourLow)))
		end
		if battType == 3 then
			battCell = "3S"
			myPercent = math.floor((myVoltage-threeLow) * (100/(threeHigh-threeLow)))
		end
	end
	
	lcd.drawText(xCoord + 4, yCoord + 2, "Lipo", modeSize.sml)
		
	if name == "battery" then
		xTxt1 = xCoord+(cellWide * 0.5)-50; yTxt1 = cellHeight + 55; xTxt2 = xCoord + (cellWide/2)-25; yTxt2 = cellHeight+90; 
		lcd.setColor(CUSTOM_COLOR, col_std)
			
		lcd.drawText(xTxt1, yTxt1, battCell.."-"..lipoCapa, modeSize.mid + CUSTOM_COLOR)
		lcd.drawText(xTxt2, yTxt2, myPercent.."%", modeSize.dbl + CUSTOM_COLOR)
	else
		xTxt1 = xCoord+(cellWide * 0.5)-50; yTxt1 = cellHeight -10; xTxt2 = xCoord + (cellWide/2)-65; yTxt2 = cellHeight + 20; 
		lcd.setColor(CUSTOM_COLOR, col_std)
		
		lcd.drawText(xTxt1, yTxt1, myPercent.."%", modeSize.mid + CUSTOM_COLOR)
		lcd.drawText(xTxt2, yTxt2, round(myVoltage,1), modeSize.dbl + CUSTOM_COLOR)
	end
	
	-- icon Batterie -----
	if myPercent > 90 then batIndex = 7
		elseif myPercent > 70 then batIndex = 6
		elseif myPercent > 50 then batIndex = 5
		elseif myPercent > 30 then	batIndex = 4
		elseif myPercent > 20 then batIndex = 3
		elseif myPercent >10 then batIndex = 2
		else batIndex = 1
	end
	
	if batName ~= imagePath.."bat"..batIndex..".png" then
		batName = imagePath.."bat"..batIndex..".png"
		batImage = Bitmap.open(batName)
	end
	
	w, h = Bitmap.getSize(batImage)
	
	if name == "battery" then
		xPic=xCoord + (cellWide * 0.5) - (w * 0.5); yPic= yCoord - h*0.5 + cellHeight*0.5
	else
		xPic=xCoord + (cellWide * 0.5) + 15; yPic= yCoord - h*0.5 + cellHeight*0.35
	end
	
	lcd.drawBitmap(batImage, xPic, yPic)
end

------------------------------------------------- 
-- GPS								 2 Spalten --
------------------------------------------------- 
local function gpsWidget(xCoord, yCoord, cellHeight, name)
	local modeFix = {[0]="Kein Fix", [2]="2D", [3]="3D", [4]="DGPS"}
	
	lcd.drawText(xCoord + 4, yCoord + 2, "GPS", modeSize.sml)
		
	-- Icon GPS -----
	xTxt1 = xCoord + 55; yTxt1 = yCoord + 60; yTxt2 = 80
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	lcd.drawText(xTxt1, yTxt1, sats, modeSize.mid + modeAlign.le + CUSTOM_COLOR)

	gpsIndex = sats + 1
	if gpsIndex > 7 then gpsIndex = 7 end
	
	if gpsName ~= imagePath.."gps"..gpsIndex..".png" then
		gpsName = imagePath.."gps"..gpsIndex..".png"
		gpsImage = Bitmap.open(gpsName)
	end
	
	xPic= xCoord + 10; yPic= yCoord + 70
	lcd.drawBitmap(gpsImage, xPic, yPic)
			
	-- Icon satFix -----
	xPic= xCoord + 75; yPic= yCoord + 7
	
	fixIndex = satfix + 1
	if fixIndex > 4 then fixIndex = 4 end
	
	if fixName ~= imagePath.."fix"..fixIndex..".png" then
		fixName = imagePath.."fix"..fixIndex..".png"
		fixImage = Bitmap.open(fixName)
	end
	
	lcd.drawBitmap(fixImage, xPic, yPic)
		
	-- Icon homeSet -----
	xPic= xCoord + 10; yPic= yCoord + 23
	
	if homeSet then homeIndex = 2 else homeIndex = 1 end
	
	if homeName ~= imagePath.."home"..homeIndex..".png" then
		homeName = imagePath.."home"..homeIndex..".png"
		homeImage = Bitmap.open(homeName)
	end
	
	lcd.drawBitmap(homeImage, xPic, yPic)
end

------------------------------------------------- 
-- Heading ------------------------------- hdg --
------------------------------------------------- 
local function headingWidget(xCoord, yCoord, cellHeight, name)
	local hdgArray = {" N ", "NNO", "NO", "ONO", " O ", "OSO", "SO", "SSO", " S ", "SSW", "SW", "WSW", " W ", "WNW", " NW ", "NNW", " N "}
	local myHeading = getValueOrDefault("Hdg") 
	
	hdgIndex = math.floor (myHeading/15+0.5) --+1
	
	if hdgIndex > 23 then hdgIndex = 23 end		-- ab 352 Grad auf Index 23
	
	xTxt1 = xCoord + cellWide * xCorr.value1; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
	lcd.setColor(CUSTOM_COLOR, col_std)
		
	--lcd.drawText(xCoord + 5, yCoord + 5, "Richtung", modeSize.sml)
	lcd.drawText(xTxt1, yTxt1, round(myHeading), modeSize.dbl + modeAlign.ri + CUSTOM_COLOR)
	lcd.drawText(xTxt1, yTxt2, "dg", modeSize.sml + modeAlign.le)
	
	-- Himmelsrichtung anzeigen -----
	local direction = math.floor((myHeading + 11.25)/22.5) + 1
	lcd.drawText(xCoord + 4, yCoord + 2, hdgArray[direction], modeSize.sml+ modeAlign.le)

	-- Icon Heading -----
	if hdgName ~= imagePath.."pfeil"..hdgIndex..".png" then
		hdgName = imagePath.."pfeil"..hdgIndex..".png"
		hdgImage = Bitmap.open(hdgName)
	end
	
	local w, h = Bitmap.getSize(hdgImage)
	xPic= xCoord + cellWide - w - 2; yPic= yCoord + 7
	lcd.drawBitmap(hdgImage, xPic, yPic)
end

------------------------------------------------- 
-- RSSI -------------------------- rssi, rssi1 --
------------------------------------------------- 
local function rssiWidget(xCoord, yCoord, cellHeight, name)

	local myRssi = getValueOrDefault("RSSI")
	local myMinRssi = getValueOrDefault("RSSI-")
	
	lcd.drawText(xCoord + 4, yCoord + 2, "RSSI", modeSize.sml)
	
	if name == "rssi" then
		xTxt1 = xCoord + cellWide * xCorr.value; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
		lcd.setColor(CUSTOM_COLOR, col_std)
		lcd.drawText(xCoord + cellWide - 5, yCoord + 2, round(myMinRssi), modeSize.sml + modeAlign.ri)
	else
		xTxt1 = xCoord + cellWide * xCorr.value1; yTxt1 = cellHeight + yCorr.dbl; yTxt2 = cellHeight + yCorr.sml
		lcd.setColor(CUSTOM_COLOR, col_std)
		lcd.drawText(xCoord + cellWide - 70, yCoord + 2, round(myMinRssi), modeSize.sml + modeAlign.ri)
	end
		
	lcd.drawText(xTxt1, yTxt1, round(myRssi), modeSize.dbl+ modeAlign.ri + CUSTOM_COLOR) 
	lcd.drawText(xTxt1, yTxt2, "dB", modeSize.sml + modeAlign.le)
	
	-- Icon RSSI -----
	if name == "rssi1" then
		percent = ((math.log(myRssi-28, 10)-1)/(math.log(72, 10)-1))*100
		if myRssi <=37 then rssiIndex = 1
		elseif
			myRssi > 99 then rssiIndex = 11
		else
			rssiIndex = math.floor(percent/10)+2
		end
		
		if rssiName ~= imagePath.."rssi"..rssiIndex..".png" then
			rssiName = imagePath.."rssi"..rssiIndex..".png"
			rssiImage = Bitmap.open(rssiName)
		end
		
		local w, h = Bitmap.getSize(rssiImage)
		xPic= xCoord + cellWide - w - 2; yPic= yCoord + 5
		lcd.drawBitmap(rssiImage, xPic, yPic)
	end
	
end


-- ############################# Call Widgets #################################
 
local function callWidget(name, xPos, yPos, y1Pos)
	if (xPos ~= nil and yPos ~= nil) then
		if (name == "battery") or (name == "battery1") then
			batteryWidget(xPos, yPos, y1Pos, name)
		elseif (name == "rssi") or (name == "rssi1") then
			rssiWidget(xPos, yPos, y1Pos, name)
		elseif (name == "vfas") then
			vfasWidget(xPos, yPos, y1Pos, name)
		elseif (name == "curr") then
			currWidget(xPos, yPos, y1Pos, name)
		elseif (name == "rxbat") then
			rxbatWidget(xPos, yPos, y1Pos, name)
		elseif (name == "fuel") then
			fuelWidget(xPos, yPos, y1Pos, name)
		elseif (name == "fm") or (name == "fm1") then
			fmWidget(xPos, yPos, y1Pos, name)
		elseif (name == "lost") then
			lostWidget(xPos, yPos, y1Pos, name)
		elseif (name == "armed") then
			armedWidget(xPos, yPos, y1Pos, name)
		elseif (name == "timer") then
			timerWidget(xPos, yPos, y1Pos, name)
		elseif (name == "gps") then
			gpsWidget(xPos, yPos, y1Pos, name)
		elseif (name == "latlon") then
			LatLonWidget(xPos, yPos, y1Pos, name)
		elseif (name == "speed") then
			speedWidget(xPos, yPos, y1Pos, name)
		elseif (name == "vspeed") then
			vspeedWidget(xPos, yPos, y1Pos, name)
		elseif (name == "rpm") then
			rpmWidget(xPos, yPos, y1Pos, name)
		elseif (name == "heading") then
			headingWidget(xPos, yPos, y1Pos, name)
		elseif (name == "dist") then
			distWidget(xPos, yPos, y1Pos, name)
		elseif (name == "dist1") then
			distCalcWidget(xPos, yPos, y1Pos, name)
		elseif (name == "alt") then
			altWidget(xPos, yPos, y1Pos, name)
		else
			return
		end
	end
end

-- ############################# Build Grid #################################

local function buildGrid(def, thisZone)

	local sumX = thisZone.zone.x
	local sumY = thisZone.zone.y
	
	noCol = # def 	-- Anzahl Spalten berechnen
	cellWide = (thisZone.zone.w / noCol) - 1
				
	-- Rechteck
	if transparency  ~= 1 then 
	  	lcd.setColor(CUSTOM_COLOR, WHITE)
		lcd.drawFilledRectangle(thisZone.zone.x, thisZone.zone.y, thisZone.zone.w, thisZone.zone.h, CUSTOM_COLOR)
		lcd.drawRectangle(thisZone.zone.x, thisZone.zone.y, thisZone.zone.w, thisZone.zone.h, 0, 2)
	else
		lcd.drawRectangle(thisZone.zone.x, thisZone.zone.y, thisZone.zone.w, thisZone.zone.h, 0, 2)
	end
	
	-- Vertikale Linien
	if noCol == 2 then
		lcd.drawLine(sumX + cellWide, sumY, sumX + cellWide, sumY + thisZone.zone.h - 1, SOLID, 0)
	elseif noCol == 3 then
		lcd.drawLine(sumX + cellWide, sumY, sumX + cellWide, sumY + thisZone.zone.h - 1, SOLID, 0)
		lcd.drawLine(sumX + cellWide*2, sumY, sumX + cellWide*2, sumY + thisZone.zone.h - 1, SOLID, 0)
	end
	
	-- Horizontale Linien und Aufruf der einzelnen Widgets
	for i=1, noCol, 1
	do
	
	local tempCellHeight = thisZone.zone.y + (math.floor(thisZone.zone.h / # def[i])*0.35)
		for j=1, # def[i], 1
		do
			-- Horizontal Linen
			if j ~= 1 then
				lcd.drawLine(sumX, sumY, sumX + cellWide, sumY, SOLID, 0)
			end
			
			-- Widgets
			callWidget(def[i][j], sumX , sumY , tempCellHeight)
			sumY = sumY + math.floor(thisZone.zone.h / # def[i])
			tempCellHeight = tempCellHeight + math.floor(thisZone.zone.h / # def[i])
		end
		
		-- Werte zur?cksetzen
		sumY = thisZone.zone.y
		sumX = sumX + cellWide
	end
end

local function background(thisZone)
end

local function refresh(thisZone)
	widget()
	
	--AnySens --
	if modelName == "Xugong" then anyFuel() end
	
	-- Build Grid --
	buildGrid(widgetDefinition, thisZone)
end

return { name="Telemetrie", options=options, create=create, update=update, refresh=refresh, background=background }
