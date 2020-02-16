;****************
;IRQ handler code
;****************
VICIRQEN .macro
		lda #1
		sta $d01a
		.endm
		
VICIRQDIS .macro
		lda #0
		sta $d01a
		.endm
		
		
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

		
IRQ1	lda full_upload
		beq partial
		bmi finirq1
		ldx #15
-		jsr setcol
		dex
		bpl -
		lda full_upload
		bmi finirq1
		lda #0
		sta full_upload
finIRQ1 lda #<IRQ2
		sta $0314
		lda #>IRQ2
		sta $0315
IRQ2Raster
		lda #0
		sta $d012
		asl $d019
		jmp $ea31

		
IRQ2	lda full_upload
		bmi finirq2
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
finirq2	lda #<IRQ1
		sta $0314
		lda #>IRQ1
		sta $0315
IRQ1Raster
		lda #0
		sta $d012
		asl $d019
		jmp $ea81


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

		
IRQInit and $d011
		sta $d011
		lda #255
		sta $d012
		jsr setirq
		rts
		