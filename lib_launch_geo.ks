@LAZYGLOBAL OFF.


GLOBAL HALF_LAUNCH IS 145.

FUNCTION changeHALF_LAUNCH
{
  PARAMETER h.
  IF h > 0 { SET HALF_LAUNCH TO h. }
}
FUNCTION headingVec { 
	PARAMETER vecT.

	LOCAL east IS VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR).

	LOCAL trig_x IS VDOT(SHIP:NORTH:VECTOR, vecT).
	LOCAL trig_y IS VDOT(east, vecT).

	LOCAL result IS ARCTAN2(trig_y, trig_x).

	IF result < 0 {RETURN 360 + result.} ELSE {RETURN result.}
}

FUNCTION latIncOk
{
  PARAMETER lat,i.
  RETURN (i > 0 AND ABS(lat) < 90 AND MIN(i,180-i) >= ABS(lat)).
}

FUNCTION etaToOrbitPlane
{
  PARAMETER is_AN, planet, orb_lan, i, ship_lat, ship_lng.

  LOCAL eta IS -1.
  IF latIncOk(ship_lat,i) {
    LOCAL rel_lng IS ARCSIN(TAN(ship_lat)/TAN(i)).
    IF NOT is_AN { SET rel_lng TO 180 - rel_lng. }
    LOCAL g_lan IS (orb_lan + rel_lng - planet:ROTATIONANGLE).
    LOCAL node_angle IS (g_lan - ship_lng).
    SET eta TO (node_angle / 360) * planet:ROTATIONPERIOD.
  }
  RETURN eta.
}

FUNCTION azimuth
{
  PARAMETER i.
  IF latIncOk(LATITUDE,i) { RETURN (ARCSIN(COS(i) / COS(LATITUDE))). }
  RETURN -1.
}

FUNCTION planetSurfaceSpeedAtLat
{
  PARAMETER planet, lat.

  LOCAL v_rot IS 0.
  LOCAL circum IS 2 * CONSTANT:PI * planet:RADIUS.
  LOCAL period IS planet:ROTATIONPERIOD.
  IF period > 0 { SET v_rot TO COS(lat) * circum / period. }
  RETURN v_rot.
}

FUNCTION launchAzimuth
{
  PARAMETER planet, az, ap.

  LOCAL v_orbit IS SQRT(planet:MU/(planet:RADIUS + ap)).
  LOCAL v_rot IS planetSurfaceSpeedAtLat(planet,LATITUDE).
  LOCAL v_orbit_x IS v_orbit * SIN(az).
  LOCAL v_orbit_y IS v_orbit * COS(az).
  LOCAL raz IS (90 - ARCTAN2(v_orbit_y, v_orbit_x - v_rot)).
  print("Input azimuth: " + ROUND(az,2)).
  print("Output azimuth: " + ROUND(raz,2)).
  RETURN raz.
}

FUNCTION noPassLaunchDetails
{
  PARAMETER ap,i,lan.

  LOCAL az IS 90.
  LOCAL lat IS MIN(i, 180-i).
  IF i > 90 { SET az TO 270. }

  IF i = 0 OR i = 180 { RETURN LIST(az,0). }

  LOCAL eta IS 0.
  IF LATITUDE > 0 { SET eta TO etaToOrbitPlane(TRUE,BODY,lan,i,lat,LONGITUDE). }
  ELSE { SET eta TO etaToOrbitPlane(FALSE,BODY,lan,i,-lat,LONGITUDE). }
  LOCAL launch_time IS TIME:SECONDS + eta - HALF_LAUNCH.
  RETURN LIST(az,launch_time).
}

FUNCTION launchDetails
{
  PARAMETER ap,i,lan,az.

  LOCAL eta IS 0.
  SET az TO launchAzimuth(BODY,az,ap).
  LOCAL eta_to_AN IS etaToOrbitPlane(TRUE,BODY,lan,i,LATITUDE,LONGITUDE).
  LOCAL eta_to_DN IS etaToOrbitPlane(FALSE,BODY,lan,i,LATITUDE,LONGITUDE).

  IF eta_to_DN < 0 AND eta_to_AN < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
  ELSE IF (eta_to_DN < eta_to_AN OR eta_to_AN < HALF_LAUNCH) AND eta_to_DN >= HALF_LAUNCH {
    SET eta TO eta_to_DN.
    SET az TO (180 - az).
  } ELSE IF eta_to_AN >= HALF_LAUNCH { SET eta TO eta_to_AN. }
  ELSE { SET eta TO eta_to_AN + BODY:ROTATIONPERIOD. }
  LOCAL launch_time IS TIME:SECONDS + eta - HALF_LAUNCH.
  RETURN LIST(az,launch_time).
}

FUNCTION calcLaunchDetails
{
  PARAMETER ap,i,lan.

  LOCAL az IS azimuth(i).
  IF az < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
  ELSE { RETURN launchDetails(ap,i,lan,az). }
}

FUNCTION warpToLaunch
{
  PARAMETER launch_time.
  IF launch_time - TIME:SECONDS > 10 {
    print("Waiting for orbit plane to pass overhead.").
    WAIT 5.
    kuniverse:timewarp:warpto(launch_time).
  }
}
FUNCTION launchWindow {
    PARAMETER tgt.
    LOCAL lat IS SHIP:LATITUDE.
    LOCAL eclipticNormal IS VCRS(tgt:OBT:VELOCITY:ORBIT,tgt:BODY:POSITION-tgt:POSITION):NORMALIZED.
    LOCAL planetNormal IS HEADING(0,lat):VECTOR.
    LOCAL bodyInc IS VANG(planetNormal, eclipticNormal).
    LOCAL beta IS ARCCOS(MAX(-1,MIN(1,COS(bodyInc) * SIN(lat) / SIN(bodyInc)))).
    LOCAL intersectdir IS VCRS(planetNormal, eclipticNormal):NORMALIZED.
    LOCAL intersectpos IS -VXCL(planetNormal, eclipticNormal):NORMALIZED.
    LOCAL launchtimedir IS (intersectdir * SIN(beta) + intersectpos * COS(beta)) * COS(lat) + SIN(lat) * planetNormal.
    LOCAL launchtime IS VANG(launchtimedir, SHIP:POSITION - BODY:POSITION) / 360 * BODY:ROTATIONPERIOD.
    if VCRS(launchtimedir, SHIP:POSITION - BODY:POSITION)*planetNormal < 0 {
        SET launchtime TO BODY:ROTATIONPERIOD - launchtime.
    }
    RETURN TIME:SECONDS+launchtime.
}

