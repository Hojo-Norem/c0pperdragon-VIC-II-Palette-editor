.comment
		******************************************************************
		******************************************************************
		*******                                                  *********
		*******             C64 Video  Enhancement               *********
		*******                      v1.16                       *********
		*******                 Palette Editor                   *********
		*******                                                  *********
		******************************************************************
		******************************************************************
		
						          By Hojo Norem
		
		 For use with with c0pperdragon's Video Enhancement PCB
		 github.com/c0pperdragon
		
		 Assembler used - 64tass
		
		 Palette generator based on the 'colodore' algorithm by pepto
		 www.pepto.de/projects/colorvic/
		
		 What's done:	
						(2019/08/07 - Initial version)
						Default palette generation based on colodore algorithm.
						Ability to alter brightness, contrast hue and saturation on a global or per colour basis.
						ability to choose between First revision VIC-II lumas (old) and everything else (new).
						PAL colourmixing calculation...  an approximation but works somewhat.
						ability to apply old VIC-II lumas to colourmix calculations for new lumas.  Per colour luma channel is averaged without bias. 
						Upload to device flash.
						Built in test image:
											This is just a Koala format bitmap.  I would appreciate something a little better, even if it's only a nice border...
											
						(2019/12/01 - v0.9)
						New test image.  At least it has some meaning now...
						Pepto contacted me a while ago and recommended that I should be scaling the UV output to better match PbPr output:
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
						
						(2020/02/16 - v1.00)					
						Implemented RGsB mode:
									When a palette is loaded stand-alone the option's state is displayed on screen.
									This required an implementation of a component>RGB conversion alorithm: 
							        
										R = Y + (1.402 * Pr)
										G = (Y - (0.344 * Pb)) - (0.714 * Pr)
										B = Y + (1.772 * Pb)
									
									I don't know enough to be certain, but I think that the generated YUV values are already PAL gamma corrected (going my my fairly uninformed
									assumption on reading the colodore source).  Under this assumption, I am skipping the rather costly (from a 6502 point of view.  I could be completely wrong)
									maths needed to do the PAL->sRGB gamma correction shown in the colodore source.  If I am wrong then it should be possible to compensate by simply
									adjusting the brightness and contrast from the editor.
									
									I have no means to actually test RGsB output.  Please report back with your results.
						
						Improved colourmixing:
								Instead of the simple and inaccurate UV biasing to generate the odd /even even / odd mixing variants there is a new routine based on the hanover bar generation
								taken from the colodore.com JS sourcecode (go to colodore.com and view page source in your browser).  Three sets of UV coordinates are generated for each colour:- 'normal',
								odd line hanover bars and even line hanover bars.  At the moment hanover bars are only used for mixed colours, as the bars are responsible for the differing resulting
								colours depending on which colour starts on the odd scanline.  The output seem to be close to colodore's, which is close to what I see on my C64 through s-video.  A couple 
								of the mixes are a little off, but the algorithm should be tweakable enough if any info on the subject comes to light.
							
						Added firmware default pre-generated palette as defined in c0pperdragon's sourcecode and a pre-calculated RGsB version.  These palettes are fixed and uneditable.
						Some code optimizations.  Editor is now more responsive.
						Split the sourcecode into modules.  Now the insanity is in byte-sized chunks.
						
						(2020/02/16 - v1.01 & v1.1)
						YUV needs to be scaled to YPbPr for accurate results: 
								Problem was that for the mixed colours this scaling was being applied before they were being mixed.
								This version fixes that and improves the accuracy of the resulting mixed colours.
						Added RGBns (no sync) videomode.  In this mode the FPGA will not output sync on Y/green and will have to be sourced from the VIC-II's luma.
						
						(2020/02/19 - v1.15)
						Setting a default palette also sets the corresponding video mode if the palette editor is chosen afterward.
						Added RGB GUI palette.  Switched in appropriately on video mode change.
						I broke the colour mixing routine in the previous version.  Fixed.
						
						(2020/04/12 - v1.16)
						Small fix / tweak to the colourmix calculations.  Some improvements to accuracy.
						It is worth noting that the default palette settings are not perfect by far.  After using them for a while I found that boosting the brightness on Yellow and Lt.Green a visible notch, shifting the
						hue of yellow and brown a notch and taking brown's saturation down a notch not only made for a more faithful colour reproduction to my eyes (done by quickly flicking between component and
						S-Video using a Extron DVS 204) but coupled with the above tweaks to the mixing algo the resulting colourmixes seem more faithful.  An example of such a palette will be included with the sources
						and binary releases.
						
						(2020/04/15 - v1.17)
						Re-worked the firmware default palette section.  Now colour mixing is now applied to the firmware default palette.
						Added a built-in instruction manual of a sort.  As user controls are already clearly marked on screen, this manual more explains the quirks of the editor and the FPGA mod in general.
						Dropped pucrunch from the main build.  Unless you want to load the editor from tape or disk without a fastloader then there isn't really a need for it in 2020... 
						
						(2020/06/14 - v1.18)
						Hopefully fixed a bug for NTSC users where one could not proceed past the luma selection screen.  I don't have a NTSC machine, so I had to do my testing in VICE.
						Partly for my own amusement and partly to lay the foundation for a more fateful representation of 8595 VIC-II delay line mixing, there is now a 'Mix them ALL!' luma mixing mode.
						
		 Some info:
						The mod uses 16 bit entries for its palette.  The editor stores them as separate low/high byte arrays.
							
		 Colour calculation arrays (located at end of code):

							MainPalL	.fill 16	|Temporary palette storage used while palette editor is active
							MainPalH	.fill 16	|
							
							Origin 		.fill 5		FP - Hue origin of currently selected colour
							Sector		.fill 5		FP - The hue colour wheel is split into 16 'sectors' (360/16).
							radian		.fill 5		FP - A radian.  The C64 ROMs probably have routines to calculate this.  I'm lazy and did it in VB and stored the result as a text string.  It gets read by a ROM routine into this variable.
							screen		.fill 5		FP - The 'screen' variable in the colodore algo.  I won't pretend to understand what it there for.  The original algo defines it as 1/5.  Like the radian, I just store it as text '0.2'.
							bias		.fill 5		FP - Read in from text.  Used to calculate the biased positions of colours for use in odd/even colour mixing. 
		
							Fcontra		.fill 5		FP - Contrast setting of currently selected colour.
							Fsatura		.fill 5		FP - Saturation setting for the same.

							FPtemp1		.fill 5		FP - Temporary variable used during many floating point operations
							
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
		
.include "varconst.asm"

		
		;Image in koala format for use with the '
		;test_image="orbital impaler.kla"
		test_image="testimage2.kla"

*       = $0801
        .word (+), 2005  ;pointer, line number
        .null $9e, format("%d", PalEdit)
+		.word 0          ;basic line end		
		
PalEdit #scroff
		jsr initmultables	;initialise the tables for the fast FP multiplication routines
		jsr hanpre
		lda #0
	    sta 53280
		sta 53281
		sta PreCalced
		sta outputmode
    lda #$40      ; Reset BeamRacer so that it drops off the bus and makes
    sta $d02e     ; VideoMod registers accessible. Harmless if BeamRacer not present
		lda #23
		sta fullcalculation
		sta 53272
		lda #20
		sta boost
		;the RUN command turns off KERNAL error and control messages
		;we want them back on for the load/save routines.  This lets the load routine
		;display the name of the first file found on tape (like the LOAD command from
		; the BASIC prompt).  You can hit RUN/STOP to cancel the load.
		lda #$c0
		sta $9D
		lda #sprite_x
		sta spr0x
		lda #sprite_y
		sta spr0y
		lda #1
		sta spr0c
		lda #sprff
		sta spr0p
		lda lumas+15
		sta temp2
		lda #128
		sta temp3
		sta temp4
		jsr preshift
;		lda colreghigh
		sta palgrey3+1	
		lda colreglow
		sta palgrey3	
		jsr printtop
		#prints title1
		#prints title2
		#prints title3
		#scron
		lda #unlock
		sta control	
		jsr waitkey
		jsr waitrel
		#scroff
		jmp mainmenu	
enteredit
		#scroff	
		ldx #15
-		lda lumas,x
		sta temp2
		ldy outputmode
		bne +
		lda #16
+		asl
		asl
		asl
		sta temp3
		sta temp4		
		jsr preshift
;		lda colreghigh
		sta mainpalh,x
		lda colreglow
		sta mainpall,x
		dex
		bpl -	
		jsr printtop
		#prints chluma1
		#prints chluma2
		#prints chluma3
		jsr changeGUIPal
		lda #1
		sta full_upload
		lda #150
wait 	cmp $d012
		bne wait
		lda #106
		sta irq1raster+1
		lda #245
		sta irq2raster+1
		jsr irqinit
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
		lda #c_clear
		jsr $ffd2
		#prints mpal1
		#prints mpal2
		#prints mpal3
		#scron
		lda PreCalced
		bne SkipCalc
		#prints preclk		
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
		jsr drawwhite
		jmp menuloop
				
		
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
		jsr update
		jmp drawval
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
		jsr update
		jmp drawval
+		jmp menuloop

	
doorigin_p
		#ldfacb 1
		#facaddm origin
		#stfacm origin
		jmp update_origin

		
menuloop
		ldy #0
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
		cmp #key_v
		beq togglevid
		jmp menuloop

		
savecols
		jmp saveram

		
loadcol
		jmp loadram
		
jchangemix
		jsr changemix
		jmp menuloop
		
		
jshowtest
		jsr showtest
		jmp mainscr
		
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
		jsr drawwhite
		jmp drawval


togglevid
		jsr waitrel
		ldx outputmode
		dex
		bpl +
		ldx #2
+		stx outputmode
		jsr changeGUIPal
		jsr dispvid
		lda currcol
		sta oldselcol
		lda #16
		sta currcol
		jsr recalc
		lda oldselcol
		sta currcol
		lda #17
		sta fullcalculation
		jmp menuloop

		
update_origin
		ldx currcol
		cpx #16
		bne onlyoneo
		ldx #15
-		jsr dotrig
		dex
		bpl -
		ldy selparam
		jsr update
		jmp drawval
onlyoneo
		jsr dotrig
		jsr update
		jmp drawval	

		
cpyparams
		
		ldy #16
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
		dey
		bpl -
		ldy currcol
		rts
		
		
changemix
		jsr waitrel
		lda active_luma
		bne oldonly
		lda mix_luma
		bpl +
		lda #0
		jmp +++
+		beq +
		lda #255
		jmp ++
+		lda #16
+		sta mix_luma
		jsr dispmix
		lda fullcalculation
		bne oldonly
		lda #17
		sta fullcalculation
oldonly	rts
				

.align 256,255
sprites
		.binary "rotate.spr",2

dispvid
		ldx outputmode
		beq dcomp
		dex
		beq drgsb
		#printtat rgbns,#7,#readouty+6
		rts	
dcomp	#printtat ypbpr,#7,#readouty+6
		rts
drgsb	#printtat rgsb,#7,#readouty+6
		rts			

		
paramkey_h
		iny
paramkey_s
		iny
paramkey_c
		iny
paramkey_b
		iny
		sty selparam
		jsr waitrel
		jsr drawwhite
drawval	ldx #3
		stx 646
		;jsr debugcols	;****************************colour register ouptut debug
		lda selparam
		bne notSel
		jmp menuloop
notSel
		cmp #1
		bne notBright
		#printnat bbright, #brix, #readouty
		jmp menuloop
notBright
		cmp #2
		bne notCont
		#printnat bcontra, #conx, #readouty
		jmp menuloop
notCont
		cmp #3
		bne notSat
		#printnat bsatura, #satx, #readouty
		jmp menuloop
notsat
		#ldfacm origin
		#printfat #originx, #readouty+4
		jmp menuloop
		
		
drawwhite
		ldx #1
		stx 646
		#printnat bbright, #brix, #readouty
		#printnat bcontra, #conx, #readouty
		#printnat bsatura, #satx, #readouty
		#ldfacm origin
		#printfat #originx, #readouty+4
		rts
		

dispmix
		lda active_luma
		bne dontprintforold
		lda mix_luma
		bne +
		#printtat lumamodenew,#0,#readouty+8
		jmp dontprintforold
+		bmi +
		#printtat lumamodemix,#0,#readouty+8
		jmp dontprintforold
+		#printtat lumamodeall,#0,#readouty+8
dontprintforold
		rts

	
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
		jsr waitrel
		lda #255
		sta full_upload
		lda #c_clear
		jsr $ffd2
		jsr fullsave
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
		bne recalc
		jsr norm_sat
recalc	ldx currcol
		cpx #16
		bne onlyone
		ldx #15		
-		jsr calccol
		jsr normoutput
		lda outputmode
		beq +
		jsr doRGBconv
+		jsr preshift
		jsr setsync
;		lda colreghigh
		sta mainpalh,x
		lda colreglow
		sta mainpall,x
		dex
		bpl -
		lda #1
		sta full_upload
		rts
onlyone
		jsr calccol
		jsr normoutput
		lda outputmode
		beq +
		jsr doRGBconv
+		jsr preshift		;we dont setsync here because colour 0 will never be altered on its own
;		lda colreghigh
		sta mainpalh,x
		lda colreglow
		sta mainpall,x

		lda #1
		sta full_upload
		rts

		
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

		
mainmenu
		jsr printtop
		jsr printpal
		#prints menu
		#scron
mainmenuloop		
		lda 197
		cmp #key_none
		beq mainmenuloop
		cmp #key_c
		beq jenteredit
		cmp #key_d
		beq dodefpal
		cmp #key_i
		beq jshowmanual
		jmp mainmenuloop
jenteredit
		jmp enteredit
jshowmanual
		jsr showmanual
		#scroff
		jmp mainmenu
dodefpal
		jsr dodefaults

		#scron
		#prints stf
		jsr waitrel
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
		
pno		#scroff
		jmp mainmenu
			
		
freezed jmp freezed

chooseluma
		pha
wrong1	jsr waitkey
		cmp #39			; key N
		beq wright1
		cmp #38			; key O
		beq wright2
		jmp wrong1
wright1	lda #New_Lumas
		jmp onwards
wright2	lda #Old_Lumas
		jmp onwards
onwards	sta Active_Luma
		sta Mix_Luma
		pla
		rts

.include "precalc.asm"

;.include "colcalc-bias.asm"
;.include "colcalc-hanover.asm"
.include "colcalc.asm"

.include "modapi.asm"
.include "coltrig.asm"
.include "irqhandler.asm"
.include "storageio.asm"
.include "kbio.asm"
.include "screen.asm"
.include "maths.asm"

;*****************
;Test image bitmap
;*****************

.align $2000,255
bitmap
		.binary test_image,2,$1f3f
charcol
		.binary test_image,$1f42		
.include "tables.asm"
.include "text.asm"		

showmanual
		#scroff
		jsr printtop
		#prints manual1
		#prints manual2
		#prints manual3
		
		#prints paktc
		#scron
		jsr waitkey
		jsr waitrel
		#scroff
		jsr printtop
		#prints manual4
		#prints manual5
		#prints manual6
		#prints manual7
		#prints paktc
		#scron
		jsr waitkey
		jsr waitrel
		#scroff
		jsr printtop
		#prints manual8
		#prints manual9
		#prints manualA
		#prints paktc
		#scron
		jsr waitkey
		jsr waitrel
		#scroff
		jsr printtop
		#prints manualB
		#prints manualC
		#prints paktc
		#scron
		jsr waitkey
		jsr waitrel
		rts

.include "defpal.asm"

;.include "coldebug.asm"	;****************************colour register ouptut debug

;**************
;Misc variables
;**************
seldevice
		.byte 0
errno	.byte 255
OldSelCol
		.byte 0
odd_cos .fill 5,255
odd_sin .fill 5,255
FPTempU .fill 5,255	
FPTempV .fill 5,255
FPTempU2 .fill 5,255	
FPTempV2 .fill 5,255

.align $100,255
		.byte 64	;Offset uploader binary due to BASIC load addr being $0801 and not $0800 ^_^
uploader
		.binary "uploader.prg",2
uploader_end
		
.include "shared.asm"
		
endoftheshow
		.fill uploader_end-uploader
.align $100
Load_Block0			;this area is used when loading so palette in memory is not overwritten by
					;incomplete load operation.
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
			.fill 1
			.fill 1
			.fill 1
.align $100
Load_Block2	.fill 16*5
.align $100
Load_Block3	.fill 16*5
.align $100
Load_Block4	.fill 16*5


