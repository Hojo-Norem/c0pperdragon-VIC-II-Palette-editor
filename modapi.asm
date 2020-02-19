;************************************
;c0pperdragon mod access api routines
;************************************
		;interface mem loc and write constants
		Control=53311		;Control register
		Unlock=137			;unlock byte. Writes go to both odd and even colour register tables. 
		Save=138			;save byte
		SelOdd=0			;Writes go to odd scanline colour register table
		SelEven=1			;Writes go to even scanline colour register table
		ColLow=53308		;Colour register low byte register
		ColHigh=53309		;Colour register high byte register
		ColReg=53310		;Colour register address register

;*****************************************************************************
;Preshift routine - Y in Temp2 is 5 bits, Pb & Pr in Temp 3 & Temp4 are 8 bits
;*****************************************************************************
preshift
		lda temp4			;Load Pr (RRRRRRRR)
		lsr					;|
		lsr					;|  Shift right 3 bits
		lsr					;|
		sta temp4			;Store Pr (...RRRRR)
		lda temp3			;Load Pb (BBBBBBBB)
		tay					;Temp store Pb in Y reg
		asl					;|  Shift left 2 bits
		asl					;|	clear rightmost 5 bits
		and #224			;|	(BBB.....)		
		ora temp4			;Logical OR with Pr (BBBRRRRR)
		sta colreglow		;Store to temp low col register
		lda temp2			;Load Y (...YYYYY)
		asl					;|  Shift Left two bits
		asl					;|	(.YYYYY..)
		sta DHB+1			;Store into parameter of ORA statement below
		tya					;Get Pb from Y reg
		lsr					;|  Shift right six bits
		lsr					;|	(......BB)
		lsr					;|
		lsr					;|
		lsr					;|
		lsr					;|
DHB		ora #0				;Logical OR with above (.YYYYYBB)
		sta colreghigh		;Store to temp high col register
		rts
		
setsync						;setsynx assumes X = colour index and A = hi colour register
		cpx #0				;are we dealing with colour index 0?
		bne +				;if not, skip ahead
		ldy outputmode		;get videomode
		cpy #2				;is videomode RGBns?
		bne +				;if no, skip ahead
;		lda colreghigh
		ora #128			;If yes, set bit7 (bit15).  This disables sync output.
;		sta colreghigh		
+		rts
		
upload
		ldy x16tab,x
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		iny
		sty colreg
		rts
		



