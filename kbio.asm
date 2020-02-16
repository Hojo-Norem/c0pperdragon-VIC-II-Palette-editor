;*****************
;Keyboard routines
;*****************

waitkey	
		lda #0 ;clear input buffer
		sta 198
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
		key_p = 41
		key_plus = 40
		key_minus = 43
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
INPUT_Y
		.byte $00

GOTINPUT
		.text "            .pal",0