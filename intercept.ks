clearscreen.
SET TARGET TO VESSEL("ISS").
AG1 on.

run once lib_launch_geo.
RCS ON.
SAS OFF.
lock steering to lookdirup(ship:velocity:orbit, ship:facing:topvector ).
wait 10.
set mode to 7.
set TVAL to 0.
clearscreen.
set kuniverse:timewarp:mode to "RAILS".

print phaseAngle(TARGET:ORBIT:SEMIMAJORAXIS,KERBIN,TARGET:ORBIT:PERIOD) AT (5,4).
until mode = 0{
LOCK throttle to TVAL.
	
	if mode = 7{
		until current_phase_angle()-phaseAngle(TARGET:ORBIT:SEMIMAJORAXIS,KERBIN,TARGET:ORBIT:PERIOD)<2{
			lock x to TimeW().
			set kuniverse:timewarp:rate to x.
			print current_phase_angle() at(5,5).
		}		
		set kuniverse:timewarp:rate to 0.
		WAIT UNTIL WARP = 0 and SHIP:UNPACKED.
		lock steering to lookdirup(ship:velocity:orbit, ship:facing:topvector ).
		if current_phase_angle()-phaseAngle(TARGET:ORBIT:SEMIMAJORAXIS,KERBIN,TARGET:ORBIT:PERIOD)<0.2{
			set mode to 8.
		}
		
	}
	if mode = 8{
		set TVAL to 1.
		if ship:apoapsis>target:orbit:apoapsis*0.98{
			set TVAL to 0.
			SET MODE TO 9.
		}	
	}
	
	if mode = 9{
	lock relativeVelocityVec to target:velocity:orbit - ship:velocity:orbit.
	lock relativeSpeed to relativeVelocityVec:mag.
	

	until eta:apoapsis<100{
		set kuniverse:timewarp:rate to 50.
	}
	set kuniverse:timewarp:rate to 0.
	WAIT UNTIL WARP = 0 and SHIP:UNPACKED.	 
	LOCK steering TO lookdirup(relativeVelocityVec, ship:facing:topvector ).
	wait until eta:apoapsis<5.
	until relativeSpeed<0.5 {
		set TVAL to 1.
	}
	set TVAL to 0.
	lock steering to lookdirup((ship:velocity:orbit)*-1, ship:facing:topvector ).
	set mode to 10.
	wait 3. 	
		
		
	}
	if mode = 10{
		lock steering to lookdirup((ship:velocity:orbit)*-1, ship:facing:topvector ).
		set angl to (180-current_phase_angle())/2.
		set dist to (((apoapsis+periapsis)/2)*sin(current_phase_angle()))/sin(angl).
		if dist>1000{
			set peTar to Find_getclose(kerbin).
			set TVAL to 1.
				if (ship:periapsis-peTar)<5{
					set TVAL to 0.
					kuniverse:timewarp:warpto(time:seconds + (ship:orbit:period/2+time:seconds)).
					WAIT UNTIL WARP = 0 and SHIP:UNPACKED.
					SET MODE TO 9.
					}	
			
				
				}
				else{
					set mode to 0.
				}
		}
}




FUNCTION phaseAngle{
	PARAMETER A2,planet,P.
	LOCAL A1 is ship:orbit:semimajoraxis.
	LOCAL avgA is (A1+A2)/2.
	LOCAL Transit is 2*constant:pi*sqrt((avgA^3)/planet:mu).
	RETURN 180-(((0.5*Transit)/(P))*360).
}
FUNCTION current_phase_angle{
	set bodyToShipVec to (SHIP:POSITION - BODY:POSITION):NORMALIZED.
	set obtNorm to VCRS(bodyToShipVec, SHIP:VELOCITY:ORBIT:NORMALIZED):NORMALIZED.
	set bodyToTarVec to VXCL(obtNorm, (target:POSITION - BODY:POSITION):NORMALIZED):NORMALIZED.
	set signVec to VCRS(obtNorm, bodyToShipVec):NORMALIZED.
	set phaseSign to VDOT(bodyToTarVec, signVec).
	set ang to VANG(bodyToTarVec,bodyToShipVec).
	if phaseSign<0{
		return 360-ang.
	}
	else{	
		return ang.
	}
}

FUNCTION Find_getclose{
PARAMETER planet.
	LOCAL P is target:orbit:period. 
	LOCAL PERIOD is P*(((360-current_phase_angle()))/360).
	LOCAL transferA is (PLANET:MU*(PERIOD/2*constant:pi)^2)^(1.0/3.0).
	LOCAL TP is 2*transferA-(apoapsis+planet:radius).
	return TP-planet:radius.
		
}	
function ThrottRelVel{
	  PARAMETER rel.
   	  LOCK dthrott TO 0.025*((0-rel)/10).
	  return dthrott.
}
function ThrottAp{
	  PARAMETER ap.
   	  LOCK dthrott TO 0.025*((ap-ship:apoapsis)/1000).
	  return dthrott.
}
function ThrottPe{
	  PARAMETER pe.
   	  LOCK dthrott TO 0.025*((pe-ship:periapsis)/1000).
	  return dthrott.
}
FUNCTION TimeW{
	LOCAL diff is current_phase_angle()-phaseAngle(TARGET:ORBIT:SEMIMAJORAXIS,KERBIN,TARGET:ORBIT:PERIOD).
	if diff>180{
		return 10000.
	}
	else if diff>90 and diff<180{
		return 1000.
	}
	else if diff>45 and diff<90{
		return 100.
	}
	else if diff>2 and diff<45{
		return 50.
	}
	else{
		return 0.
	}
	
}

clearscreen.