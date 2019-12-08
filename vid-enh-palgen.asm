.comment
		******************************************************************
		******************************************************************
		*******                                                  *********
		*******             C64 Viedo  Enhancement               *********
		*******                      v0.91                       *********
		*******                 Palette Editor                   *********
		*******                                                  *********
		******************************************************************
		******************************************************************
		
						          By Hojo Norem
		
		 For use with with c0pperdragon's Video Enchancement PCB
		 github.com/c0pperdragon
		
		 Assembler used - 64tass
		
		 Palette generator based on the 'colodore' algorithm by pepto
		 www.pepto.de/projects/colorvic/
		
		 What's done:	
						(2019/08/07 - Initial version)
						Default palette generation based on colodore algorithm
						Ability to alter brightness, contrast hue and saturation on a global or per colour basis
						ability to choose between First revision VIC-II lumas (old) and everything else (new)
						PAL colourmixing calculation...  an approximation but works somewhat
						ability to apply old VIC-II lumas to colourmix calaulations for new lumas.  Per colour luma channel is averaged without bias. 
						Upload to device flash
						Built in test image:
											This is just a Koala format bitmap.  I would appreciate something a little better, even if it's only a nice border...
											
						(2019/12/01 - v0.9)
						New test image.  At least it has some meaning now...
						Pepto contacted me a while ago and reccomended that I should be scaling the UV output to better match PbPr output:
											pb = u / 0.872021 pr = v / 1.229951.  To my eye this has improved the accuracy of the default palette.
						Save/Load palettes to/from tape/disk:
											Saved palettes can be re-loaded into the editor for further editing or they can be loaded straight from the
											BASIC prompt like a normal PRG.  For that to function, do NOT load using LOAD"file",1,1 or LOAD"file",8,1.
											THe selected luma table, luma mixing mode and video output mode (even if it currently is locked to YPbPr) is also saved.
											A interrupted load (either through a read error or RUN/STOP) will not corrupt the current palette.
											The last 4 characters of the standard CBM filename is reserved for the extension ".PAL".  The handling
											of this extension is automatic.  Loading from disk will automatically display the directory of the selected
											drive and is filtered to only show files with the .PAL extension.
											
											As the the palette file is saved with it's origin memory address, any cartridge based DMA loader that
											respects load addresses can be used to instantly load the palette into memory.  The 1541 Ultimate II (untested on 
											original Ultimates or II+) has a 'DMA' option in it's action menu when a PRG file is selected.  Use this when 
											instructed by the palette editor.
						(2019/12/08 - v0.91)
						The load menu now automatically recognises when a palette has been DMA loaded.
									
		 What's to do:						
						Implement RGB mode:
							YPbPr / RGsB switch option is coded and is stored with palette during drive I/O.  When a palette is loaded stand-alone the option's state is displayed on screen.
							This requires an implementation of a component>RGB conversion alorithm... 
							And colour 0 needs to switched between black level 15 for pbpr and 0 for RB...
		 
		 Some info:
						The mod uses 16 bit entries for its palette.  The editor stores them as seperate low/high byte arrays.
							
		 Colour calculation arrays (located at end of code):

							MainPalL	.fill 16	|Temporary palette storage used while palette editor is active
							MainPalH	.fill 16	|
							
							Origin 		.fill 5		FP - Hue origin of currently selected colour
							Sector		.fill 5		FP - The hue colour wheel is split into 16 'sectors' (360/16).
							radian		.fill 5		FP - A radian.  The C64 ROMs probably have routines to calculat this.  I'm lazy and did it in VB and stored the result as a text string.  It gest read by a ROM routine into this variable.
							screen		.fill 5		FP - The 'screen' variable in the colodore algo.  I won't pretend to understand what it there for.  The original algo defines it as 1/5.  Like the radian, I just store it as text '0.2'.
							bias		.fill 5		FP - Read in from text.  Used to calculate the biased positions of colours for use in odd/even colour mixing. 
		
							Fcontra		.fill 5		FP - Contrast setting of currently selected colour.
							Fsatura		.fill 5		FP - Saturation setting for the same.

							FPtemp1		.fill 5		FP - Temporary vraiable used during many floating point operations
							
							ColCOS		.fill 16*5	FP - Array for holding calculated cosine calculations for each colour
							ColSIN		.fill 16*5	FP - The same, but for sin calculations.

							ColCOSB		.fill 16*5	FP - Biased version of above
							ColSINB		.fill 16*5	FP - Biased version of above
							
							IOrigin 	.fill 17*5	FP - Array to hold hue origin setting value of each colour
							IBright		.fill 17	The same for brightness
							IContra		.fill 17	And Contrast
							ISatura  	.fill 17	Saturation too.

							FullPalOddL	.fill 256	|Fully calculated palette goes here in seperated low/high byte format.
							FullPalOddH	.fill 256	|There are technically two palettes.  One is used for odd screen lines
							FullPalEveL	.fill 256	|and the other for even lines.  This feature of the mod is used to
							fullPalEveH	.fill 256	|simulate the biasing that occurs in a PAL C64's video output.
.endc
		
		;interface mem loc and write constants
		Control=53311		;Control register
		Unlock=137			;unlock byte. Writes go to both odd and even colour register tables. 
		Save=138			;save byte
		SelOdd=0			;Writes go to odd scanline colour register table
		SelEven=1			;Writes go to even scanline colour register table
		ColLow=53308		;Colour register low byte register
		ColHigh=53309		;Colour register high byte register
		ColReg=53310		;Colour register address register
		
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
		
		;Constants for PETCII control codes
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
		
		;sprite 0 register constants
		Spr0X=$d000
		Spr0Y=$d001
		SprEn=$d015
		Spr0C=$d027
		Spr0P=2040
		SprFF=44
		
		;zeropage addr constants
		;Active_Luma=$02		;Currently active luma table (moved to colour table at end of listing so it can be saved)
		;Mix_Luma=74			;Luma table to use for colour mixing (moved to colour table at end of listing so it will can be saved)
		Bbright=252			;current brightness
		brightsign=64		;sign of normalised brightness
		Nbright=193			;normalised brighness
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
		
		
		;keyboard scancode constants
		key_none = 64
		key_0 = 35
		key_1 = 56
		key_8 = 27
		key_9 = 32
		key_b = 28
		key_c = 20
		key_s = 13
		key_a = 10
		key_h = 29
		key_t = 22
		key_d = 18
		key_u = 30
		key_e = 14
		key_m = 36
		key_l = 42
		key_v = 31
		key_o = 38
		key_f = 21
		key_plus = 40
		key_minus = 43
		
		;Image in koala format for use with the '
		;test_image="orbital impaler.kla"
		test_image="testimage2.kla"

*       = $0801
        .word (+), 2005  ;pointer, line number
        .null $9e, format("%d", PalEdit)
+		.word 0          ;basic line end		
		
PalEdit
		#scroff
		lda #0
	    sta 53280
		sta 53281
		sta PreCalced
		sta outputmode
		
		lda #23
		sta fullcalculation
		sta 53272
		lda #20
		sta boost
		
		

		ldx #0
-		lda lumas,x
		lsr
		lsr
		lsr
		sta temp2
		lda #15
		sta temp3
		sta temp4
		jsr preshift
		lda colreglow
		sta mainpall,x
		lda colreghigh
		sta mainpalh,x
		inx
		cpx #16
		bne -
		
		lda #sprite_x
		sta spr0x
		lda #sprite_y
		sta spr0y
		lda #1
		sta spr0c
		lda #sprff
		sta spr0p
		
		lda lumas+15
		lsr
		lsr
		lsr
		sta temp2
		lda #15
		sta temp3
		sta temp4
		jsr preshift
		lda colreglow
		sta palgrey3
		lda colreghigh
		sta palgrey3+1
			
		jsr printtop
		ldx #<title1
		ldy #>title1
		jsr sprint
		ldx #<title2
		ldy #>title2
		jsr sprint
		ldx #<title3
		ldy #>title3
		jsr sprint
		#scron
		lda #unlock
		sta control
		
		jsr waitkey
		jsr waitrel
		#scroff
		jsr printtop
		ldx #<ChLuma1
		ldy #>ChLuma1
		jsr sprint
		ldx #<ChLuma2
		ldy #>ChLuma2
		jsr sprint
		ldx #<ChLuma3
		ldy #>ChLuma3
		jsr sprint
		lda #1
		sta full_upload
		;sei
		lda #150
wait 	cmp $d012
		bne wait
		lda #106
		sta irq1raster+1
		lda #255
		sta irq2raster+1
		jsr irqinit
		;cli
		#scron
		jsr chooseluma
		jsr waitrel
		#vicirqdis
		lda #10
		sta irq1raster+1
		lda #108
		sta irq2raster+1
		
		#vicirqen
mainscr	#scroff
		;jsr printtop
		lda #c_clear
		jsr $ffd2
		ldx #<MPal1
		ldy #>MPal1
		jsr sprint
		ldx #<MPal2
		ldy #>MPal2
		jsr sprint		
		ldx #<MPal3
		ldy #>MPal3
		jsr sprint
		#scron
		lda PreCalced
		bne SkipCalc
		ldx #<PreClk
		ldy #>PreClk
		jsr sprint			
		jsr PreCalc
		jsr incselcol

		lda #1
		sta PreCalced
SkipCalc

		#prints maincon
		#prints maincon2
		#printtat footer,#0,#21
		jsr dispmix
		jsr dispvid
		jsr drawselcol
		jmp drawval
		

		


update_origin
		ldx currcol
		cpx #16
		bne onlyoneo

		ldx #1
-		jsr dotrig
		inx
		cpx #16
		bne -
		ldy selparam
		jmp update
		
onlyoneo
		jsr dotrig
		jmp update
		
doorigin_m
		#ldfacb 1
		#facsubm origin
		#stfacm origin

		jmp update_origin
		
pressminus
		ldy selparam
		beq ++
		cpy #4
		beq doorigin_m
		ldx selparam,y
		cpx #0
		beq +
		dex
		dex
+		stx selparam,y
		jmp update
+		jmp menuloop	

pressplus
		ldy selparam
		beq ++
		cpy #4
		beq doorigin_p
		ldx selparam,y
		cpx #100
		beq +
		inx
		inx
+		stx selparam,y
		jmp update
+		jmp menuloop

doorigin_p
		#ldfacb 1
		#facaddm origin
		#stfacm origin
		jmp update_origin
		
menuloop
		;cli
		ldy #0
		;clc
		lda 197
		cmp #key_none
		beq menuloop
		cmp #key_plus
		beq	pressplus
		cmp #key_minus
		beq pressminus
		cmp #key_b
		beq jparamkey_b
		cmp #key_c
		beq jparamkey_c
		cmp #key_s
		beq jparamkey_s
		cmp #key_h
		beq jparamkey_h
		cmp #key_f
		beq jsavecol
		cmp #key_t
		beq jshowtest
		cmp #key_e
		beq changecurrcol
		cmp #key_l
		beq jchangemix
		cmp #key_a
		beq savecols
		cmp #key_o
		beq loadcol
		;cmp #key_v
		;beq togglevid
		jmp menuloop

savecols
		jmp saveram
loadcol
		jmp loadram
		
jchangemix
		jsr changemix
		jmp menuloop
		
		
jshowtest
		jmp showtest
		
jparamkey_b
		jmp paramkey_b
jparamkey_c
		jmp paramkey_c
jparamkey_s
		jmp paramkey_s
jparamkey_h
		jmp paramkey_h
		
jsavecol
		jmp savecol



		
changecurrcol
		
		jsr waitrel
		jsr incselcol
		jsr drawselcol
		jmp drawval


togglevid
		jsr waitrel
		lda outputmode
		eor #255
		sta outputmode
		jsr dispvid
		jmp menuloop
		
dispvid
		lda outputmode
		bne +
		#printtat ypbpr,#7,#readouty+6
		rts
+		#printtat rgsb,#7,#readouty+6
		rts		
		

.align 256,00
sprites
		.binary "rotate.spr",2
paramkey_h
		iny
paramkey_s
		iny
paramkey_c
		iny
paramkey_b
		iny
		sty selparam
drawval	lda selparam
		ldx #1
		cmp #1
		bne +
		ldx #3
+		stx 646
		#printnat bbright, #brix, #readouty
		ldx #1
		lda selparam
		cmp #2
		bne +
		ldx #3
+		stx 646
		#printnat bcontra, #conx, #readouty
		ldx #1
		lda selparam
		cmp #3
		bne +
		ldx #3
+		stx 646
		#printnat bsatura, #satx, #readouty
		ldx #1
		lda selparam
		cmp #4
		bne +
		ldx #3
+		stx 646
		#ldfacm origin
		#printfat #originx, #readouty+4
		jmp menuloop
changemix
		jsr waitrel
		lda active_luma
		bne +++
		lda mix_luma
		beq +
		lda #0
		jmp ++
+		lda #16
+		sta mix_luma
		

		jsr dispmix
		lda fullcalculation
		bne +
		lda #17
		sta fullcalculation
+		rts

dispmix
		lda active_luma
		bne ++
		lda mix_luma
		bne +
		#printtat lumamodenew,#0,#readouty+8
		jmp ++
+		#printtat lumamodemix,#0,#readouty+8
+		rts
	
drawselcol
		ldx #1
		stx 646
		ldx currcol
		cpx #16
		beq +
		stx temp1
		#printnat temp1,#currcolx,#readouty+4
		lda #32
		jsr $ffd2
		jmp ++
+		#printtat alltxt,#currcolx,#readouty+4
+		rts

cpyparams
		
		ldy #1
-		ldx x5tab,y		
		lda origin
		sta iorigin,x
		lda origin+1
		sta iorigin+1,x
		lda origin+2
		sta iorigin+2,x
		lda origin+3
		sta iorigin+3,x
		lda origin+4
		sta iorigin+4,x
		lda bbright
		sta ibright,y
		lda bcontra
		sta icontra,y
		lda bsatura
		sta isatura,y
		iny
		cpy #17
		bne -
;		lda #1
;		sta fullcalculation
		ldy currcol
		rts 
		
		
		
incselcol
		ldx currcol
		
		lda bsatura
		sta isatura,x
		
		lda bcontra
		sta icontra,x
		
		lda bbright
		sta ibright,x
		#ldfacm origin
		ldy currcol
		ldx x5tab,y
		ldy #>iorigin
		jsr movmf
		ldy currcol
		lda fullcalculation
		cmp #16
		bne not16
		jsr cpyparams
		
		
not16	iny
		cpy #17
		bne +
		ldy #1
+		sty currcol
		ldx isatura,y
		stx bsatura
		ldx icontra,y
		stx bcontra
		ldx ibright,y
		stx bbright
		lda x5tab,y
		ldy #>iorigin
		jsr movfm
		#stfacm origin
		jsr norm_bri
		jsr norm_sat
		jsr norm_con
		rts
		
savecol
		;#scroff
		
		jsr waitrel
		lda #255
		sta full_upload
		lda #c_clear
		jsr $ffd2
		jsr fullsave


		;#scron


		
		jmp mainscr
		
update
		lda currcol
		sta fullcalculation
		cpy #1
		bne +
		jsr norm_bri
		jmp recalc
+		cpy #2
		bne +
		jsr norm_con
		jmp recalc
+		cpy #3
		bne +
		jsr norm_sat

+		
recalc	
		ldx currcol
		cpx #16
		bne onlyone
		ldx #1		
-		jsr calccol
		jsr preshift
		;jsr upload
		lda colreglow
		sta mainpall,x
		lda colreghigh
		sta mainpalh,x
		inx
		cpx #16
		bne -
		lda #1
		sta full_upload
		jmp drawval
onlyone
		jsr calccol
		jsr preshift
		lda colreglow
		sta mainpall,x
		lda colreghigh
		sta mainpalh,x
		lda #1
		sta full_upload
		jmp drawval

		
fullsave
		#vicirqdis
		jsr fullcalc
		#scroff
		ldy #25
- 		cpy $d012
		bne -
		dey
		bne -
		lda #save
		sta control
		ldy #25
- 		cpy $d012
		bne -
		dey
		bne -
		lda #0
- 		cmp $d012
		bne -
		#scron
		#prints locktxt
		#vicirqen
		jsr waitkey
		jsr waitrel
		lda #1
		sta full_upload
		rts

jskipmixcalc
		jmp skipmixcalc
fullcalculation
		.byte 0
		
tempY	.byte 0,0
tempU	.byte 0,0
tempV	.byte 0,0
tabin	.byte 0
tempreg	.byte 0

spinsprite
		pha
		txa
		pha
		ldx #220
- 		cpx $d012
		bne -
		ldx spr0p
		inx
		cpx #48
		bne +
		ldx #44
+		stx spr0p
		pla
		tax
		pla
		rts

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
		;lda tempy
		clc
		lda temp2			;load Y value
		adc tempy			;add above Y value
		lsr					;divide by two
		sta temp2			;store here because the preshifter routine uses it
		clc
		lda temp3			;load Y value
		adc tempu			;add above Y value
		lsr					;divide by two
		sta temp3			;store here because the preshifter routine uses it
		clc
		lda temp4			;load Y value
		adc tempv			;add above Y value
		lsr					;divide by two
		sta temp4			;store here because the preshifter routine uses it
		rts
		

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
		lda #>colcosb
		sta costab+1
		lda #>colsinb
		sta sintab+1
		
mixtab1	lda $c000,x
		beq donetable
		tax
		asl
		asl
		asl
		asl
		sta tempreg

		jsr getparams
		
		jsr calccol
		lda temp2
		sta tempy
		lda temp3
		sta tempu
		lda temp4
		sta tempv
		
		;jsr spinsprite
		
		lda #>colcos
		sta costab+1
		lda #>colsin
		sta sintab+1
		
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
		
		jsr preshift
		
		ldy tempreg
		lda colreglow
		sta fullpaloddl,y
		lda colreghigh
		sta fullpaloddh,y
		tya
		ASL  
        ADC #$80
        ROL  
        ASL  
        ADC #$80
        ROL  
		tay
		lda colreglow
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
		.comment
		ldx bsatura
loopsat	stx bsatura
		;lda #15
		;sta 53280
		jsr norm_sat
		ldx #1
-		jsr calccol
		jsr upload
		inx
		cpx #16
		bne -
		ldx bsatura
		inx
		inx
		cpx #102
		bne loopsat
		ldx #0
		jmp loopsat
		.endc
	
		
		
		
		
freezed jmp freezed

chooseluma
		pha
wrong1	jsr waitkey
		cmp #39			; key N
		beq wright1
		cmp #38			; key O
		beq wright2
		;cmp #22			; Key T
		;beq wright3
		jmp wrong1
wright1	lda #New_Lumas
		jmp onwards
wright2	lda #Old_Lumas
		jmp onwards
wright3	lda #Tweaked_Lumas
onwards	sta Active_Luma
		sta Mix_Luma
		pla
		rts

PreCalc

		lda #1
		sta spren
		#ldfacb 0
		#stfacm fpm128
		#LDFACB 127
		#STFACM FP127
		#facsubm fpm128
		#stfacm fpm128
		;Make radian FP number from string
		#ldfact radtxt
		#STFACM radian
		;Make PrPb scaling FP constants from string	
		#ldfact ScalePb
		#STFACM FPScalePb
		#ldfact ScalePr
		#STFACM FPScalePr
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
		;calculate sector (360/16)
		#ldfacw 360
		#STFACM fptemp1
		#ldfacb 16
		#facdivm fptemp1
		#STFACM sector
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
		;Make screen FP number from string
		#ldfact scrtxt
		#STFACM screen
		;Make colour mixing bias FP number from string
		#ldfact biatxt
		#STFACM bias	
		jsr norm_sat
		jsr norm_con
		jsr norm_bri
		ldx #0
deftrig	jsr dotrig
		jsr calccol
		jsr preshift
		lda colreglow
		sta mainpall,x
		lda colreghigh
		sta mainpalh,x
		
		jsr spinsprite
		
		inx
		cpx #16
		bne deftrig
		lda #1
		sta full_upload
		lda #0
		sta spren
		rts


norm_bri
		sec
		lda bbright
		sbc #50
		bpl setplus
		lda #50
		sec
		sbc bbright
		sta Nbright
		lda #1
		jmp docontr
setplus	sta Nbright
		lda #0
docontr	sta brightsign
		;#printnat brightsign,#1,#1
		;#printnat bright,#1,#2
		rts
		

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
		
		


itsblack
		lda #0
		sta temp2
		;sta ytab
		ldy #0
itsgry	lda #15
		sta temp3
		sta temp4
		;sta utab,y
		;sta vtab,y
		jmp donecol
		
CalcCol	txa
		sta temp1
		beq itsblack
		clc
		lda active_luma
		adc temp1
		tay
		lda lumas,y
		;tay
		ldy brightsign
		beq doplusbri
		;tya
		sec
		sbc Nbright
		;bpl finbri
		;lda #0
		jmp finbri
doplusbri
		clc
		
		adc Nbright
		bcc finbri
		lda #255
finbri	
		lsr
		lsr
		lsr
		
		tay
		
		
		
		ldx Conlut,y
		stx pcluth
		ldy ncontra
		lda (pclutl),y
		
		.comment
finbri	tay
		lda #0
		jsr givayf

		#facmulm fcontra
		
		jsr facinx
		cmp #0
		beq skipmax
		lda #31
		jmp donebri
skipmax	tya
		lsr
		lsr
		lsr
		.endc
donebri	sta temp2
		ldy temp1
		;sta ytab,y
		

;u=int((((uc(ci)*fsatura)*fcontra)+127)/255)	
		;ldy temp1
		lda angles,y
		beq itsgry
		lda x5tab,y
costab	ldy #>colcos
		jsr movfm
		
		;lda #<fsatura
		;ldy #>fsatura
		;jsr fmult
		;lda #<fcontra
		;ldy #>fcontra
		;jsr fmult
		#FACMULM fsatura
		#FACMULM fcontra
		#STFACM FPtemp1
		#LDFACM FPScalePb
		#FACDIVM FPtemp1
		
		lda #<FP127
		ldy #>FP127
		jsr FCOMP
		cmp #1
		bne +
		#LDFACM FP127
		
+		jsr facinx
		tya
		clc
		adc #127
		lsr
		lsr
		lsr
		
		
		sta temp3
		;sty temp3
		ldy temp1
		;sta utab,y

		
		;ldy temp1
		lda x5tab,y
sintab	ldy #>colsin
		jsr movfm
		;lda #<fsatura
		;ldy #>fsatura
		;jsr fmult
		;lda #<fcontra
		;ldy #>fcontra
		;jsr fmult
		#FACMULM fsatura
		#FACMULM fcontra
		#STFACM FPtemp1
		#LDFACM FPScalePr
		#FACDIVM FPtemp1

		lda #<FPm128
		ldy #>FPm128
		jsr FCOMP
		cmp #255
		bne +
		#LDFACM FPm128
		
+		jsr facinx
		tya
		clc
		adc #127
		lsr
		lsr
		lsr
		
		sta temp4
		;ldy temp1
		;sta vtab,y		

		
		

donecol	
		.comment
		lda #0
		ldx temp2
		jsr $bdcd
		#prints somespaces
		lda #0
		ldx temp3
		jsr $bdcd
		#prints somespaces
		lda #0
		ldx temp4
		jsr $bdcd
		#prints somespaces		
		lda #13
		jsr $ffd2	
		.endc
		
		ldx temp1
		rts

		
preshift
		lda temp3
		tay
		asl
		asl
		asl
		asl
		asl
		ora temp4
		sta colreglow
		lda temp2
		asl
		asl
		sta colreghigh
		tya
		lsr
		lsr
		lsr
		ora colreghigh
		sta colreghigh
		rts
		;ldy temp1
			
upload
		;lda colreglow
		;sta collow
		;lda colreghigh
		;sta colhigh
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


		; calculate colour trigonoetry for colour index stored in X register
DoTrig	stx temp1
		ldy angles,x
		beq nocol
		;jmp nocol
		; angle = ( origin + angles[ index ] * sector ) * radian;
		lda #0
		jsr givayf
		lda #<sector
		ldy #>sector
		jsr fmult
		lda #<origin
		;ldy temp1
		;lda x5tab,y
		ldy #>origin
		jsr fadd
		lda #<radian
		ldy #>radian
		jsr fmult
		;ldx #<FPtemp1
		;ldy #>fptemp1
		;jsr movmf
		#STFACM fptemp1
		jsr cos
		ldy temp1
		ldx x5tab,y
		ldy #>colcos
		jsr movmf
		#facmulm bias
		ldy temp1
		ldx x5tab,y
		ldy #>colcosb
		jsr movmf
		;lda #<FPtemp1
		;ldy #>fptemp1	
		;jsr movfm
		#ldfacm fptemp1
		jsr sin
		ldy temp1
		ldx x5tab,y
		ldy #>colsin
		jsr movmf
		#facmulm bias
		ldy temp1
		ldx x5tab,y
		ldy #>colsinb
		jsr movmf
		jmp doneang		
nocol	;lda #<FPzero
		;ldy #>fpzero	
		;jsr movfm
		#ldfacb 0
		ldy temp1
		ldx x5tab,y
		ldy #>colcos
		jsr movmf
		ldy temp1
		ldx x5tab,y
		ldy #>colcosb
		jsr movmf
		ldy temp1
		ldx x5tab,y
		ldy #>colsin
		jsr movmf
		ldy temp1
		ldx x5tab,y
		ldy #>colsinb
		jsr movmf
doneang
		ldx temp1
		rts

		;constants for bitmap displayer
		vscreen=$0400
		colram=$d800
		;bitmap=$2000
		
		colour=charcol+$3e8
		background=charcol+$7d0
scrrestore
		.byte 0
showtest
		jsr waitrel

		;jsr fullcalc
		#vicirqdis
		#scroff
		lda #0
		sta $d020
		lda background
		sta $d021
		
		ldx #0
-		lda charcol,x
		sta vscreen,x
		lda charcol+$100,x
		sta vscreen+$100,x
		lda charcol+$200,x
		sta vscreen+$200,x
		lda charcol+$2e8,x
		sta vscreen+$2e8,x
		
		lda colour,x
		sta colram,x
		lda colour+$100,x
		sta colram+$100,x
		lda colour+$200,x
		sta colram+$200,x
		lda colour+$2e8,x
		sta colram+$2e8,x
		inx
		bne -
		lda $d011
		ora #32
		and #%01111111
		sta $d011
		lda $d016
		ora #16
		sta $d016
		lda $d018
		sta scrrestore
		lda #$18
		sta $d018
		#scron
		jsr fullcalc
		
		#vicirqen
		jsr waitkey
		jsr waitrel
		#scroff
		;switch to char mode here
		lda $d011
		and #%00011111
		sta $d011
		lda $d016
		and #%11101111
		sta $d016
		lda scrrestore
		sta $d018
		lda #0
		sta $d021
		sta full_upload
		jmp mainscr
		
setcol 	ldy mainpall,x
		sty collow
		ldy mainpalh,x
		sty colhigh
		jsr upload
		rts

partial	ldx #2
		jsr setcol
		
		ldx #3
		jsr setcol

		ldx #13
		jsr setcol

		ldx #15
		jsr setcol
		
		ldx #1
		jsr setcol

		ldx #14
		jsr setcol

		ldx #8
		jsr setcol
		
		jmp finirq1

		
IRQ1
		;jsr linespin
		lda full_upload
		beq partial
		bmi finirq1
		ldx #1
-		jsr setcol
		inx
		cpx #16
		bne -
		lda full_upload
		bmi finirq1
		lda #0
		sta full_upload
finIRQ1
		;jsr linespin
		

	
		lda #<IRQ2
		sta $0314
		lda #>IRQ2
		sta $0315
		
IRQ2Raster
		lda #0
		sta $d012
		asl $d019
		;lda full_upload
		;bmi speedup
		jmp $ea31
;speedup
		;jmp $ea81
		;jmp $ea81
		
		
IRQ2
		lda full_upload
		bmi finirq2

		ldx #2
		;stx 53280
		ldy palred
		sty collow
		ldy palred+1
		sty colhigh
		jsr upload
		
		ldx #15
		ldy palgrey3
		sty collow
		ldy palgrey3+1
		sty colhigh
		jsr upload

		;lda #0
		;sta 53280
		
		ldx #3
		ldy palflash
		sty collow
		ldy palflash+1
		sty colhigh
		jsr upload
		
		ldx #1
		ldy palwhite
		sty collow
		ldy palwhite+1
		sty colhigh
		jsr upload
		
		jsr othercols

		jsr doflash
		

finirq2	
		lda #<IRQ1
		sta $0314
		lda #>IRQ1
		sta $0315
		
IRQ1Raster
		lda #0
		sta $d012
		asl $d019
		jmp $ea81
		;jmp $ea31

doflash
		ldy palflash+2
		lda palflash+3
		cmp #63
		bne goup
		dey
		cpy #0
		bne flshdn
		sty palflash+3
		jmp flshdn

goup	ldy palflash+2
		iny
		cpy #63
		bne flshdn
		sty palflash+3

flshdn	sty palflash+2
		tya 
		asl
		and #%01111100
		sta palflash+1
		rts

othercols
		ldx #14
		ldy palltblue
		sty collow
		ldy palltblue+1
		sty colhigh
		jsr upload
		
		ldx #8
		ldy palgrey1
		sty collow
		ldy palgrey1+1
		sty colhigh
		jsr upload
		
		ldx #13
		ldy PalLtGrn
		sty collow
		ldy PalLtGrn+1
		sty colhigh
		jsr upload
		rts
		
IRQRest .byte 0,0

ResetIRQ
		sei
		lda irqrest
		sta $0314
		lda irqrest+1
		sta $0315
		#vicirqdis
		lda #$81
		sta $dc0d
		cli
		rts
		
SetIRQ  sei
		lda #$7f
		sta $dc0d
		lda $0314
		sta IRQRest
		lda $0315
		sta IRQRest+1
		lda #<IRQ1
		sta $0314
		lda #>IRQ1
		sta $0315
		#vicirqen
		cli
		rts
IRQInit

		and $d011
		sta $d011
		lda #255
		sta $d012
		jsr setirq
		;lda #%00000001
		;sta $d01a
		rts

		
INPUT_Y
		.byte $00

GOTINPUT
		.text "            .pal",0
		
seldevice
		.byte 0
		
saveram
		jsr prepls

		jsr getdrive
		ldy seldevice
		cpy #0
		bne +

		jsr SetIRQ
		jmp mainscr
		
+		#prints fntxt
		jsr filtered_text
		lda #64
		sta FullPalOddL-1
		jsr fullcalc
		lda #13
		jsr $ffd2
		lda seldevice
		cmp #1
		beq +
		#prints dsave
		jmp ++
+		#prints tapetxt
		jsr waitkey
		jsr waitrel		
		
+       ;LDA input_y
		lda #16
        LDX #<gotinput
        LDY #>gotinput
        JSR $FFBD     ; call SETNAM
        LDA #$00
;       LDX $BA       ; last used device number
;       BNE +
        LDX seldevice      ; default to device 8
+	    LDY #$00
        JSR $FFBA     ; call SETLFS

        LDA #<uploader
        STA temp1
        LDA #>uploader
        STA temp2

        LDX #<endoftheshow
        LDY #>endoftheshow
        LDA #temp1      ; start address located in $C1/$C2
        JSR $FFD8     ; call SAVE
        BCS +		    ; if carry set, a load error has happened
        jmp ++
+
        ; Akkumulator contains BASIC error code
		jsr printerr
		;jsr $ffe7
        ;#prints dertxt
		
		jsr waitrel
		jsr waitkey
		jsr waitrel
        
+		
		jsr $ffe7
		jsr SetIRQ
		jmp mainscr	


jlerror jmp lerror

loadram
		jsr prepls
		#prints dmatxt
		jsr getdrive
		ldy seldevice
		cpy #0
		bne +

nofile	jsr SetIRQ
		jmp mainscr
		
		;lda seldevice
+		cpy #1
		beq ldtape
		lda #255
		sta errno
		jsr displaydir
		lda errno
		cmp #255
		bne jlerror
		lda filesfound
		bne +
		#prints nofiles
		#prints paktxt
		jsr waitkey
		jsr waitrel
		jmp nofile
+		#prints found1
		#printn	filesfound
		#prints found2
		#prints fntxt
		jsr filtered_text
		lda #13
		jsr $ffd2
		#prints dload
		jmp +
ldtape	#prints tapetxt
		lda #0
		sta input_y
		jsr waitkey
		jsr waitrel		
		
+       LDA input_y
		;lda #16
        LDX #<gotinput
        LDY #>gotinput
        JSR $FFBD     ; call SETNAM
        LDA #$00
;       LDX $BA       ; last used device number
;       BNE +
        LDX seldevice      ; default to device 8
+	    LDY #$00
        JSR $FFBA     ; call SETLFS


        LDX #<(endoftheshow+1);uploader
        LDY #>(endoftheshow+1);uploader
        LDA #0
        JSR $FFD5     ; call load
        BCS lerror		    ; if carry set, a load error has happened
        jmp loaddone
lerror
        ; Akkumulator contains BASIC error code
		jsr printerr
		jsr $ffe7
        ;#prints dertxt
		
		jsr waitrel
		jsr waitkey
		jsr waitrel
		jsr SetIRQ
		jmp mainscr	
        
loaddone
		jsr $ffe7
		ldx #0
-		lda Load_Block0,x
		sta IOrigin,x
		lda Load_Block1,x
		sta Colcos,x
		lda Load_Block2,x
		sta Colsin,x
		lda Load_Block3,x
		sta colcosb,x
		lda Load_Block4,x
		sta colsinb,x
		inx
		bne -
fixpal	ldy #16
		sty currcol
		ldx isatura,y
		stx bsatura
		ldx icontra,y
		stx bcontra
		ldx ibright,y
		stx bbright
		lda x5tab,y
		ldy #>iorigin
		jsr movfm
		#stfacm origin
		jsr norm_bri
		jsr norm_sat
		jsr norm_con	
		jsr SetIRQ
		jmp mainscr	

;jfixpal jmp fixpal

getdrive
		#prints devtxt
		lda #255
		sta FullPalOddL-1 
		ldy #0
		clc
-		lda 197
		;cmp #key_none
		;beq -
		cmp #key_t
		beq	presstape
		cmp #key_d
		beq	pressdisk
		cmp #key_c
		beq	presscancel
		lda FullPalOddL-1
		cmp #255
		bne fixpal
		jmp -
presstape
		ldy #1
presscancel
		sty seldevice
		rts
pressdisk
		
		#prints devnot
		ldy #8
		clc
-		lda 197
		cmp #key_none
		beq -
		cmp #key_0
		beq drive10
		cmp #Key_1
		beq drive11
		cmp #key_9
		beq drive9
		cmp #key_8
		beq drive8
		jmp -
drive11
		iny
drive10
		iny
drive9
		iny
drive8
		sty seldevice
		rts
		
		
prepls
		lda #c_clear
		jsr $ffd2
		jsr resetirq
		ldx #2
		ldy palred
		sty collow
		ldy palred+1
		sty colhigh
		jsr upload		
		ldx #15
		ldy palgrey3
		sty collow
		ldy palgrey3+1
		sty colhigh
		jsr upload
		ldx #1
		ldy palwhite
		sty collow
		ldy palwhite+1
		sty colhigh
		jsr upload
		lda #0
		sta input_y
		sty seldevice
		lda #17
		sta fullcalculation
		rts

cancel	jmp mainscr
		


;******* The following snippet was borrowed without shame from codebase64.org ********
		
;======================================================================
;Input a string and store it in GOTINPUT, terminated with a null byte.
;x:a is a pointer to the allowed list of characters, null-terminated.
;max # of chars in y returns num of chars entered in y.
;======================================================================

GETIN = $ffe4

; Example usage
FILTERED_TEXT

	lda #0 ;clear input buffer - tweak by me
	sta 198
	lda #' '
	ldy #12
-	dey				;clear string buffer - tweak by me
	sta gotinput,y
	bne -
	
  lda #>filter
  ldx #<filter
  ldy #12
  ;Drop through

; Main entry
FILTERED_INPUT
  sty MAXCHARS
  stx CHECKALLOWED+1
  sta CHECKALLOWED+2

  ;Zero characters received.
  lda #$00
  sta INPUT_Y

;Wait for a character.
INPUT_GET
  jsr GETIN
  beq INPUT_GET

  sta LASTCHAR

  cmp #$14               ;Delete
  beq DELETE

  cmp #$0d               ;Return
  beq INPUT_DONE

  lda input_y    ; move maxchar check here to ignore characters at maxchar - tweak by me
  cmp maxchars
  beq input_get
  
  ;Check the allowed list of characters.
  ldx #$00
CHECKALLOWED
  lda $FFFF,x           ;Overwritten
  beq INPUT_GET         ;Reached end of list (0)

  cmp LASTCHAR
  beq INPUTOK           ;Match found

  ;Not end or match, keep checking
  inx
  jmp CHECKALLOWED

INPUTOK
  lda LASTCHAR          ;Get the char back
  ldy INPUT_Y
  sta GOTINPUT,y        ;Add it to string
  jsr $ffd2             ;Print it

  inc INPUT_Y           ;Next character

  ;End reached?
  ;lda INPUT_Y        disabled maxchar check here.  Dont want to finixh input on maxchar - tweak by me
  ;cmp MAXCHARS
  ;beq INPUT_DONE

  ;Not yet.
  jmp INPUT_GET

INPUT_DONE
		ldy #16
		sty input_y
		ldx #0
-  		lda entrytest,x
		sta gotinput+12,x
		inx
		cpx #4
		bne -
   ;lda #$00                             ;don't zero terminate.  All filenames are 16 chars long (12+".PAL")
   ;sta GOTINPUT,y   ;Zero-terminate
		lda #0 ;clear input buffer
		sta 198
   rts

; Delete last character.
DELETE
  ;First, check if we're at the beginning.  If so, just exit.
  lda INPUT_Y
  bne DELETE_OK
  jmp INPUT_GET

  ;At least one character entered.
DELETE_OK
  ;Move pointer back.
  dec INPUT_Y

  ;Store a zero over top of last character, just in case no other characters are entered.
  ldy INPUT_Y
  lda #' '
  sta GOTINPUT,y

  ;Print the delete char
  lda #$14
  jsr $ffd2

  ;Wait for next char
  jmp INPUT_GET


;=================================================
;Some example filters
;=================================================

filter	.text " abcdefghijklmnopqrstuvwxyz1234567890.-+!#$%&()",0

;=================================================
MAXCHARS
		.byte $00

LASTCHAR
		.byte $00


		
;********* Now back to your scheduled insanity *********

printerr
		sta errno
		#prints errdrv
		#printn seldevice
		lda errno
		cmp #05
		beq pdnp
		cmp #04
		beq pfnf
		cmp #$1d
		beq ple
		cmp #0
		beq prs
		#prints errdef
		#printn errno
		lda #13
		jsr $ffd2
		lda #13
		jsr $ffd2
		#prints paktxt
		rts
pdnp	#prints errdnp
		#prints paktxt
		rts
pfnf	#prints errfnf
		#prints paktxt
		rts
ple		#prints errle
		#prints paktxt
		rts
prs		#prints errbrk
		#prints paktxt
		rts
		
displaydir
		lda #0
		sta quotemode
		sta disktitle
		sta filesfound
		lda #c_white
		jsr $ffd2
        LDA #1
        LDX #<dddirname
        LDY #>dddirname
        JSR $FFBD      ; call SETNAM

        LDA #$02       ; filenumber 2
        ;LDX $BA
        ;BNE ddskip
        LDX seldevice  
		LDY #$00       ; secondary address 0 (required for dir reading!)
        JSR $FFBA      ; call SETLFS

        JSR $FFC0      ; call OPEN (open the directory)
        BCS dderror     ; quit if OPEN failed

        LDX #$02       ; filenumber 2
        JSR $FFC6      ; call CHKIN

        LDY #$04       ; skip 4 bytes on the first dir line
        BNE ddskip2
ddnext
        ;LDY #$02       ; skip 2 bytes on all other lines
		ldy #2
ddskip2  JSR ddgetbyte    ; get a byte from dir and ignore it
        DEY
        BNE ddskip2
        JSR ddgetbyte    ; get low byte of basic line number
		JSR ddgetbyte    ; get high byte of basic line number
 
ddchar
        ;JSR $FFD2      ; call CHROUT (print character)
        JSR ddgetbyte
		sta temp1
		ldx disktitle
		beq jpdisktitle
		cmp #34
		beq jgotquote
		ldx quotemode
		beq nextchar
		sta direntry-1,x
		inx
		stx quotemode
nextchar
		lda temp1
		BNE ddchar      ; continue until end of line

nextline
		lda #0
		sta quotemode
		;LDA #$0D
		;sta disktitle
        ;JSR $FFD2      ; print RETURN
        JSR $FFE1      ; RUN/STOP pressed?
        BNE ddnext      ; no RUN/STOP -> continue
jpdisktitle
		jmp pdisktitle
jgotquote
		jmp gotquote
dderror
        ; Akkumulator contains BASIC error code
		sta errno
        ; most likely error:
        ; A = $05 (DEVICE NOT PRESENT)
ddexit
        LDA #$02       ; filenumber 2
        JSR $FFC3      ; call CLOSE

        JSR $FFCC     ; call CLRCHN
		;lda #13
		;jsr $ffd2		
		lda #13
		jsr $ffd2
        RTS

ddgetbyte:
        JSR $FFB7      ; call READST (read status byte)
        BNE ddend       ; read error or end of file
        JMP $FFCF      ; call CHRIN (read byte from directory)
ddend
        PLA            ; don't return to dir reading loop
        PLA
        JMP ddexit

dddirname:
        .TEXT "$"      ; filename used to access directory		

filesfound
		.byte 0
		
disktitle
		.byte 0
quotemode
		.byte 0
clrentry
		pha
		ldy #0
		lda #0
-		sta direntry+12,y
		iny
		cpy #4
		bne -
		pla
		rts

pdisktitle
		lda temp1
		bne +
		LDA #$0D
		sta disktitle
+		jsr $ffd2
		jmp nextchar
gotquote
		ldx quotemode
		bne +
		inx
		stx quotemode
		jmp nextchar
+		ldx #0
		stx quotemode
		dex
-		inx
		lda entrytest,x
		sta cmptmp
		lda direntry+12,x
		cmp cmptmp
		beq -
		cpx #4
		bne dircont
		lda #13
		sta direntry+12
		lda #0
		sta direntry+13
		#prints direntry
		inc filesfound
dircont	jmp nextchar


cmptmp	.byte 0

entrytest
		.text ".pal",255

direntry
		.text "1234567890abcdef",0		

jSCRON	lda 53265
		ora #16
		and #%01111111
		sta 53265
		lda #0
- 		cmp $d012
		bne -
		rts
		
jSCROFF lda 53265
		and #239
		and #%01111111
		sta 53265
		lda #0
- 		cmp $d012
		bne -
		rts

s_printn
		lda #0
		jsr $bdcd
		lda #32
		jsr $ffd2
		rts

s_printnat
		lda #0
		jsr $bdcd
		lda #32
		jsr $ffd2
		rts
		
printtop
	ldx #<top1
	ldy #>top1
	jsr sprint
	rts
	
sprint   stx sprint01+1        ;save string pointer LSB
         sty sprint01+2        ;save string pointer MSB
         ldy #0                ;starting string index

sprint01 lda $1000,y           ;get a character
         beq sprint02          ;end of string

         jsr $ffd2             ;print character
         iny                   ;next
         bne sprint01

sprint02 rts                   ;exit

waitkey	
		lda #0 ;clear input buffer
		sta 198
;		clc
;-		lda 197
;		cmp #64
;		beq -
-		jsr GETIN
		beq -
		lda 197
		rts
		
waitrel 
		clc
		lda 197
		cmp #64
		bne waitrel
		lda #0 ;clear input buffer 
		sta 198
		rts
		
radtxt	.ptext "0.0174532925"
scrtxt 	.ptext "0.2"
biatxt 	.ptext "1.3"

alltxt	.text "All",0

;deftxt	.text c_white," Default",0
;forcetxt
;		.text c_white,"Force old",0
		
top1 	.text c_clear,c_white,176
		.fill 37,96
		.text 174,13,125,"        ",c_lt_green,"C64 Video Enhancement       ",c_white," ",125,13,173
		.fill 37,96
		.text 189,13,0
		
Title1	.text c_lt_green,"       Palette adjustment utility",13,13
		.text c_yellow,"      Hardware and firmware design",13
		.text "          *2019*  c0pperdragon",13
		.text c_grey2,"        github.com/c0pperdragon",13,13
		.text c_yellow,"           COLODORE algorithm",13
		.text "              *2017* pepto",13,0
Title2	.text c_grey2,"    www.pepto.de/projects/colorvic/",13,13
		.text c_yellow,"             Utility coding",13
		.text "           *2019*  Hojo Norem",13
		.text c_grey2,"         github.com/Hojo-Norem",13,0
Title3	.text c_black,"           john moore",13,13,13	
		.text c_white," PLEASE TOGGLE YOUR OUTPUT MODE SWITCH",13
		.text "  AND THEN PRESS  ANY KEY TO CONTINUE",0


lumamodenew
		.text c_grey3,"     ",c_red,"L",c_grey3,"uma mixing table:  ",c_lt_green,"New",c_white," lumas",0
lumamodemix
		.text c_grey3,"     ",c_red,"L",c_grey3,"uma mixing table:  ",c_lt_green,"Old",c_white," lumas",0
		
YPbPr	.text c_orange,"V",c_grey3,"ideo output mode:  ",c_lt_green,"Y",c_lt_blue,"Pb",c_red,"Pr",0
RGsB	.text c_orange,"V",c_grey3,"ideo output mode:  ",c_red,"R",c_lt_green,"G",c_white,"s",c_lt_blue,"B",0
;YPbPr	.text c_red,"V",c_grey3,"ideo output mode:  ",c_lt_green,"Y",c_lt_blue,"Pb",c_red,"Pr",0
;RGsB	.text c_red,"V",c_grey3,"ideo output mode:  ",c_red,"R",c_lt_green,"G",c_white,"s",c_lt_blue,"B",0		    

locktxt	.text c_white,"Your palette is now stored. Press any",13
		.text "key to return to the editor or power-",13
		.text "cycle your C64 to re-lock the palette.",13,0  
		
devtxt	.text c_grey3,"Please Select ",c_red,"t",c_grey3,"ape, ",c_red,"d",c_grey3,"isk or ",c_red,"c",c_grey3,"ancel.",13,13,0
			;  0123456789012345678901234567890123456789
dmatxt	.text c_grey3,"You can use a cartridge with DMA load",13
		.text "ability here.",13,13,0; Use DMA to load a palette and",13
		;.text "then select any option to return.",13,13,0
devnot	.text c_grey3,"Which drive? (",c_red,"8",c_grey3,",",c_red,"9",c_grey3,",1",c_red,"0",c_grey3,",1",c_red,"1",c_grey3,")",13,13,0
FNtxt	.text c_grey3,"Enter Filename: ",c_white,0
DErtxt	.text c_white,"Disk Error!!",0
DLoad	.text 13,c_grey3,"Loading...",13,13,0
DSave	.text 13,c_grey3,"Saving...",13,13,0
			
Tapetxt .text 13,c_grey3,"Please wind cassette to required",13
		.text "position and then press any key to",13
		.text "continue.",13,13,0
nofiles .text c_grey3,"No palette files found.",13,13,0
found1	.text c_grey3,"Found ",0
found2	.text "palette files.",13,13,0

paktxt	.text c_grey3,"Press any key to return.",13,0

.align $2000,00
bitmap
		.binary test_image,2,$1f3f
		


ChLuma1	.text 13,c_grey3,"Press a key for ",c_red,"N",c_grey3,"ew or ",c_red,"O",c_grey3,"ld luma groups.",13
		.text "Groupings determine luma distribution",13
		.text "and colour mixing ability.",13,13,13
	
		.text c_white,"   NEW LUMAS:",13,c_blue,0
ChLuma2	.text "      ",c_revs_on,172,162,187,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",c_revs_on,188,c_revs_off,162,c_revs_on,190,c_revs_on,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,13,13,0

ChLuma3	.text 13,c_white,"   OLD LUMAS:",13,c_blue
		.text "      ",c_revs_on,172,162,187,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",c_revs_on,188,c_revs_off,162,c_revs_on,190,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,13,0

MPal1	.text c_white,c_revs_on,172,162,162,187,c_revs_off," ",c_revs_on,"    ",c_revs_off," ",c_red,c_revs_on,"    ",c_revs_off," ",c_cyan,c_revs_on,"    ",c_revs_off," ",c_purple,c_revs_on,"    ",c_revs_off," ",c_green,c_revs_on,"    ",c_revs_off," ",c_blue,c_revs_on,"    ",c_revs_off," ",c_yellow,c_revs_on,"    ",c_revs_off,13
		.text c_white,161,"00",c_revs_on,161,c_revs_off," ",c_revs_on," 01 ",c_revs_off," ",c_red,c_revs_on," 02 ",c_revs_off," ",c_cyan,c_revs_on," 03 ",c_revs_off," ",c_purple,c_revs_on," 04 ",c_revs_off," ",c_green,c_revs_on," 05 ",c_revs_off," ",c_blue,c_revs_on," 06 ",c_revs_off," ",c_yellow,c_revs_on," 07 ",c_revs_off,13,0
MPal2	.text c_white,c_revs_on,188,c_revs_off,162,162,c_revs_on,190,c_revs_off," ",c_revs_on,"    ",c_revs_off," ",c_red,c_revs_on,"    ",c_revs_off," ",c_cyan,c_revs_on,"    ",c_revs_off," ",c_purple,c_revs_on,"    ",c_revs_off," ",c_green,c_revs_on,"    ",c_revs_off," ",c_blue,c_revs_on,"    ",c_revs_off," ",c_yellow,c_revs_on,"    ",c_revs_off,13,13

		.text c_orange,c_revs_on,"    ",c_revs_off," ",c_brown,c_revs_on,"    ",c_revs_off," ",c_lt_red,c_revs_on,"    ",c_revs_off," ",c_grey1,c_revs_on,"    ",c_revs_off," ",c_grey2,c_revs_on,"    ",c_revs_off," ",c_lt_green,c_revs_on,"    ",c_revs_off," ",c_lt_blue,c_revs_on,"    ",c_revs_off," ",c_grey3,c_revs_on,"    ",c_revs_off,13,0
MPal3	.text c_orange,c_revs_on," 08 ",c_revs_off," ",c_brown,c_revs_on," 09 ",c_revs_off," ",c_lt_red,c_revs_on," 10 ",c_revs_off," ",c_grey1,c_revs_on," 11 ",c_revs_off," ",c_grey2,c_revs_on," 12 ",c_revs_off," ",c_lt_green,c_revs_on," 13 ",c_revs_off," ",c_lt_blue,c_revs_on," 14 ",c_revs_off," ",c_grey3,c_revs_on," 15 ",c_revs_off,13
		.text c_orange,c_revs_on,"    ",c_revs_off," ",c_brown,c_revs_on,"    ",c_revs_off," ",c_lt_red,c_revs_on,"    ",c_revs_off," ",c_grey1,c_revs_on,"    ",c_revs_off," ",c_grey2,c_revs_on,"    ",c_revs_off," ",c_lt_green,c_revs_on,"    ",c_revs_off," ",c_lt_blue,c_revs_on,"    ",c_revs_off," ",c_grey3,c_revs_on,"    ",c_revs_off,13,13,0		

PreClk	.text c_grey2," Pre-calculating and applying defaults",13,c_up,0

maincon	.text "   ",c_red,"B",c_grey3,"rightness   ",c_red,"C",c_grey3,"ontrast   ",c_red,"S",c_grey3,"aturation ",13,13
		;.text c_white,"       50          100         50",13,13
		.text 13,13
		.text "      ",c_red,"H",c_grey3,"ue origin   S",c_red,"e",c_grey3,"lected colour",13,13
		;.text c_white,"         11.25           All",13,0
		.text 13,0
maincon2
		.text 13,13,13,13,13
		.text "  Palette: ",c_red,"T",c_grey3,"est - S",c_red,"a",c_grey3,"ve - L",c_red,"o",c_grey3,"ad - ",c_red,"F",c_grey3,"lash",13,13,0
		;.text "Palette:  ",c_red,"T",c_grey3,"est - ",c_red,"U",c_grey3,"pload",13,13,13,0
footer	.text c_grey3," "
		.fill 37,96
		.text 13,c_grey3,"     Highlighted character selects.",13,13,"         Use ",c_red,"+",c_grey3," and ",c_red,"-",c_grey3," to adjust.",0


		
ScalePb .ptext "0.872021"
FPScalePb
		.fill 5
ScalePr .ptext "1.229951"
FPScalePr
		.fill 5
FP127	.fill 5


.align $100,00	
	;precalculated Y (luma) table
	; new lumas
Lumas	.byte 0,255,79,159,95,127,63,191,95,63,127,79,119,191,119,159
	; old lumas
		.byte 0,255,63,191,127,127,63,191,127,63,127,63,127,191,127,191
	; tweaked lumas
		.byte 0,255,79,159,95,127,63,191,95,63,127,79,127,191,127,159

Angles	.byte 0,0,4,12,2,10,15,7,5,6,4,0,0,10,15,0

X5Tab	.byte 0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100
X16Tab	.byte 0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240

ConLUT	.byte >ConLut00,>ConLut01,>ConLut02,>ConLut03,>ConLut04,>ConLut05,>ConLut06,>ConLut07,>ConLut08,>ConLut09
		.byte >ConLut10,>ConLut11,>ConLut12,>ConLut13,>ConLut14,>ConLut15,>ConLut16,>ConLut17,>ConLut18,>ConLut19
		.byte >ConLut20,>ConLut21,>ConLut22,>ConLut23,>ConLut24,>ConLut25,>ConLut26,>ConLut27,>ConLut28,>ConLut29
		.byte >ConLut30,>ConLut31
	
PalRed		.byte 30,44	;11, 30, 0        
PalLtGrn	.byte 64,44	;11, 0, 2      01000000   00101100
PalGrey3	.byte 239,105
PalGrey1	.byte 239,%00011101
PalWhite	.byte 239,125
PalltBlue		.byte 224,47	;11, 0, 30     11100000   00101111 
PalFlash	.byte 30,44,0,0
charcol
		.binary test_image,$1f42
.align $100

ConLut00 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
ConLut01 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
ConLut02 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5
ConLut03 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
ConLut04 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10
ConLut05 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12
ConLut06 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15
ConLut07 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,17,17,17,17
ConLut08 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,19,19,19,20,20,20,20,20,20
ConLut09 .byte 0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,22,22,22
ConLut10 .byte 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,24,25,25,25,25,25,25
ConLut11 .byte 0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,25,25,25,25,25,25,25,25,25,26,26,26,26,26,26,26,26,26,27,27,27,27,27,27,27,27,27,28
ConLut12 .byte 0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,25,25,25,25,25,25,25,25,26,26,26,26,26,26,26,26,27,27,27,27,27,27,27,27,27,28,28,28,28,28,28,28,28,29,29,29,29,29,29,29,29,30,30,30,30,30,30
ConLut13 .byte 0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,25,25,25,25,25,25,25,26,26,26,26,26,26,26,26,27,27,27,27,27,27,27,27,28,28,28,28,28,28,28,28,29,29,29,29,29,29,29,30,30,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut14 .byte 0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,9,9,9,9,9,9,9,10,10,10,10,10,10,10,11,11,11,11,11,11,11,12,12,12,12,12,12,12,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,16,16,16,16,16,16,16,17,17,17,17,17,17,17,18,18,18,18,18,18,18,19,19,19,19,19,19,19,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,23,23,23,23,23,23,23,24,24,24,24,24,24,24,25,25,25,25,25,25,25,26,26,26,26,26,26,26,27,27,27,27,27,27,27,28,28,28,28,28,28,28,28,29,29,29,29,29,29,29,30,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut15 .byte 0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,6,6,7,7,7,7,7,7,7,8,8,8,8,8,8,9,9,9,9,9,9,9,10,10,10,10,10,10,10,11,11,11,11,11,11,12,12,12,12,12,12,12,13,13,13,13,13,13,13,14,14,14,14,14,14,15,15,15,15,15,15,15,16,16,16,16,16,16,16,17,17,17,17,17,17,18,18,18,18,18,18,18,19,19,19,19,19,19,19,20,20,20,20,20,20,21,21,21,21,21,21,21,22,22,22,22,22,22,22,23,23,23,23,23,23,24,24,24,24,24,24,24,25,25,25,25,25,25,25,26,26,26,26,26,26,27,27,27,27,27,27,27,28,28,28,28,28,28,28,29,29,29,29,29,29,30,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut16 .byte 0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8,8,8,9,9,9,9,9,9,10,10,10,10,10,10,11,11,11,11,11,11,12,12,12,12,12,12,12,13,13,13,13,13,13,14,14,14,14,14,14,15,15,15,15,15,15,16,16,16,16,16,16,16,17,17,17,17,17,17,18,18,18,18,18,18,19,19,19,19,19,19,20,20,20,20,20,20,20,21,21,21,21,21,21,22,22,22,22,22,22,23,23,23,23,23,23,24,24,24,24,24,24,24,25,25,25,25,25,25,26,26,26,26,26,26,27,27,27,27,27,27,28,28,28,28,28,28,28,29,29,29,29,29,29,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut17 .byte 0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8,9,9,9,9,9,9,10,10,10,10,10,10,11,11,11,11,11,11,12,12,12,12,12,12,13,13,13,13,13,13,14,14,14,14,14,14,15,15,15,15,15,15,16,16,16,16,16,17,17,17,17,17,17,18,18,18,18,18,18,19,19,19,19,19,19,20,20,20,20,20,20,21,21,21,21,21,21,22,22,22,22,22,22,23,23,23,23,23,23,24,24,24,24,24,24,25,25,25,25,25,26,26,26,26,26,26,27,27,27,27,27,27,28,28,28,28,28,28,29,29,29,29,29,29,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut18 .byte 0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8,9,9,9,9,9,9,10,10,10,10,10,10,11,11,11,11,11,12,12,12,12,12,12,13,13,13,13,13,14,14,14,14,14,14,15,15,15,15,15,16,16,16,16,16,16,17,17,17,17,17,18,18,18,18,18,18,19,19,19,19,19,19,20,20,20,20,20,21,21,21,21,21,21,22,22,22,22,22,23,23,23,23,23,23,24,24,24,24,24,25,25,25,25,25,25,26,26,26,26,26,27,27,27,27,27,27,28,28,28,28,28,28,29,29,29,29,29,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut19 .byte 0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8,9,9,9,9,9,10,10,10,10,10,11,11,11,11,11,11,12,12,12,12,12,13,13,13,13,13,14,14,14,14,14,15,15,15,15,15,15,16,16,16,16,16,17,17,17,17,17,18,18,18,18,18,19,19,19,19,19,19,20,20,20,20,20,21,21,21,21,21,22,22,22,22,22,22,23,23,23,23,23,24,24,24,24,24,25,25,25,25,25,26,26,26,26,26,26,27,27,27,27,27,28,28,28,28,28,29,29,29,29,29,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut20 .byte 0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7,8,8,8,8,8,9,9,9,9,9,10,10,10,10,10,11,11,11,11,11,12,12,12,12,12,13,13,13,13,13,14,14,14,14,14,15,15,15,15,15,16,16,16,16,16,17,17,17,17,17,18,18,18,18,18,19,19,19,19,19,20,20,20,20,20,21,21,21,21,21,22,22,22,22,22,23,23,23,23,23,24,24,24,24,24,25,25,25,25,25,26,26,26,26,26,27,27,27,27,27,28,28,28,28,28,29,29,29,29,29,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut21 .byte 0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7,8,8,8,8,9,9,9,9,9,10,10,10,10,10,11,11,11,11,11,12,12,12,12,13,13,13,13,13,14,14,14,14,14,15,15,15,15,15,16,16,16,16,17,17,17,17,17,18,18,18,18,18,19,19,19,19,19,20,20,20,20,21,21,21,21,21,22,22,22,22,22,23,23,23,23,23,24,24,24,24,24,25,25,25,25,26,26,26,26,26,27,27,27,27,27,28,28,28,28,28,29,29,29,29,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut22 .byte 0,0,0,0,0,1,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,5,5,5,5,5,6,6,6,6,7,7,7,7,7,8,8,8,8,9,9,9,9,9,10,10,10,10,11,11,11,11,11,12,12,12,12,12,13,13,13,13,14,14,14,14,14,15,15,15,15,16,16,16,16,16,17,17,17,17,18,18,18,18,18,19,19,19,19,20,20,20,20,20,21,21,21,21,22,22,22,22,22,23,23,23,23,23,24,24,24,24,25,25,25,25,25,26,26,26,26,27,27,27,27,27,28,28,28,28,29,29,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut23 .byte 0,0,0,0,0,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,11,12,12,12,12,13,13,13,13,14,14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,20,20,21,21,21,21,22,22,22,22,23,23,23,23,23,24,24,24,24,25,25,25,25,25,26,26,26,26,27,27,27,27,28,28,28,28,28,29,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut24 .byte 0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,12,12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,18,18,18,18,18,19,19,19,19,20,20,20,20,21,21,21,21,22,22,22,22,23,23,23,23,24,24,24,24,24,25,25,25,25,26,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,30,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut25 .byte 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,20,21,21,21,21,22,22,22,22,23,23,23,23,24,24,24,24,25,25,25,25,26,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut26 .byte 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,18,18,18,18,19,19,19,20,20,20,20,21,21,21,21,22,22,22,22,23,23,23,23,24,24,24,24,25,25,25,26,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut27 .byte 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,4,4,4,4,5,5,5,5,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,11,11,11,11,12,12,12,12,13,13,13,14,14,14,14,15,15,15,15,16,16,16,17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,21,21,21,21,22,22,22,22,23,23,23,24,24,24,24,25,25,25,25,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut28 .byte 0,0,0,0,1,1,1,1,2,2,2,3,3,3,3,4,4,4,5,5,5,5,6,6,6,7,7,7,7,8,8,8,8,9,9,9,10,10,10,10,11,11,11,12,12,12,12,13,13,13,14,14,14,14,15,15,15,15,16,16,16,17,17,17,17,18,18,18,19,19,19,19,20,20,20,21,21,21,21,22,22,22,22,23,23,23,24,24,24,24,25,25,25,26,26,26,26,27,27,27,28,28,28,28,29,29,29,29,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut29 .byte 0,0,0,0,1,1,1,2,2,2,2,3,3,3,4,4,4,4,5,5,5,6,6,6,6,7,7,7,8,8,8,8,9,9,9,10,10,10,11,11,11,11,12,12,12,13,13,13,13,14,14,14,15,15,15,15,16,16,16,17,17,17,17,18,18,18,19,19,19,20,20,20,20,21,21,21,22,22,22,22,23,23,23,24,24,24,24,25,25,25,26,26,26,26,27,27,27,28,28,28,29,29,29,29,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut30 .byte 0,0,0,0,1,1,1,2,2,2,3,3,3,3,4,4,4,5,5,5,6,6,6,6,7,7,7,8,8,8,9,9,9,9,10,10,10,11,11,11,12,12,12,12,13,13,13,14,14,14,15,15,15,15,16,16,16,17,17,17,18,18,18,18,19,19,19,20,20,20,21,21,21,21,22,22,22,23,23,23,24,24,24,24,25,25,25,26,26,26,27,27,27,27,28,28,28,29,29,29,30,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
ConLut31 .byte 0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,5,5,5,6,6,6,7,7,7,8,8,8,8,9,9,9,10,10,10,11,11,11,12,12,12,13,13,13,13,14,14,14,15,15,15,16,16,16,17,17,17,17,18,18,18,19,19,19,20,20,20,21,21,21,22,22,22,22,23,23,23,24,24,24,25,25,25,26,26,26,26,27,27,27,28,28,28,29,29,29,30,30,30,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31

NewMix 	.byte 2,11,3,15,4,8,5,10,6,9,7,13,8,4,9,6,10,5,11,2,12,14,13,7,14,12,15,3,0,0
OldMix	.byte 2,6,2,9,2,11,3,7,3,13,3,15,4,5,4,8,4,10,4,12,4,14,5,4,5,8,5,10,5,12,5,14,6,2,6,9,6,11,7,3,7,13
		.byte 7,15,8,4,8,5,8,10,8,12,8,14,9,2,9,6,9,11,10,4,10,5,10,8,10,12,10,14,11,2,11,6,11,9,12,4,12,5,12
		.byte 8,12,10,12,14,13,3,13,7,13,15,14,4,14,5,14,8,14,10,14,12,15,3,15,7,15,13,0,0

errno	.byte 0
		

		
ErrDRV	.text 13,13,c_white,"Device ",0		
ErrDNP	.text ": Drive not present!",13,13,0
ErrFNF	.text ": File not found!",13,13,0
ErrLE	.text ": Load error!",13,13,0
ErrBrk	.text ": RUN/STOP!",13,13,0
ErrDef	.text ": Error number ",0

FPM128	.fill 5,0

.align $100,$64
		.byte 64	;Offset uploader binary due to BASIC load addr being $0801 and not $0800 ^_^
uploader
		.binary "uploader.prg",2
uploader_end
		
.align $100,0
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

OutputMode
		.fill 1
Mix_Luma
		.fill 1
Active_Luma
		.fill 1
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
endoftheshow
		.fill uploader_end-uploader
.align $100
Load_Block0
			.fill 17*5
			.fill 17
			.fill 17
			.fill 17

.align $100
Load_Block1	.fill 16*5
			.fill 16
			.fill 16
			.fill 5
			.fill 5
			.fill 5
			.fill 5
			.fill 5
			.fill 5
			.fill 5
			.fill 5
			.fill 1
			.fill 1
			.fill 1
.align $100
Load_Block2	.fill 16*5
.align $100
Load_Block3	.fill 16*5
.align $100
Load_Block4	.fill 16*5

;*********************
;   Helper Mactros
;*********************
VICIRQEN .macro
		lda #1
		sta $d01a
		.endm
		
VICIRQDIS .macro
		lda #0
		sta $d01a
		.endm
	
printnat .macro number,xcord,ycord
		ldx \ycord
		ldy \xcord
		jsr $e50c
		ldx \number
		jsr s_printnat
		.endm
		
printtat .macro address,xcord,ycord
		ldx \ycord
		ldy \xcord
		jsr $e50c
		ldx #<\address
		ldy #>\address
		jsr sprint
		lda #32
		jsr $ffd2
		.endm
		
printfat .macro xcord,ycord
		ldx \ycord
		ldy \xcord
		jsr $e50c
		#printfac
		lda #32
		jsr $ffd2
		.endm

printn .macro number

		ldx \number
		jsr s_printn
		.endm	
	
prints	.macro address
		ldx #<\address
		ldy #>\address
		jsr sprint
		.endm
		
SCRON	.macro
		jsr jSCRON
		.endm
		
SCROFF  .macro
		jsr jSCROFF
		.endm

FACADDM	.macro address
		lda #<\address
		ldy #>\address
		jsr fadd
		.endm

FACSUBM	.macro address
		lda #<\address
		ldy #>\address
		jsr fsub
		.endm


FACDIVM .macro address
		lda #<\address
		ldy #>\address
		jsr fdiv
		.endm
		
FACMULM .macro address
		lda #<\address
		ldy #>\address
		jsr fmult
		.endm
		
LDFACB	.macro number
		ldy #\number
		lda #0
		jsr givayf
		.endm

LDFACW .macro number
		ldy #<\number
		lda #>\number
		jsr givayf
		.endm
		
		
LDFACM .macro address
		lda #<\address
		ldy #>\address
		jsr movfm
		.endm
		
LDARG .macro address
		lda #<\address
		ldy #>\address
		jsr conupk
		.endm
		
STFACM	.macro address
		ldx #<\address
		ldy #>\address
		jsr movmf
		.endm
		
TXFA	.macro
		jsr movfa
		.endm

TXAF	.macro
		jsr movef
		.endm
		
LDFACT	.macro address
		lda \address
		ldx #<\address+1
		ldy #>\address+1
		stx $22
		sty $23
		jsr strval
		.endm
LDFACBM	.macro address
		ldy \address
		lda #0
		jsr givayf
		.endm		
		
PRINTFAC .macro
		jsr $bddd
		tax
		jsr sprint		
		.endm
