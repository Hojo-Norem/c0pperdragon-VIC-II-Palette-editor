DefPalMode	.byte 0

dodefaults
			#scroff
			lda #1
			sta defpalmode
			jsr printtop
			jsr printpal
			#prints defpalmenu
			#scron
			ldy #0
defmainmenuloop		
			lda 197
			cmp #key_none
			beq defmainmenuloop
			cmp #key_1
			beq defcomppal
			cmp #key_2
			beq defrgbspal
			cmp #key_3
			beq defrgbnpal
			jmp defmainmenuloop			
			
defrgbnpal	iny
defrgbspal	iny
defcomppal	sty outputmode
			lda #17
			sta fullcalculation
			lda #16
			sta currcol
			#prints defpalluma
			jsr chooseluma
			jsr recalc
			jsr showtest
			jsr printtop
			jsr printpal
			lda #0
			sta defpalmode
			rts
			
;dodefcol - Converts c0pperdragon's precalculated palette into seperate
;			Y and FP Pr and Pb values then rescales Pr and Pb into UV colourspace
;			Expects - X = colour index
;			Returns - Calculated Y in temp2, calculated U & V in FPTempU and FPTempV
;			Trashes - Everything but X
dodefcol
		stx temp1
		lda DefaultPaletteYPbPrLo,x
		and #31
		jsr upscale
		tay
		#ldfacy
		#stfacm fptemp1
		
		#ldfacb 128
		#facsubm fptemp1
		#FACmulM fpscalepr
		lda #<FP127
		ldy #>FP127
		jsr FCOMP
		cmp #1
		bne +
		#LDFACM FP127
+		#stfacm FPTempV
		ldx temp1
		lda DefaultPaletteYPbPrLo,x
		and #224
		lsr
		lsr
		lsr
		lsr
		lsr
		sta temp2
		ldx temp1
		lda DefaultPaletteYPbPrhi,x
		and #3
		asl
		asl
		asl
		ora temp2
		jsr upscale
		tay
		#ldfacy
		#stfacm fptemp1
		#ldfacb 128
		#facsubm fptemp1
		#FACMULM FPscalepb
		#stfacm FPTempU
		ldx temp1
		lda DefaultPaletteYPbPrhi,x
		lsr
		lsr
		sta temp2
		rts

		

		