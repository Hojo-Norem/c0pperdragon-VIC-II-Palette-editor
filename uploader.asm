;****************************************
;** Palette editor standalone uploader **
;****************************************
		;interface mem loc and write constants
		Control=53311		;Control register
		Unlock=137			;unlock byte. Writes go to both odd and even colour register tables. 
		Save=138			;save byte
		SelOdd=0			;Writes go to odd scanline colour register table
		SelEven=1			;Writes go to even scanline colour register table
		ColLow=53308		;Colour register low byte register
		ColHigh=53309		;Colour register high byte register
		ColReg=53310		;Colour register address register


		
*       = $0801
        .word (+), 2005  ;pointer, line number
        .null $9e, format("%d", uploader)
+		.word 0          ;basic line end	
		
uploader
		lda #unlock
		sta control
		#prints prompt
		clc
-		lda 197
		cmp #64
		beq -
		clc
-		lda 197
		cmp #64
		bne -		
		ldx #0
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
		inx
		bne -

		
		lda #unlock
		sta control
		#prints done
		rts

prints	.macro address
		ldx #<\address
		ldy #>\address
		jsr sprint
		.endm
	
sprint   stx sprint01+1        ;save string pointer LSB
         sty sprint01+2        ;save string pointer MSB
         ldy #0                ;starting string index

sprint01 lda $1000,y           ;get a character
         beq sprint02          ;end of string

         jsr $ffd2             ;print character
         iny                   ;next
         bne sprint01

sprint02 rts                   ;exit

prompt	.text 13,"Please toggle your mode select switch",13,"then press any key...",13,0
done	.text "Done.  Use command POKE 53311,138 to upload to flash.",13,13,0
		
.align $100,$64
IOrigin 	.fill 17*5
IBright		.fill 17
IContra		.fill 17
ISatura  	.fill 17

.align $100
ColCOS	.fill 16*5
MainPalL	.fill 16
MainPalH	.fill 16

Origin 		.fill 5
Sector		.fill 5
radian		.fill 5
screen		.fill 5
bias		.fill 5
	
Fcontra	.fill 5
Fsatura	.fill 5

FPtemp1	.fill 5
FPTemp2 .fill 5
.align $100
ColSIN	.fill 16*5
.align $100
ColCOSB	.fill 16*5
.align $100
ColSINB	.fill 16*5
.align $100
FullPalOddL	.fill 256
FullPalOddH	.fill 256
FullPalEveL	.fill 256
fullPalEveH	.fill 256