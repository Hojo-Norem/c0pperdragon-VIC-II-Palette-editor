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
		GETIN = $ffe4

		c_black=144
		c_white=5
		c_red=28
		c_cyan=159
		c_purple=156
		c_green=30
		c_blue=31
		c_yellow=158
		c_brown=149
		c_lt_red=150
		c_grey1=151
		c_grey2=152
		c_grey3=155
		c_lt_green=153
		c_lt_blue=154
		c_orange=129
		c_up=145
		c_down=17
		c_left=29
		c_right=157
		c_home=19
		c_clear=147
		c_revs_on=18
		c_revs_off=146
		c_return=13
		
*       = $0801
        .word (+), 2005  ;pointer, line number
        .null $9e, format("%d", uploader)
+		.word 0          ;basic line end	
		
uploader

		lda #0
	    sta 53280
		sta 53281
		lda #23
		sta 53272
		lda #unlock
		sta control
		#prints top1
		#prints mpal1
		#prints mpal2
		#prints mpal3
		ldx outputmode
		beq comp
		dex
		beq jrgsb
		#prints rgbns
		jmp +
jrgsb	#prints rgsb
		jmp +
comp	#prints ypbpr
+		#prints prompt
	
-		jsr GETIN
		beq -
		
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
		
-		lda 197
		cmp #64
		bne -
		
-		lda 197
		cmp #64
		beq -
		cmp #25
		beq pyes
		cmp #39
		beq pno
		jmp -
pyes
		lda #save
		sta control
		
pno		lda #0 ;clear input buffer - tweak by me
		sta 198
		lda #c_clear
		jsr $ffd2
		jmp 64738
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
YPbPr	.text c_grey3,"     This is a ",c_lt_green,"Y",c_lt_blue,"Pb",c_red,"Pr",c_grey3," video palette",13,13,0
RGsB	.text c_grey3,"     This is a ",c_red,"R",c_lt_green,"G",c_white,"s",c_lt_blue,"B",c_grey3," video palette",13,13,0
RGBns	.text c_grey3,"     This is a ",c_red,"R",c_lt_green,"G",c_white,"s",c_lt_blue,"B",c_grey1,"ns",c_grey3," video palette",13,13,0

prompt	.text c_grey3," Please toggle your mode select switch",13
		.text "         then press any key...",13,13,0
done	.text "                Done",13,13
		.text "    Save palette to flash? (",c_red,"Y",c_grey3,"/",c_red,"N",c_grey3,")",13,0
top1 	.text c_clear,c_white,176
		.fill 37,96
		.text 174,13,125,"        ",c_lt_green,"C64 Video Enhancement       ",c_white," ",125,13,173
		.fill 37,96
		.text 189,13,0
MPal1	.text c_white,c_revs_on,172,162,162,187,c_revs_off," ",c_revs_on,"    ",c_revs_off," ",c_red,c_revs_on,"    ",c_revs_off," ",c_cyan,c_revs_on,"    ",c_revs_off," ",c_purple,c_revs_on,"    ",c_revs_off," ",c_green,c_revs_on,"    ",c_revs_off," ",c_blue,c_revs_on,"    ",c_revs_off," ",c_yellow,c_revs_on,"    ",c_revs_off,13
		.text c_white,161,"00",c_revs_on,161,c_revs_off," ",c_revs_on," 01 ",c_revs_off," ",c_red,c_revs_on," 02 ",c_revs_off," ",c_cyan,c_revs_on," 03 ",c_revs_off," ",c_purple,c_revs_on," 04 ",c_revs_off," ",c_green,c_revs_on," 05 ",c_revs_off," ",c_blue,c_revs_on," 06 ",c_revs_off," ",c_yellow,c_revs_on," 07 ",c_revs_off,13,0
MPal2	.text c_white,c_revs_on,188,c_revs_off,162,162,c_revs_on,190,c_revs_off," ",c_revs_on,"    ",c_revs_off," ",c_red,c_revs_on,"    ",c_revs_off," ",c_cyan,c_revs_on,"    ",c_revs_off," ",c_purple,c_revs_on,"    ",c_revs_off," ",c_green,c_revs_on,"    ",c_revs_off," ",c_blue,c_revs_on,"    ",c_revs_off," ",c_yellow,c_revs_on,"    ",c_revs_off,13,13

		.text c_orange,c_revs_on,"    ",c_revs_off," ",c_brown,c_revs_on,"    ",c_revs_off," ",c_lt_red,c_revs_on,"    ",c_revs_off," ",c_grey1,c_revs_on,"    ",c_revs_off," ",c_grey2,c_revs_on,"    ",c_revs_off," ",c_lt_green,c_revs_on,"    ",c_revs_off," ",c_lt_blue,c_revs_on,"    ",c_revs_off," ",c_grey3,c_revs_on,"    ",c_revs_off,13,0
MPal3	.text c_orange,c_revs_on," 08 ",c_revs_off," ",c_brown,c_revs_on," 09 ",c_revs_off," ",c_lt_red,c_revs_on," 10 ",c_revs_off," ",c_grey1,c_revs_on," 11 ",c_revs_off," ",c_grey2,c_revs_on," 12 ",c_revs_off," ",c_lt_green,c_revs_on," 13 ",c_revs_off," ",c_lt_blue,c_revs_on," 14 ",c_revs_off," ",c_grey3,c_revs_on," 15 ",c_revs_off,13
		.text c_orange,c_revs_on,"    ",c_revs_off," ",c_brown,c_revs_on,"    ",c_revs_off," ",c_lt_red,c_revs_on,"    ",c_revs_off," ",c_grey1,c_revs_on,"    ",c_revs_off," ",c_grey2,c_revs_on,"    ",c_revs_off," ",c_lt_green,c_revs_on,"    ",c_revs_off," ",c_lt_blue,c_revs_on,"    ",c_revs_off," ",c_grey3,c_revs_on,"    ",c_revs_off,13,13,0

		
		
.align $100,255
.include "shared.asm"

printn .macro number

		ldx \number
		lda #0
		jsr $bdcd
		lda #32
		jsr $ffd2
		.endm
