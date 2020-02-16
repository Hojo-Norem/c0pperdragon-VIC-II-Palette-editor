;****************************************************
;initialise variables and perform initial calculation
;****************************************************

PreCalc
		jsr initmultables	;initialise the tables for the fast FP multiplication routines
		lda #1
		sta spren
		;Set default values
		lda #50
		sta bbright
		sta bsatura
		lda #100
		sta bcontra
		lda #15
		sta currcol
		ldx #0
		stx selparam
		;make odd_cos and odd_sin
		;according to the JS source at colorore.com, 'odd' = 360/16,
		;the same as 'sector' at pepto.de/projects/colorvic/
		;odd_cos = cos( (odd * PI) / 180 );
		;odd_sin = sin( (odd * PI) / 180 );
		#ldfacm sector
		#facmulm pi
		#stfacm fptemp1
		#ldfacb 180
		#facdivm fptemp1
		#stfacm fptemp1
		jsr cos
		#stfacm odd_cos
		#ldfacm fptemp1
		jsr sin
		#stfacm odd_sin
		;origin (sector / 2)
		#ldfacb 2
		#facdivm sector
		#STFACM origin
		;calculate and store default origin, brightness, contrast and saturatuon for each colour
		ldy #0
-		sty temp4
		#ldfacm origin
		ldy temp4
		ldx x5tab,y
		ldy #>iorigin
		jsr movmf
		ldy temp4
		lda #50
		sta ibright,y
		sta isatura,y
		lda #100
		sta icontra,y
		iny
		cpy #17
		bne -
		jsr norm_sat
		jsr norm_con
		jsr norm_bri
		ldx #15
deftrig	jsr dotrig
		jsr calccol
		jsr normoutput
		jsr preshift
		lda colreglow
		sta mainpall,x
		lda colreghigh
		sta mainpalh,x
		jsr spinsprite
		dex
		bpl deftrig
		lda #1
		sta full_upload
		lda #0
		sta spren
		rts
