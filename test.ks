clearscreen.
	LIST Engines in Eng.
	set maxmin to 0.
	FOR engine IN Eng{
		IF(Engine:POSSIBLETHRUST>maxmin){
			set maxmin to Engine:POSSIBLETHRUST.
		}
	
	}		
PRINT maxmin.