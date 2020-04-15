;******************************
;Mathematic routines and macros
;******************************
		;C64 rom floating point routine entry points
		CONUPK=47756 	 	;Fetch a number from a RAM location to ARG (A=Addr.LB, Y=Addr.HB)
		MOVEF=48143 	 	;Copy a number currently in ARG, over into FAC
		;MOVFA=48124 	 	;Copy a number currently in FAC, over into ARG
		MOVFA=$bc0c
		MOVFM=48034 	 	;Fetch a number from a RAM location to FAC (A=Addr.LB, Y=Addr.HB)
		MOVMF=48084 	 	;Store the number currently in FAC, to a RAM location. Uses X and Y rather than A and Y to point to RAM. (X=Addr.LB, Y=Addr.HB) 

		FACINX=45482 	 	;Convert number in FAC to 16-bit signed integer (Y=LB, A=HB).
		STRVAL=47029 	 	;Convert numerical PETSCII-string to floating point number in FAC. Expects string-address in $22/$23 and length of string in accumulator.
		GIVAYF=45969 	 	;Convert 16-bit signed integer to floating point number in FAC. Expects lowbyte in Y- and highbyte in A-register.
		
		COS=57956 			;Performs the COS function on the number in FAC
		FADD=47207 	 		;Adds the number in FAC with one stored in RAM (A=Addr.LB, Y=Addr.HB)
		FADDT=47210 	 	;Adds the numbers in FAC and ARG
		FDIV=47887 	 		;Divides a number stored in RAM by the number in FAC (A=Addr.LB, Y=Addr.HB)
		FDIVT=47890 	 	;Divides the number in ARG by the number in FAC. Ignores the sign of the number in FAC and treats it as positive number.
		FMULT=47656 	 	;Multiplies a number from RAM and FAC (clobbers ARG, A=Addr.LB, Y=Addr.HB)
		FSUB=47184 			;Subtracts the number in FAC from one stored in RAM (A=Addr.LB, Y=Addr.HB) 
		FSUBT=47187			;Subtracts the number in FAC from the number in ARG 
		SIN=57963           ;Performs the SIN function on the number in FAC 
		
		FCOMP=48219 		;Compares the number in FAC against one stored in RAM (A=Addr.LB, Y=Addr.HB). The result of the comparison is stored in A: Zero (0) indicates the values were equal.
							;One (1) indicates FAC was greater than RAM and negative one (-1 or $FF) indicates FAC was less than RAM.
							;Also sets processor flags (N,Z) depending on whether the number in FAC is zero, positive or negative 

FACCOMPM .macro address		;compare FAC with memory
		lda #<\address
		ldy #>\address
		jsr fcomp
		.endm
							
FACADDM	.macro address		;add memory to FAC
		lda #<\address
		ldy #>\address
		jsr fadd
		.endm

FACSUBM	.macro address		;sub FAC from memory
		lda #<\address
		ldy #>\address
		jsr fsub
		.endm


FACDIVM .macro address		;divide memory by FAC
		lda #<\address
		ldy #>\address
		jsr fdiv
		.endm

;		See fast multiplaction routine below
;FACMULM .macro address 
;		lda #<\address
;		ldy #>\address
;		jsr fmult
;		.endm
		
LDFACB	.macro number		;immediate load FAC with unsigned byte
		ldy #\number
		lda #0
		jsr givayf
		.endm
		
LDFACY	.macro 				;load FAC with Y register
		lda #0
		jsr givayf
		.endm

LDFACW .macro number		;immediate load FAC with signed word
		ldy #<\number
		lda #>\number
		jsr givayf
		.endm
		
		
LDFACM .macro address		;load FAC from memory
		lda #<\address
		ldy #>\address
		jsr movfm
		.endm
		
LDARG .macro address		;load ARG from memory
		lda #<\address
		ldy #>\address
		jsr conupk
		.endm
		
STFACM	.macro address		;store FAC to memory
		ldx #<\address
		ldy #>\address
		jsr movmf
		.endm
		
TXFA	.macro				;Transfer FAC to ARG
		jsr movfa
		.endm

TXAF	.macro				;Transfer ARG to FAC
		jsr movef
		.endm
		
LDFACT	.macro address		;Load FAC from pstring (byte_length+string)
		lda \address
		ldx #<\address+1
		ldy #>\address+1
		stx $22
		sty $23
		jsr strval
		.endm

LDFACBM	.macro address		;load FAC with a 8 bit unsigned immidiare or from memory
		ldy \address
		lda #0
		jsr givayf
		.endm

							;Load FAC with a signed 16 bit number
LDFAC	.macro Laddress, Haddress
		ldy \Laddress
		lda \Haddress
		jsr givayf
		.endm
		
;cpfp - 	copy one FP number to another without loading the FAC then storing the FAC.
;			Faster and smaller code than using LDFACM and STFACM macros.
cpfp	.macro source, dest	
		ldy #4
-		lda \source,y
		sta \dest,y
		dey
		bpl -
		.endm
ustemp	.byte 0
upscale	tay
		and #1
		sta ustemp
		tya
		asl
		ora ustemp
		asl
		ora ustemp
		asl
		ora ustemp
		rts		
;Fast Floating Point Multiplication - Again borrowed from codebase64 and converted to 64tass
 
;ZP
 
RESULT	= $26 ;-$2c
 
FACX	= $61 ;exponent
FAC	= $62 ;mantissa - $65
;	  $66 ;sign, in MSB
ARGX	= $69 ;exponent
ARG	= $6a ;mantissa - $6d
;	  $6e ;sign, in MSB
SGNCMP  = $6f
 
res8	= 2;$fb ;lobyte of product 
 
 FACMULM .macro address
		lda #<\address
		ldy #>\address
		jsr conupk
		jsr mul_FP
		.endm
 
addresult .macro _num, _carry
_num_ 	:=\_num
_carry_ :=\_carry
	pha
	lda res8
	clc
	adc RESULT+_num_
	sta RESULT+_num_
	pla 
	adc (RESULT-1)+_num_
	sta (RESULT-1)+_num_
	.if _carry_ != 0 
		_num_ := _num_ - 1
		bcc +
		inc (RESULT-1)+_num_
		.for ,_carry_ > 1, 
			_num_ := _num_ - 1
			_carry_ := _carry_ - 1
			bne +
			inc (RESULT-1)+_num_
		.next	
	.endif	
+
.endm

initmultables
	ldx #$00
	txa
	.byte $c9	;cmp #, clears carry, skips tya
lb1	tya
	adc #$00
ml1	sta multabhi,x
	tay
	cmp #$40
	txa
	ror
ml9	adc #$00
	sta ml9+1
	inx
ml0	sta multablo,x
	bne lb1
	inc ml0+2
	inc ml1+2
	clc
	iny
	bne lb1
 
	ldx #$00
	ldy #$ff
-	lda multabhi+1,x
	sta multab2hi+$100,x
	lda multabhi,x
	sta multab2hi,y
	lda multablo+1,x
	sta multab2lo+$100,x
	lda multablo,x
	sta multab2lo,y
	dey
	inx
	bne -
	rts

 
mul_FP	bne +
	rts	;0 in FAC returns 0
+	jsr $bab7	;add exponents
	lda #0		;clear RESULT
	sta $26
	sta $27
	sta $28
	sta $29
	sta $2a
	sta $2b
	sta $2c
 
	lda FAC+3
	ldx ARG+3
	jsr mul8x8	
	sta RESULT+6
	ldx ARG+2
	jsr mulf
	#addresult 6,0
	ldx ARG+1
	jsr mulf
	#addresult 5,0
	ldx ARG
	jsr mulf
	#addresult 4,0
 
	lda FAC+2
	ldx ARG+3
	jsr mul8x8
	#addresult 6,2
	ldx ARG+2
	jsr mulf
	#addresult 5,2
	ldx ARG+1
	jsr mulf
	#addresult 4,2
	ldx ARG
	jsr mulf
	#addresult 3,2
 
	lda FAC+1
	ldx ARG+3
	jsr mul8x8
	#addresult 5,2
	ldx ARG+2
	jsr mulf
	#addresult 4,2
	ldx ARG+1
	jsr mulf
	#addresult 3,2
	ldx ARG
	jsr mulf
	#addresult 2,1
 
	lda FAC
	ldx ARG+3
	jsr mul8x8
	#addresult 4,3
	lda RESULT+4
	sta $70		;rounding byte
	ldx ARG+2
	jsr mulf
	#addresult 3,2
	ldx ARG+1
	jsr mulf
	#addresult 2,1
	ldx ARG
	jsr mulf
	#addresult 1,0
 
	jmp $bb8f	;normal multiply exit.
			;copies RESULT to FAC1
			;and normalises.
 
mul8x8	sta sm1+1                                             
	sta sm3+1                                             
	eor #$ff                                              
	sta sm2+1                                             
	sta sm4+1
mulf	sec   
sm1	lda multablo,x
sm2	sbc multab2lo,x
	sta res8   
sm3	lda multabhi,x
sm4	sbc multab2hi,x
	rts
 

 
multablo = $c000
multabhi = $c200
multab2lo = $c400
multab2hi = $c600