;*******************
;save load functions
;*******************

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
+       lda #16
        LDX #<gotinput
        LDY #>gotinput
        JSR $FFBD     ; call SETNAM
        LDA #$00
        LDX seldevice      
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
+		jsr printerr	; A contains BASIC error code
		jsr waitrel
		jsr waitkey
		jsr waitrel
+		jsr $ffe7
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
        LDX #<gotinput
        LDY #>gotinput
        JSR $FFBD     			; call SETNAM
        LDA #$00
        LDX seldevice    
+	    LDY #$00
        JSR $FFBA     			; call SETLFS
        LDX #<(endoftheshow+1)	;uploader
        LDY #>(endoftheshow+1)	;uploader
        LDA #0
        JSR $FFD5     			; call load
        BCS lerror		    	; if carry set, a load error has happened
        jmp loaddone
lerror	jsr printerr			; A contains BASIC error code
		jsr $ffe7
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
		lda #17
		sta fullcalculation
		jmp mainscr	

		
getdrive
		#prints devtxt
		lda #255
		sta FullPalOddL-1 
		ldy #0
		clc
-		lda 197
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
        LDX seldevice  
		LDY #$00       ; secondary address 0 (required for dir reading!)
        JSR $FFBA      ; call SETLFS
        JSR $FFC0      ; call OPEN (open the directory)
        BCS dderror     ; quit if OPEN failed
        LDX #$02       ; filenumber 2
        JSR $FFC6      ; call CHKIN
        LDY #$04       ; skip 4 bytes on the first dir line
        BNE ddskip2
ddnext	ldy #2			; skip 2 bytes on all other lines
ddskip2 JSR ddgetbyte    ; get a byte from dir and ignore it
        DEY
        BNE ddskip2
        JSR ddgetbyte    ; get low byte of basic line number
		JSR ddgetbyte    ; get high byte of basic line number
ddchar	JSR ddgetbyte
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
        JSR $FFE1      ; RUN/STOP pressed?
        BNE ddnext      ; no RUN/STOP -> continue
jpdisktitle
		jmp pdisktitle
jgotquote
		jmp gotquote
dderror	sta errno		; A contains BASIC error code
        ; most likely error:
        ; A = $05 (DEVICE NOT PRESENT)
ddexit
        LDA #$02       ; filenumber 2
        JSR $FFC3      ; call CLOSE
        JSR $FFCC     ; call CLRCHN	
		lda #13
		jsr $ffd2
        RTS

		
ddgetbyte
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
