clearscreen.
lock steering to up.
set targetAlt to 500.

set currentAlt to ship:altitude.

SET Kp TO 1.
SET Ki TO 1.
SET Kd TO 1.
SET PID TO PIDLOOP(Kp, Kp, Kd).
SET PID:SETPOINT TO targetAlt.

SET thrott TO 0.5.
LOCK THROTTLE TO thrott.

UNTIL SHIP:LIQUIDFUEL < 0.1 {
    SET thrott TO thrott + PID:UPDATE(TIME:SECONDS, currentAlt).
    WAIT 0.001.
}