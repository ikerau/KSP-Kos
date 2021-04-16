clearscreen.
AG2 on.
set mode to 1.
SET g TO KERBIN:MU / KERBIN:RADIUS^2.
set freefall to false.
until freefall{
	
	set freefall to acc().
}
wait 2.
RCS on.
set steering to heading(headingVec(SHIP:VELOCITY:orbit)*-1,0).
BRAKES ON.
wait 5.
until mode = 0{
lock throttle to TVAL.
	if mode  = 1{

		set biom to addon:biome:current.
		until biom<>water{
			set TVAL to 1.
			set biom to TRAddon:IMPACTPOS.
		}
		wait 0.5.
		set TVAL to 0.
		set mode to 2.
	}
	else if mode = 2{
	lock steering to -1*(TRAddon:PLANNEDVECTOR).
 	
	}
}
FUNCTION acc{
	SET g TO KERBIN:MU / KERBIN:RADIUS^2.
	set accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
	set huh to accvec:mag/g.
	if huh>0.01{
		return false.
	}
	return true.	
}