;*****************************************
;'real time' colour calcultation functions
;*****************************************

hanover	.byte 0			; Calculate hanover bars. 0 = dont, 1 = odd lines, 2 = even lines

norm_bri
		lda bbright
		sta Nbright
		rts
		
;normalise contrast as per colorore
norm_con
		#ldfacbm bcontra
		#STFACM fptemp1
		#ldfacb 100
		#facdivm fptemp1
		#facaddm screen
		#STFACM fcontra
		clc
		lda bcontra
		adc boost
		sta Ncontra
		rts
		
;normalise saturation as per colodore
norm_sat
		#ldfacb 1
		#txfa
		#ldfacm screen
		jsr fsubt
		#STFACM fptemp1
		#ldfacbm bsatura
		#facmulm fptemp1
		#STFACM fsatura
		rts
		
;calccol - 	The 'meat' of the algorithm.  responsible for the final parts calculations.
;		   	Called whenever a parameter changes.  U & V are calculated entirely using
;			floating point.  This shuold reduce the conversion errors when going YUV
;			to RGB.  Also allows accurate hanover bar generation.  Y is derrived from
;			two pre-calculated tables which holds all the 5bit permutations of
;			"(Luma+brightness)*contrast+screen".
;			Expects - X = colour index to calculate
;			Returns - Calculated Y in temp2, calculated U & V in FPTempU and FPTempV
;			Trashes - A,Y and a lot more.
CalcCol	txa
		sta temp1
		bne itsnotblack
		lda #0
		jmp donebri
itsnotblack		
		clc
		lda active_luma
		adc temp1
		tay
		lda lumas,y
		ldy nbright
		clc
		adc brilut,y
		tay
		and #224 ;if >31 then Z will be clear.  if => 128 then N will be set
		bpl notminus
		lda #0
		tay
notminus
		beq notover
		lda #31
		tay		
notover	ldx Conlut,y
		stx pcluth
		ldy ncontra
		lda (pclutl),y
donebri	sta temp2
		ldy temp1
		;u=int((((uc(ci)*fsatura)*fcontra)+127)/255)	
		lda angles,y
		lda x5tab,y
costab	ldy #>colcos
		jsr movfm
		#FACMULM fsatura
		#FACMULM fcontra
		#STFACM FPtempU
		ldy temp1
		lda x5tab,y
sintab	ldy #>colsin
		jsr movfm
		#FACMULM fsatura
		#FACMULM fcontra
		#STFACM FPtempV
		lda hanover
		bne +
		jmp nohanover
+		cmp #1
		beq +
		jmp dohaneven
+		#ldfacm fptempu
		#facmulm odd_cos
		#stfacm fptemp1
		#ldfacm fptempv
		#facmulm odd_sin
		#stfacm fptemp2
		#ldfacw -1
		#facmulm fptemp2
		#facsubm fptemp1
		#stfacm fptemp3	
		#ldfacm fptempv
		#facmulm odd_cos
		#stfacm fptemp1
		#ldfacm fptempu
		#facmulm odd_sin
		#stfacm fptemp2
		#ldfacw -1
		#facmulm fptemp2
		#facaddm fptemp1
		#stfacm fptempv	
		#cpfp fptemp3, fptempu
		jmp noscale
dohaneven
		#ldfacm fptempu
		#facmulm odd_cos
		#stfacm fptemp1
		#ldfacm fptempv
		#facmulm odd_sin
		#facsubm fptemp1
		#stfacm fptemp2
		
		#ldfacm fptempv
		#facmulm odd_cos
		#stfacm fptemp1
		#ldfacm fptempu
		#facmulm odd_sin
		#facaddm fptemp1
		#stfacm fptempv		
		#cpfp fptemp2, fptempu
		jmp noscale
nohanover
		jsr scaletoYPbPr
noscale	ldx temp1
		rts


scaletoYPbPr
		;do U -> Pb scaling
		#LDFACM FPScalePb
		#FACDIVM FPtempU
		;and clamp it
		lda #<FP127
		ldy #>FP127
		jsr FCOMP
		cmp #1
		bne +
		#LDFACM FP127
+		#stfacm FPTempU
		;do V -> Pr scaling 
		#LDFACM FPScalePr
		#FACDIVM FPtempV
		#stfacm FPTempV
		rts
		
		
normoutput
		txa
		pha
		tya
		pha
		#ldfacm fptempu
		jsr facinx
		tya
		clc
		adc #128
		sta temp3
		#ldfacm fptempv
		jsr facinx
		tya
		clc
		adc #128
		sta temp4		
		pla
		tay
		pla
		tax
		rts
		

fullcalculation
		.byte 0
tempY	.byte 0,0
tempU	.byte 0,0
tempV	.byte 0,0
tabin	.byte 0
tempreg	.byte 0


getparams
		lda isatura,x
		sta bsatura
		lda icontra,x
		sta bcontra
		lda ibright,x
		sta bbright
		txa
		pha
		jsr norm_bri
		jsr norm_sat
		jsr norm_con
		pla
		tax
		rts

		
dodivs
		lda tempy
		clc
		lda temp2			;load Y value
		adc tempy			;add second Y value
		lsr					;divide by two
		sta temp2			;store here because the preshifter routine uses it
		#ldfacm fptempu
		#facaddm fptempu2
		#stfacm fptemp2
		#ldfacb 2
		#facdivm fptemp2
		#stfacm fptempu
		#ldfacm fptempv
		#facaddm fptempv2
		#stfacm fptempv
		#ldfacb 2
		#facdivm fptempv
		#stfacm fptempv	
		rts
		
		
jskipmixcalc
		jmp skipmixcalc	

;fullcalc -	This is where the colour data gets copied ready for uploading to FPGA and
;			where the function calls are made for the additional calculation for generating
;			the lumamixed colours.
fullcalc
		lda fullcalculation
		beq jskipmixcalc
		lda #1
		sta spren
		ldx currcol
		lda bsatura
		sta isatura,x
		lda bcontra
		sta icontra,x
		lda bbright
		sta ibright,x
		lda fullcalculation
		cmp #16
		bne +
		jsr cpyparams
+		ldy #0
		; copy work palette (mainpal) into both odd and even output palettes (fullpalodd and fullpaleve)
		ldx #0				
-		stx temp1			
		ldx #0				
-		stx temp2
		ldx temp1
		lda mainpall,x
		sta fullpaloddl,y
		sta fullpalevel,y
		lda mainpalh,x
		sta fullpaloddh,y
		sta fullpaleveh,y
		iny
		ldx temp2
		inx
		cpx #16
		bne -
		jsr spinsprite
		ldx temp1
		inx
		cpx #16
		bne --
		; select mixing table to use
		lda #<newmix
		sta mixtab1+1
		sta mixtab2+1
		lda #>newmix
		sta mixtab1+2
		sta mixtab2+2
		lda mix_luma
		beq usenew
		lda #<oldmix
		sta mixtab1+1
		sta mixtab2+1
		lda #>oldmix
		sta mixtab1+2
		sta mixtab2+2		
usenew	ldx #0
		stx tabin
calcfulltable
		lda #1
		sta hanover
mixtab1	lda $c000,x
		bne +
		jmp donetable
+		tax
		asl
		asl
		asl
		asl
		sta tempreg
		jsr getparams
		jsr calccol
		lda temp2
		sta tempy
		#cpfp fptempu, fptempu2
		#cpfp fptempv, fptempv2
		lda #0			;my personal pref is to mix the odd line hanovers with the even line non-hanovers
		sta hanover		;will probably change this if I figure out how to tweak the hanover generator	
		ldx tabin
		inx
mixtab2	lda $c000,x
		inx
		stx tabin
		tax
		ora tempreg
		sta tempreg
		jsr getparams		
		jsr calccol	
		jsr dodivs
		jsr scaletoYPbPr
		lda outputmode
		bne +
		jsr normoutput
		jmp ++
+		jsr doRGBconv
+		jsr preshift
		ldy tempreg
;		lda colreghigh	;store colour into odd scanline palette
		sta fullpaloddh,y
		lda colreglow	
		sta fullpaloddl,y
		tya
		ASL  			;swap colour matrix co-ords
        ADC #$80
        ROL  
        ASL  
        ADC #$80
        ROL  
		tay
		lda colreglow	;and store into even scanline palette
		sta fullpalevel,y
		lda colreghigh
		sta fullpaleveh,y		
		jsr spinsprite	
		ldx tabin
		jmp calcfulltable
donetable		
		ldy currcol
		ldx isatura,y
		stx bsatura
		ldx icontra,y
		stx bcontra
		ldx ibright,y
		stx bbright
		lda #0
		sta hanover		
skipmixcalc
		lda #1
		sta spren
		lda #255
		sta full_upload
		ldx #0
		ldy #2
		sty temp1
-		lda #selodd
		sta control
		ldy fullpaloddl,x
		sty collow
		ldy fullpaloddh,x
		sty colhigh
		stx colreg
		lda #seleven
		sta control
		ldy fullpalevel,x
		sty collow
		ldy fullpaleveh,x
		sty colhigh
		stx colreg
		ldy temp1
		dey
		bne +
		jsr spinsprite
		ldy #2
+		sty temp1
		inx
		bne -
		lda #unlock
		sta control	
		lda #0
		sta fullcalculation
		sta spren
		rts

		;R = Y + (1.402 * Pr)
		;G = (Y - (0.344 * Pb)) - (0.714 * Pr)
		;B = Y + (1.772 * Pb)
doRGBconv
		txa
		pha
		tya
		pha
		lda temp2		;|shift Y compnent up to 8 bits
		asl
		asl
		asl
		tay
		#LDFACY			;Make it a floating point number
		#STFACM	fptemp2
		#ldfacm fptempu
		#facmulm fpbc
		#facaddm fptemp2
		jsr clamp
		jsr facinx
		sty temp3
		#ldfacm fptempv		
		#facmulm fprc
		#facaddm fptemp2
		jsr clamp
		jsr facinx
		sty temp4
		#ldfacm fptempu
		#facmulm fpgc1
		#facsubm fptemp2
		#stfacm fptemp1
		#ldfacm fptempv
		#facmulm fpgc2
		#facsubm fptemp1
		jsr clamp
		jsr facinx
		tya
		lsr
		lsr
		lsr
		sta temp2
		pla
		tay
		pla
		tax
		rts
		
		
clamp
		#faccompm fp255
		cmp #1
		bne dolower
		#ldfacm fp255
		rts
dolower #faccompm fp0
		cmp #255
		bne noclamp
		#ldfacm fp0
noclamp	rts
