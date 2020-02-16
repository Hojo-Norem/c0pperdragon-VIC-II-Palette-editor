;*********************
;Colour precalculation
;*********************

		; calculate colour trigonoetry for colour index stored in X register
DoTrig	stx temp1
		ldy angles,x
		beq nocol
		; angle = ( origin + angles[ index ] * sector ) * radian;
		lda #0
		jsr givayf
		lda #<sector
		ldy #>sector
		jsr fmult
		lda #<origin
		ldy #>origin
		jsr fadd
		lda #<radian
		ldy #>radian
		jsr fmult
		#STFACM fptemp1
		jsr cos
		ldy temp1
		ldx x5tab,y
		ldy #>colcos
		jsr movmf
		#ldfacm fptemp1
		jsr sin
		ldy temp1
		ldx x5tab,y
		ldy #>colsin
		jsr movmf
		jmp doneang		
nocol	#ldfacb 0
		ldy temp1
		ldx x5tab,y
		ldy #>colcos
		jsr movmf
		ldy temp1
		ldx x5tab,y
		ldy #>colsin
		jsr movmf
doneang ldx temp1
		rts
		