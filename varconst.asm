;**********************************
;Constants and Variable definitions
;**********************************

		
		

		
		;zeropage addr constants
		Bbright=252			;current brightness
		;brightsign=64		;sign of normalised brightness
		Nbright=64			;normalised brighness
		Bcontra=253			;current contrast
		Bsatura=254			;current saturation
		PreCalced=63		;skip pre-calcualtion if needed
		NContra=250			;Normalised contrast (for use with LUT)
		Boost=83			;brightness boost used for contrast LUT
		full_upload=255		;0 - IRQ routine only upload minimal colours to interface. 255 - skip all uploads. Reset to 0 after any nonzero or 255 operation
		CurrCol=73			;Currently selected colour for editing.  Index 16 selects all colours
		
		ColRegLow=165		;Temp storage for ready to upload colour register values
		ColRegHigh=166
		
		Temp1=61
		Temp2=62
		Temp3=155
		Temp4=156
		
		PCLUTL=195			;Temp low / high pair for (addr),y operations
		PCLUTH=196
		
		;misc constants
		New_Lumas=0
		Old_Lumas=16
		Tweaked_Lumas=32
		
		Sprite_x=24
		Sprite_y=229
		SelParam=251
		
		ReadOutY=10		;base screen row constant for displaying adjustment values
		BriX=7			;x position constant of brightness value
		ConX=19			;same for contrast
		SatX=31			;and saturation
		originX=7		;origin too
		currcolx=25		;dont forget current colour
		
		Pi=$aea8		
