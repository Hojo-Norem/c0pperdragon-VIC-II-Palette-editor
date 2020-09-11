; Beam racer support routines

VREG_CONTROL = $D031

; brcheck - subroutine checks if there is an active BeamRacer expansion.
;			If there is not then the normal start screen is printed.
;			If there is an active expansion detected, then a reset command is sent
;			and the check repeated.  If deactivation is successful then the start
;			screen will reflect this.  If not then a error message will display
;			and the program will enter a freeze loop.

brcheck
		LDX VREG_CONTROL
		INX
		BNE bractive
		#prints title3
		rts		
bractive
		lda #$40      ; Reset BeamRacer so that it drops off the bus and makes
		sta $d02e     ; VideoMod registers accessible. Harmless if BeamRacer not present
		LDX VREG_CONTROL
		INX
		BNE brstillactive
		#prints title3br
		rts
brstillactive
		#prints brerror
		#scron
frloop	jmp frloop
		