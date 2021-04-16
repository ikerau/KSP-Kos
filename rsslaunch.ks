CLEARSCREEN.

run once lib_launch_geo.


SET gui TO GUI(400 ,800).                                 //User enters target launch apogee. Because a constant burn is required for reaching orbit in RSS, the final apogee is usually higher.
set height to gui:addlabel("Type the desired Apogee").
set height:STYLE:ALIGN TO "CENTER".
set box1 to gui:ADDHLAYOUT().
box1:addspacing(50).
set box1:STYLE:ALIGN TO "CENTER".
set input to Box1:ADDTEXTFIELD("").
SET button TO gui:ADDBUTTON("OK").
gui:SHOW().
UNTIL button:TAKEPRESS WAIT(0.1).
CLEARGUIS().
set str to input:TEXT.
set apoapsis_orbit to str:TONUMBER().


SET gui TO GUI(400 ,800).                                			 //User enters a celestial body target. If there is no target of this type requred, the if statement s triggered.
set height to gui:addlabel(" Body Target (E.g. Moon). Type 'No' if targeting a vessel or no target is required").
set height:STYLE:ALIGN TO "CENTER".
set box1 to gui:ADDHLAYOUT().
box1:addspacing(50).
set box1:STYLE:ALIGN TO "CENTER".
set input to Box1:ADDTEXTFIELD("").
SET button TO gui:ADDBUTTON("OK").
gui:SHOW().
UNTIL button:TAKEPRESS WAIT(0.1).
CLEARGUIS().

if input:TEXT = "No"{
	SET gui TO GUI(400 ,800).                                              //User enters a vessel target. If there is no target of this type requred, the if statement s triggered.
	set height to gui:addlabel(" Vessel Target (E.g. ISS). Type 'No' if no target is required").
	set height:STYLE:ALIGN TO "CENTER".
	set box1 to gui:ADDHLAYOUT().
	box1:addspacing(50).
	set box1:STYLE:ALIGN TO "CENTER".
	set input to Box1:ADDTEXTFIELD("").
	SET button TO gui:ADDBUTTON("OK").
	gui:SHOW().
	UNTIL button:TAKEPRESS WAIT(0.1).
	CLEARGUIS().
	
	if input:TEXT = "No"
	{
		SET gui TO GUI(400 ,800).                                      //User enters a target launch heading. Could be more precise. 
		set height to gui:addlabel("Launch Azimuth").
		set height:STYLE:ALIGN TO "CENTER".
		set box1 to gui:ADDHLAYOUT().
		box1:addspacing(50).
		set box1:STYLE:ALIGN TO "CENTER".
		set input to Box1:ADDTEXTFIELD("").
		SET button TO gui:ADDBUTTON("OK").
		gui:SHOW().
		UNTIL button:TAKEPRESS WAIT(0.1).
		CLEARGUIS().
		set str1 to input:TEXT.
		set laazf to str1:TONUMBER().
		
		SET gui TO GUI(400 ,800).
		set height to gui:addlabel("North (1) or South (0)").
		set height:STYLE:ALIGN TO "CENTER".
		set box1 to gui:ADDHLAYOUT().
		box1:addspacing(50).
		set box1:STYLE:ALIGN TO "CENTER".
		set input to Box1:ADDTEXTFIELD("").
		SET button TO gui:ADDBUTTON("OK").
		gui:SHOW().
		UNTIL button:TAKEPRESS WAIT(0.1).
		CLEARGUIS().
		set str1 to input:TEXT.
		set laazNS to str1:TONUMBER().
	} 
	else
	{
		set target to VESSEL(input:TEXT). 
	}

} 
else
{
set target to BODY(input:TEXT). 
}

if HASTARGET                                                                    //If a target was selected, the launch azimuth and launch time are calculated with the library imported above.
{
	set latitudeS to SHIP:GEOPOSITION:LAT.
	set longitudeS to SHIP:GEOPOSITION:LNG.
	set inclinationTar to target:ORBIT:INCLINATION.
	set LANTar to TARGET:ORBIT:LongitudeOfAscendingNode.
	
	print latIncOk(latitudeS, inclinationTar).
	set window to launchWindow(target)-30.
	print ROUND(window,1)+" seconds to launch window".
	
	WarpToLaunch(window).
	WAIT UNTIL WARP = 0 and SHIP:UNPACKED.
	clearscreen.
	
	print"Warp complete. Calculating launch azimuth...".
	wait 1.	
	set az to azimuth(inclinationTar).
	set laaz to launchAzimuth(Earth, az, apoapsis_orbit).
	print "launch azimuth: "+laaz.
}



set altz to apoapsis_orbit. 
set TVAL to 0.         //Thrust value
set mode to 1.         //Launch mode
set one to 1.          //Keeps the countdown function from repeating in the first launch mode.
if laazNS = 0{         //Determines roll directoin based on user input above (North or South)
	set laaz to 90-laazf.
}
else{
	set laaz to laazf.
}
until mode = 0{             //This structure works, but I am not sure if there is a better way to approach the script. It definitely causes a bit of lag (not a lot, but noticable)
lock throttle to TVAL.        //TVAL value will control throttle output.

	if mode = 1
	{ 
		if one = 1 AND SHIP:ALTITUDE<150{                //Initiates countdown and launches the rocket vertically with original heading until 150 meters
			set steering to r(up:pitch,up:yaw,facing:roll).
			set TVAL to Thrott().
			clearscreen.
			countdown().
			clearscreen.
			set targetG to 3.
			set one to 2.
		}
		
		else if one = 2 AND SHIP:ALTITUDE>150 {         //Once it reaches 150 meters, it starts the roll program
			set mode to 2.
		
		}
			
	
	}
	
	else if mode = 2
	{
		set steering to heading(laaz,90,180).              //Points the vehicle towards the right inclination.
		if SHIP:VERTICALSPEED > 95                    //Starts pitch manuever at 95 m/s.
		{
			set mode to 3.
		}
	}
	else if mode = 3
	{
		set twr1 to TWR(Earth).                               //These four lines determine the gravity turn and end turn angle based on TWR and a function. 
		set mina to max((25.7143-7.14286*twr1),7).          //I don't like using a function as a fixed turn (based on speed). I would like the turn to alter based on TWR. Don't know how to do that yet.
		set speedy to speed().
                set angle to (93.6998 - 0.047205*speedy).
		set steering to heading(laaz,max(angle,mina),180).
		set det to deta().                                     // Deta is the slope of the ETA to apoapsis. If it is less than zero, it makes sure the engine is at maximum throttle setting. I don't think this is necessary anymore.
		if det<0{
			set TVAL to 1.
		}
		else{
			set TVAL to Thrott().
		}
		superStage().
		if HASTARGET{                                       // Switches to the orbital velocity vector once the relative inclination to target has decreased to less than two degrees. Could be better.
			if SHIP:APOAPSIS >= Altz AND abs(target:orbit:inclination-ship:orbit:inclination)<2 
			{
				set mode to 4.
			}
		}
		else if SHIP:APOAPSIS >= Altz{
			set mode to 4.
		}
		
	}
	else if mode = 4
	{
		superStage().
		RCS ON.
		wait 1.
		if ETA:APOAPSIS >0 and ETA:APOAPSIS<90{                   //Flight angle between ETA to apoapsis 0 and 90. Function based on ETA
			set angleOrb to  (24.1667-0.416667*ETA:APOAPSIS).
			LOCK steering to heading(laaz,angleOrb,180).
			set TVAL to Thrott(). 
		}
		else if ETA:APOAPSIS>90 AND ETA:APOAPSIS<1200{           //Flight angle when ETA is greater than 90
			set angleOrb to -2.
			set steering to heading(laaz,angleOrb,180).
			set TVAL to Thrott(). 
		}
		else if SHIP:VERTICALSPEED<0{                               //Flight angle when Apoapsis is behind the spacecraft
			set steering to heading(laaz,40,180).
			set TVAL to Thrott(). 
		}		
		superStage().
		
		if speed() > 4000{
			set mode to 5.
		}
	}
	else if mode = 5
	{	
		superStage().
		RCS ON.
		wait 1.
		if ETA:APOAPSIS >30 and ETA:APOAPSIS<90{
			set angleOrb to  (25-0.309524*ETA:APOAPSIS).
			LOCK steering to heading(headingVec(SHIP:VELOCITY:orbit),angleOrb).
			set TVAL to Thrott(). 
		}
		else if ETA:APOAPSIS<30 AND ETA:APOAPSIS>0{
			set steering to heading(headingVec(SHIP:VELOCITY:orbit),20).
			set TVAL to Thrott().
		}
		else if ETA:APOAPSIS>90 AND ETA:APOAPSIS<1200{
			set angleOrb to -20.
			set steering to heading(headingVec(SHIP:VELOCITY:orbit),angleOrb).
			set TVAL to Thrott().
		}
		else if ETA:APOAPSIS>1200{
			set steering to heading(headingVec(SHIP:VELOCITY:orbit),40).
			set TVAL to Thrott().
		}		
		superStage().
		if SHIP:PERIAPSIS>Altz AND SHIP:APOAPSIS>Altz
		{
			set TVAL to 0.
			set throttle to 0.
			set mode to 0.
			set yeet to true.
		}
			
	}

    print "MODE:         "  + mode + "      " at (5,4).
    print "ALTITUDE:     " + round(SHIP:ALTITUDE) + "      " at (5,5).
    print "APOAPSIS:     " + round(SHIP:APOAPSIS) + "      " at (5,6).
    print "PERIAPSIS:   " + round(SHIP:PERIAPSIS) + "      " at (5,7).
    print "ETA to AP:    " + round(ETA:APOAPSIS) + "      " at (5,8).
    print "Engine Perf:  " + round(TVAL*100) + "%      " at (5,9).
   



}
clearscreen.
UNLOCK Steering.
set throttle to 0.

function countdown{
	set t to 0.
	set x to 10.
	until t = 10{
		Print"T-Minus:"+(x-t) at(5,5).
		wait 1.
		set t to t+1.
		clearscreen.
	}
	clearscreen.
	stage.
	print"Ignition!"at(5,5).
	wait 4.
	stage.
	clearscreen.
	print"Liftoff!"at(5,5).
	
	
}


function speed{
 	return sqrt(SHIP:VERTICALSPEED^2+SHIP:GROUNDSPEED^2).
}
function superStage{	
	LIST Engines in Eng.
	FOR engine IN Eng{
		IF (engine:ignition AND engine:flameout) {
			set targetG to 1.88571-0.000928571*speed().
			wait until stage:ready.
			wait 0.1.
			stage.
			BREAK.
					
		} 
	}	
}

function ascentThrott{
	SET g TO EARTH:MU / EARTH:RADIUS^2.
   	LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
    	LOCK gforce TO accvec:MAG / g.
  	LOCK dthrott TO 0.1 * (targetG - gforce).
	return 1+dthrott.
}
Function TWR{
	PARAMETER body.
	local heregrav is body:mu / ((ship:altitude + body:radius)^2).
	local t is SHIP:AVAILABLETHRUST / (heregrav * ship:mass).
	return t.
}
function Thrott{
	SET g TO EARTH:MU / EARTH:RADIUS^2.
	LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
	LOCK gforce TO accvec:MAG / g.
	SET Kp TO 0.55.
	SET Ki TO 0.55.
	SET Kd TO 0.55.
	SET PID TO PIDLOOP(Kp, Ki, Kd).
	SET PID:SETPOINT TO 3.
	return 1 + PID:UPDATE(TIME:SECONDS, gforce). wait 0.001.
}

function engineMin{
	LIST Engines in Eng.
	set maxmin to 0.
	FOR engine IN Eng{
		IF(engine:minthrottle>maxmin){
			set maxmin to engine:minthrottle.
		}
	return maxmin.
	}		
}

function deta{
	set a to ETA:APOAPSIS.
	wait(0.01).
	set b to ETA:APOAPSIS.
	return (b-a)/(0.01).
}
















