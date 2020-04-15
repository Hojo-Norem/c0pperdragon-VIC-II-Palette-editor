;**********************************
;Screen output and control routines
;**********************************
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
		
printpal
		#prints mpal1
		#prints mpal2
		#prints mpal3
		rts

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
		
PRINTFAC .macro
		jsr $bddd
		tax
		jsr sprint		
		.endm
		
SCRON	.macro
		jsr jSCRON
		.endm
		
SCROFF  .macro
		jsr jSCROFF
		.endm
		
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
		lda defpalmode
		bne +
		#vicirqdis
+		#scroff
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
		lda defpalmode
		bne +		
		#vicirqen
+		jsr waitkey
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
		rts
		
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