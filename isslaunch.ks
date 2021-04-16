SET TARGET TO VESSEL("ISS").
clearscreen.
SET spot TO SHIP:GEOPOSITION.
run once lib_launch_geo.
set mode to 100.
set TVAL to 0.
set throttle to 0.
lock throttle to TVAL.
set yeet to false.

set t to launchWindow(TARGET)-85.

set Altz to 80500.



kuniverse:timewarp:warpto(t).
set kuniverse:timewarp:rate to 0.
WAIT UNTIL WARP = 0 and SHIP:UNPACKED.

set mode to 1.
set inc to launchAzimuth(KERBIN,azimuth(TARGET:ORBIT:INCLINATION),TARGET:ORBIT:APOAPSIS).
until mode = 0 or yeet{


	if mode = 1
	{ 
		
		lock steering to heading(inc,90).
		set TVAL to 1.
		countdown().
		set mode to 2.
		set targetG to 3.
		clearscreen.	
	
	}
	
	else if mode = 2
	{
	
		if SHIP:VERTICALSPEED > 50
		{
			set mode to 3.
		}

	}
	else if mode = 3
	{
		if SHIP:ALTITUDE<2000{
			set angle to ((0.0000371748*speed()^2) - 0.111273*speed() + 92.5606).
			lock steering to heading(inc,max(angle,5)).
		}
		else if SHIP:ALTITUDE>1500 AND ship:orbit:inclination<target:orbit:inclination{
			set angle to ((0.0000371748*speed()^2) - 0.111273*speed() + 92.5606).
			
			lock steering to heading(headingVec(SHIP:VELOCITY:surface),max(angle,5)).
		}
		else if abs(target:orbit:inclination-ship:orbit:inclination)<1 {
			set mode to 3.5.	
		}
		set TVAL to ascentThrott().
		superStage().

		
	}
	else if mode = 3.5{
		lock TVAL to ascentThrott().
		superStage().
		set angle to ((0.0000371748*speed()^2) - 0.111273*speed() + 92.5606).
		lock steering to heading(headingVec(SHIP:VELOCITY:orbit),max(angle,5)).	
		if SHIP:APOAPSIS >= Altz
		{
			unlock TVAL.
			set mode to 4.
			set TVAL to 0.
		}
	
	}
	else if mode =4{
		set ETAp to 45.3308-48.1415*log10(TWR(kerbin)).
		set steering to heading (headingVec(SHIP:VELOCITY:orbit),-15). 
      	  	set TVAL to 0. 
      	 	 if (SHIP:ALTITUDE > 70000) and (ETA:APOAPSIS > 60) and (VERTICALSPEED > 0) {
           			 if WARP = 0 {      
              	 			 wait 1.         
               				 SET WARP TO 4. 
               			 }
          		  }
      		  else if ETA:APOAPSIS < ETAp {
          			  SET WARP to 0.
            			  set mode to 5.
            		}
	
	}

	else if mode = 5{	
		
		RCS ON.
		wait 1.
		if ETA:APOAPSIS >0 and ETA:APOAPSIS<400{
			set angleOrb to  1.81818-0.363636*ETA:APOAPSIS.
			lock steering to heading(headingVec(SHIP:VELOCITY:orbit),angleOrb).
			set TVAL to max(insertionThrott() ,0.2). 
		}
		else if ETA:APOAPSIS>600{
			lock steering to heading(headingVec(SHIP:VELOCITY:orbit),20).
			set TVAL to 1.
		}		
		superStage().
		if SHIP:PERIAPSIS>20000
		{
			lock steering to heading(headingVec(SHIP:VELOCITY:orbit),angleOrb).
			set TVAL to max((1.48853-0.573394*TWR(kerbin)),0.3). 
			set mode to 6.
		}
			
	}
	else if mode = 6
	{
		if SHIP:APOAPSIS>Altz+100 and SHIP:PERIAPSIS>70000
		{
			set TVAL to 0.
			unlock steering.
			set throttle to 0.
			set mode to 0.
			set yeet to true.
		}
	}                                                        

lock throttle to TVAL.

    print "MODE:         "  + mode + "      " at (5,4).
    print "ALTITUDE:     " + round(SHIP:ALTITUDE) + "      " at (5,5).
    print "APOAPSIS:     " + round(SHIP:APOAPSIS) + "      " at (5,6).
    print "PERIAPSIS:   " + round(SHIP:PERIAPSIS) + "      " at (5,7).
    print "ETA to AP:    " + round(ETA:APOAPSIS) + "      " at (5,8).
    print "Engine Perf:  " + min(round(THROTTLE*100),100) + "%      " at (5,9).



}
clearscreen.
if (ship:apoapsis-ship:periapsis)<150{
	run intercept.
}
print "Circularize manually, then type in run intercept to rendezvous".

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
	AG4 ON.
	wait 3.
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
	  SET g TO KERBIN:MU / KERBIN:RADIUS^2.
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
function insertionThrott{
	  set targetETA to 2.
   	  LOCK dthrott TO 0.025 * (eta:apoapsis-targetETA).
	  return max(1-dthrott,0.2).
}
	