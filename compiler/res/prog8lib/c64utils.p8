; Prog8 definitions for the Commodore-64
; These are the utility subroutines.
;
; Written by Irmen de Jong (irmen@razorvine.net) - license: GNU GPL 3.0
;
; indent format: TABS, size=8


%import c64lib


~ c64utils {

		const   uword  ESTACK_LO	= $ce00
		const   uword  ESTACK_HI	= $cf00
		
		
; ----- utility functions ----

asmsub  init_system  () -> clobbers(A,X,Y) -> ()  {
	; ---- initializes the machine to a sane starting state
	; This means that the BASIC, KERNAL and CHARGEN ROMs are banked in,
	; the VIC, SID and CIA chips are reset, screen is cleared, and the default IRQ is set.
	; Also a different color scheme is chosen to identify ourselves a little. 
	; Uppercase charset is activated, and all three registers set to 0, status flags cleared.
	%asm {{
		sei
		cld
		lda  #%00101111
		sta  $00
		lda  #%00100111
		sta  $01
		jsr  c64.IOINIT
		jsr  c64.RESTOR
		jsr  c64.CINT
		lda  #6
		sta  c64.EXTCOL
		lda  #7
		sta  c64.COLOR
		lda  #0
		sta  c64.BGCOL0
		tax
		tay
		clc
		clv
		cli
		rts
	}}
}

asmsub  ubyte2decimal  (ubyte value @ A) -> clobbers() -> (ubyte @ Y, ubyte @ X, ubyte @ A)  {
	; ---- A to decimal string in Y/X/A  (100s in Y, 10s in X, 1s in A)
	%asm {{
		ldy  #$2f
		ldx  #$3a
		sec
-               iny
		sbc  #100
		bcs  -
-               dex
		adc  #10
		bmi  -
		adc  #$2f
		rts
	}}
}

asmsub  byte2decimal  (ubyte value @ A) -> clobbers() -> (ubyte @ Y, ubyte @ X, ubyte @ A)  {
	; ---- A (signed byte) to decimal string in Y/X/A  (100s in Y, 10s in X, 1s in A)
	;      note: the '-' is not part of the conversion here if it's a negative number
	%asm {{
		cmp  #0
		bpl  +
		eor  #255
		clc
		adc  #1
+		jmp  ubyte2decimal
	}}
}

asmsub  ubyte2hex  (ubyte value @ A) -> clobbers(X) -> (ubyte @ A, ubyte @ Y)  {
	; ---- A to hex string in AY (first hex char in A, second hex char in Y)
	%asm {{
		pha
		and  #$0f
		tax
		ldy  hex_digits,x
		pla
		lsr  a
		lsr  a
		lsr  a
		lsr  a
		tax
		lda  hex_digits,x
		rts

hex_digits	.text "0123456789abcdef"	; can probably be reused for other stuff as well
	}}
}


		str  word2hex_output = "1234"   ; 0-terminated, to make printing easier
asmsub  uword2hex  (uword value @ AY) -> clobbers(A,X,Y) -> ()  {
	; ---- convert 16 bit uword in A/Y into 4-character hexadecimal string into memory  'word2hex_output'
	%asm {{
		sta  c64.SCRATCH_ZPREG
		tya
		jsr  ubyte2hex
		stx  word2hex_output
		sty  word2hex_output+1
		lda  c64.SCRATCH_ZPREG
		jsr  ubyte2hex
		sta  word2hex_output+2
		sty  word2hex_output+3
		rts
	}}
}

		ubyte[3]  word2bcd_bcdbuff = [0, 0, 0]
asmsub  uword2bcd  (uword value @ AY) -> clobbers(A,X) -> ()  {
	; Convert an 16 bit binary value to BCD
	;
	; This function converts a 16 bit binary value in A/Y into a 24 bit BCD. It
	; works by transferring one bit a time from the source and adding it
	; into a BCD value that is being doubled on each iteration. As all the
	; arithmetic is being done in BCD the result is a binary to decimal
	; conversion.
	%asm {{
		sta  c64.SCRATCH_ZPB1
		sty  c64.SCRATCH_ZPREG
		sei				; disable interrupts because of bcd math
		sed				; switch to decimal mode
		lda  #0				; ensure the result is clear
		sta  word2bcd_bcdbuff+0
		sta  word2bcd_bcdbuff+1
		sta  word2bcd_bcdbuff+2
		ldx  #16			; the number of source bits

-		asl  c64.SCRATCH_ZPB1		; shift out one bit
		rol  c64.SCRATCH_ZPREG
		lda  word2bcd_bcdbuff+0		; and add into result
		adc  word2bcd_bcdbuff+0
		sta  word2bcd_bcdbuff+0
		lda  word2bcd_bcdbuff+1		; propagating any carry
		adc  word2bcd_bcdbuff+1
		sta  word2bcd_bcdbuff+1
		lda  word2bcd_bcdbuff+2		; ... thru whole result
		adc  word2bcd_bcdbuff+2
		sta  word2bcd_bcdbuff+2
		dex				; and repeat for next bit
		bne  -
		cld				; back to binary
		cli				; enable interrupts again
		rts
	}}
}


		ubyte[5]  word2decimal_output = 0
asmsub  uword2decimal  (uword value @ AY) -> clobbers(A,X,Y) -> ()  {
	; ---- convert 16 bit uword in A/Y into decimal string into memory  'word2decimal_output'
	%asm {{
		jsr  uword2bcd
		lda  word2bcd_bcdbuff+2
		clc
		adc  #'0'
		sta  word2decimal_output
		ldy  #1
		lda  word2bcd_bcdbuff+1
		jsr  +
		lda  word2bcd_bcdbuff+0

+		pha
		lsr  a
		lsr  a
		lsr  a
		lsr  a
		clc
		adc  #'0'
		sta  word2decimal_output,y
		iny
		pla
		and  #$0f
		adc  #'0'
		sta  word2decimal_output,y
		iny
		rts
	}}
	
}




; @todo this is python code for a str-to-ubyte function that doesn't use the basic rom:
;def str2ubyte(s, slen):
;    hundreds_map = {
;        0: 0,
;        1: 100,
;        2: 200
;        }
;    digitvalue = 0
;    result = 0
;    if slen==0:
;        return digitvalue
;    digitvalue = ord(s[slen-1])-48
;    slen -= 1
;    if slen==0:
;        return digitvalue
;    result = digitvalue
;    digitvalue = 10 * (ord(s[slen-1])-48)
;    result += digitvalue
;    slen -= 1
;    if slen==0:
;        return result
;    digitvalue = hundreds_map[ord(s[slen-1])-48]
;    result += digitvalue
;    return result


asmsub	c64flt_FREADSTR	(ubyte length @ A) -> clobbers(A,X,Y) -> ()	= $b7b5		; @todo needed for (slow) str conversion below
asmsub	c64flt_GETADR	() -> clobbers(X) -> (ubyte @ Y, ubyte @ A)	= $b7f7		; @todo needed for (slow) str conversion below
asmsub	c64flt_FTOSWORDYA  () -> clobbers(X) -> (ubyte @ Y, ubyte @ A)	= $b1aa		; @todo needed for (slow) str conversion below

asmsub  str2uword(str string @ AY) -> clobbers() -> (uword @ AY) {
	%asm {{
		;-- convert string (address in A/Y) to uword number in A/Y
		;   @todo don't use the (slow) kernel floating point conversion
		sta  $22
		sty  $23
		jsr  _strlen2233
		tya
		stx  c64.SCRATCH_ZPREGX
		jsr  c64flt_FREADSTR			; string to fac1
		jsr  c64flt_GETADR			; fac1 to unsigned word in Y/A
		ldx  c64.SCRATCH_ZPREGX
		sta  c64.SCRATCH_ZPREG
		tya
		ldy  c64.SCRATCH_ZPREG
		rts

_strlen2233
		;-- return the length of the (zero-terminated) string at $22/$23, in Y
		ldy  #0
-		lda  ($22),y
		beq  +
		iny
		bne  -
+		rts
	}}
}

asmsub  str2word(str string @ AY) -> clobbers() -> (word @ AY) {
	%asm {{
		;-- convert string (address in A/Y) to signed word number in A/Y
		;   @todo don't use the (slow) kernel floating point conversion
		sta  $22
		sty  $23
		jsr  str2uword._strlen2233
		tya
		stx  c64.SCRATCH_ZPREGX
		jsr  c64flt_FREADSTR		; string to fac1
		jsr  c64flt_FTOSWORDYA		; fac1 to unsigned word in Y/A
		ldx  c64.SCRATCH_ZPREGX
		sta  c64.SCRATCH_ZPREG
		tya
		ldy  c64.SCRATCH_ZPREG
		rts
	}}
}
	
asmsub  str2ubyte(str string @ AY) -> clobbers(Y) -> (ubyte @ A) {
	%asm {{
		;-- convert string (address in A/Y) to ubyte number in A
		;   @todo don't use the (slow) kernel floating point conversion
		jmp  str2uword
	}}
}
	
asmsub  str2byte(str string @ AY) -> clobbers(Y) -> (byte @ A) {
	%asm {{
		;-- convert string (address in A/Y) to byte number in A
		;   @todo don't use the (slow) kernel floating point conversion
		jmp  str2word
	}}	
}


; @todo string to 32 bit unsigned integer http://www.6502.org/source/strings/ascii-to-32bit.html

%asm {{
; copy memory UP from (SCRATCH_ZPWORD1) to (SCRATCH_ZPWORD2) of length X/Y (16-bit, X=lo, Y=hi)
; clobbers register A,X,Y
memcopy16_up	.proc
		source = SCRATCH_ZPWORD1
		dest = SCRATCH_ZPWORD2
		length = SCRATCH_ZPB1   ; (and SCRATCH_ZPREG)

		stx  length
		sty  length+1

		ldx  length             ; move low byte of length into X
		bne  +                  ; jump to start if X > 0
		dec  length             ; subtract 1 from length
+		ldy  #0                 ; set Y to 0
-		lda  (source),y         ; set A to whatever (source) points to offset by Y
		sta  (dest),y           ; move A to location pointed to by (dest) offset by Y
		iny                     ; increment Y
		bne  +                  ; if Y<>0 then (rolled over) then still moving bytes
		inc  source+1           ; increment hi byte of source
		inc  dest+1             ; increment hi byte of dest
+		dex                     ; decrement X (lo byte counter)
		bne  -                  ; if X<>0 then move another byte
		dec  length             ; weve moved 255 bytes, dec length
		bpl  -                  ; if length is still positive go back and move more
		rts                     ; done
		.pend


; copy memory UP from (SCRATCH_ZPWORD1) to (AY) with length X (1 to 256, 0 meaning 256)
; destination must not overlap, or be before start, then overlap is possible.
; clobbers A, X, Y

memcopy		.proc
		sta  c64.SCRATCH_ZPWORD2
		sty  c64.SCRATCH_ZPWORD2+1
		ldy  #0
-		lda  (c64.SCRATCH_ZPWORD1), y
		sta  (c64.SCRATCH_ZPWORD2), y
		iny
		dex
		bne  -
		rts
		.pend


; fill memory from (SCRATCH_ZPWORD1), length XY, with value in A.
; clobbers X, Y
memset          .proc
		stx  SCRATCH_ZPB1
		sty  SCRATCH_ZPREG
		ldy  #0
		ldx  SCRATCH_ZPREG
		beq  _lastpage

_fullpage	sta  (SCRATCH_ZPWORD1),y
		iny
		bne  _fullpage
		inc  SCRATCH_ZPWORD1+1          ; next page
		dex
		bne  _fullpage

_lastpage	ldy  SCRATCH_ZPB1
		beq  +
-         	dey
		sta  (SCRATCH_ZPWORD1),y
		bne  -

+           	rts
		.pend


; fill memory from (SCRATCH_ZPWORD1) number of words in SCRATCH_ZPWORD2, with word value in AY.
; clobbers A, X, Y
memsetw		.proc
		sta  _mod1+1                    ; self-modify
		sty  _mod1b+1                   ; self-modify
		sta  _mod2+1                    ; self-modify
		sty  _mod2b+1                   ; self-modify
		ldx  SCRATCH_ZPWORD1
		stx  SCRATCH_ZPB1
		ldx  SCRATCH_ZPWORD1+1
		inx
		stx  SCRATCH_ZPREG                ; second page

		ldy  #0
		ldx  SCRATCH_ZPWORD2+1
		beq  _lastpage

_fullpage
_mod1           lda  #0                         ; self-modified
		sta  (SCRATCH_ZPWORD1),y        ; first page
		sta  (SCRATCH_ZPB1),y            ; second page
		iny
_mod1b		lda  #0                         ; self-modified
		sta  (SCRATCH_ZPWORD1),y        ; first page
		sta  (SCRATCH_ZPB1),y            ; second page
		iny
		bne  _fullpage
		inc  SCRATCH_ZPWORD1+1          ; next page pair
		inc  SCRATCH_ZPWORD1+1          ; next page pair
		inc  SCRATCH_ZPB1+1              ; next page pair
		inc  SCRATCH_ZPB1+1              ; next page pair
		dex
		bne  _fullpage

_lastpage	ldx  SCRATCH_ZPWORD2
		beq  _done

		ldy  #0
-
_mod2           lda  #0                         ; self-modified
                sta  (SCRATCH_ZPWORD1), y
		inc  SCRATCH_ZPWORD1
		bne  _mod2b
		inc  SCRATCH_ZPWORD1+1
_mod2b          lda  #0                         ; self-modified
		sta  (SCRATCH_ZPWORD1), y
		inc  SCRATCH_ZPWORD1
		bne  +
		inc  SCRATCH_ZPWORD1+1
+               dex
		bne  -
_done		rts
		.pend
		
}}		
                
                
asmsub  set_irqvec_excl() -> clobbers(A) -> ()  {
	%asm {{
		sei
		lda  #<_irq_handler
		sta  c64.CINV
		lda  #>_irq_handler
		sta  c64.CINV+1
		cli
		rts
_irq_handler	jsr  irq.irq
		lda  #$ff
		sta  c64.VICIRQ			; acknowledge raster irq
		lda  c64.CIA1ICR		; acknowledge CIA1 interrupt
		jmp  c64.IRQDFEND		; end irq processing - don't call kernel
	}}
}

asmsub  set_irqvec() -> clobbers(A) -> ()  {
	%asm {{
		sei
		lda  #<_irq_handler
		sta  c64.CINV
		lda  #>_irq_handler
		sta  c64.CINV+1
		cli
		rts
_irq_handler    jsr  irq.irq
		jmp  c64.IRQDFRT		; continue with normal kernel irq routine
	
	}}
}
	
	
asmsub  restore_irqvec() -> clobbers() -> () {
	%asm {{
		sei
		lda  #<c64.IRQDFRT
		sta  c64.CINV
		lda  #>c64.IRQDFRT
		sta  c64.CINV+1
		lda  #0
		sta  c64.IREQMASK	; disable raster irq
		lda  #%10000001
		sta  c64.CIA1ICR	; restore CIA1 irq
		cli
		rts
	}}
}


asmsub  set_rasterirq(uword rasterpos @ AY) -> clobbers(A) -> () {
	%asm {{
		sei
		jsr  _setup_raster_irq
		lda  #<_raster_irq_handler
		sta  c64.CINV
		lda  #>_raster_irq_handler
		sta  c64.CINV+1
		cli
		rts

_raster_irq_handler
		jsr  irq.irq
		lda  #$ff
		sta  c64.VICIRQ			; acknowledge raster irq
		jmp  c64.IRQDFRT

_setup_raster_irq
		pha
		lda  #%01111111
		sta  c64.CIA1ICR    ; "switch off" interrupts signals from cia-1
		sta  c64.CIA2ICR    ; "switch off" interrupts signals from cia-2
		and  c64.SCROLY
		sta  c64.SCROLY     ; clear most significant bit of raster position
		lda  c64.CIA1ICR    ; ack previous irq
		lda  c64.CIA2ICR    ; ack previous irq
		pla
		sta  c64.RASTER     ; set the raster line number where interrupt should occur
		cpy  #0
		beq  +
		lda  c64.SCROLY
		ora  #%10000000
		sta  c64.SCROLY     ; set most significant bit of raster position
+		lda  #%00000001
		sta  c64.IREQMASK   ;enable raster interrupt signals from vic
		rts
	}}
}

asmsub  set_rasterirq_excl(uword rasterpos @ AY) -> clobbers(A) -> () {
	%asm {{
		sei
		jsr  set_rasterirq._setup_raster_irq
		lda  #<_raster_irq_handler
		sta  c64.CINV
		lda  #>_raster_irq_handler
		sta  c64.CINV+1
		cli
		rts

_raster_irq_handler	
		jsr  irq.irq
		lda  #$ff
		sta  c64.VICIRQ			; acknowledge raster irq
		jmp  c64.IRQDFEND		; end irq processing - don't call kernel

	}}
}



}  ; ------ end of block c64utils





~ c64scr {
	; ---- this block contains (character) Screen and text I/O related functions ----


asmsub  clear_screen (ubyte char @ A, ubyte color @ Y) -> clobbers(A) -> ()  {
	; ---- clear the character screen with the given fill character and character color.
	;      (assumes screen and color matrix are at their default addresses)

	%asm {{
		pha
		tya
		jsr  clear_screencolors
		pla
		jsr  clear_screenchars
		rts
        }}

}


asmsub  clear_screenchars (ubyte char @ A) -> clobbers(Y) -> ()  {
	; ---- clear the character screen with the given fill character (leaves colors)
	;      (assumes screen matrix is at the default address)
	%asm {{
		ldy  #0
_loop		sta  c64.Screen,y
		sta  c64.Screen+1,y
		sta  c64.Screen+$0100,y
		sta  c64.Screen+$0101,y
		sta  c64.Screen+$0200,y
		sta  c64.Screen+$0201,y
		sta  c64.Screen+$02e8,y
		sta  c64.Screen+$02e9,y
		iny
		iny
		bne  _loop
		rts
        }}
}

asmsub  clear_screencolors (ubyte color @ A) -> clobbers(Y) -> ()  {
	; ---- clear the character screen colors with the given color (leaves characters).
	;      (assumes color matrix is at the default address)
	%asm {{
		ldy  #0
_loop		sta  c64.Colors,y
		sta  c64.Colors+1,y
		sta  c64.Colors+$0100,y
		sta  c64.Colors+$0101,y
		sta  c64.Colors+$0200,y
		sta  c64.Colors+$0201,y
		sta  c64.Colors+$02e8,y
		sta  c64.Colors+$02e9,y
		iny
		iny
		bne  _loop
		rts
        }}
}


asmsub scroll_left_full  (ubyte alsocolors @ Pc) -> clobbers(A, X, Y) -> ()  {
	; ---- scroll the whole screen 1 character to the left
	;      contents of the rightmost column are unchanged, you should clear/refill this yourself
	;      Carry flag determines if screen color data must be scrolled too
	%asm {{
		bcs  +
		jmp  _scroll_screen

+               ; scroll the color memory
		ldx  #0
		ldy  #38
-
	.for row=0, row<=12, row+=1
		lda  c64.Colors + 40*row + 1,x
		sta  c64.Colors + 40*row,x
	.next
		inx
		dey
		bpl  -

		ldx  #0
		ldy  #38
-
	.for row=13, row<=24, row+=1
		lda  c64.Colors + 40*row + 1,x
		sta  c64.Colors + 40*row,x
	.next
		inx
		dey
		bpl  -

_scroll_screen  ; scroll the screen memory
		ldx  #0
		ldy  #38
-
	.for row=0, row<=12, row+=1
		lda  c64.Screen + 40*row + 1,x
		sta  c64.Screen + 40*row,x
	.next
		inx
		dey
		bpl  -

		ldx  #0
		ldy  #38
-
	.for row=13, row<=24, row+=1
		lda  c64.Screen + 40*row + 1,x
		sta  c64.Screen + 40*row,x
	.next
		inx
		dey
		bpl  -

		rts
	}}
}


asmsub scroll_right_full  (ubyte alsocolors @ Pc) -> clobbers(A,X) -> ()  {
	; ---- scroll the whole screen 1 character to the right
	;      contents of the leftmost column are unchanged, you should clear/refill this yourself
	;      Carry flag determines if screen color data must be scrolled too
	%asm {{
		bcs  +
		jmp  _scroll_screen

+               ; scroll the color memory
		ldx  #38
-
	.for row=0, row<=12, row+=1
		lda  c64.Colors + 40*row + 0,x
		sta  c64.Colors + 40*row + 1,x
	.next
		dex
		bpl  -

		ldx  #38
-
	.for row=13, row<=24, row+=1
		lda  c64.Colors + 40*row,x
		sta  c64.Colors + 40*row + 1,x
	.next
		dex
		bpl  -

_scroll_screen  ; scroll the screen memory
		ldx  #38
-
	.for row=0, row<=12, row+=1
		lda  c64.Screen + 40*row + 0,x
		sta  c64.Screen + 40*row + 1,x
	.next
		dex
		bpl  -

		ldx  #38
-
	.for row=13, row<=24, row+=1
		lda  c64.Screen + 40*row,x
		sta  c64.Screen + 40*row + 1,x
	.next
		dex
		bpl  -

		rts
	}}
}


asmsub scroll_up_full  (ubyte alsocolors @ Pc) -> clobbers(A,X) -> ()  {
	; ---- scroll the whole screen 1 character up
	;      contents of the bottom row are unchanged, you should refill/clear this yourself
	;      Carry flag determines if screen color data must be scrolled too
	%asm {{
		bcs  +
		jmp  _scroll_screen

+               ; scroll the color memory
		ldx #39
-
	.for row=1, row<=11, row+=1
		lda  c64.Colors + 40*row,x
		sta  c64.Colors + 40*(row-1),x
	.next
		dex
		bpl  -

		ldx #39
-
	.for row=12, row<=24, row+=1
		lda  c64.Colors + 40*row,x
		sta  c64.Colors + 40*(row-1),x
	.next
		dex
		bpl  -

_scroll_screen  ; scroll the screen memory
		ldx #39
-
	.for row=1, row<=11, row+=1
		lda  c64.Screen + 40*row,x
		sta  c64.Screen + 40*(row-1),x
	.next
		dex
		bpl  -

		ldx #39
-
	.for row=12, row<=24, row+=1
		lda  c64.Screen + 40*row,x
		sta  c64.Screen + 40*(row-1),x
	.next
		dex
		bpl  -

		rts
	}}
}


asmsub scroll_down_full  (ubyte alsocolors @ Pc) -> clobbers(A,X) -> ()  {
	; ---- scroll the whole screen 1 character down
	;      contents of the top row are unchanged, you should refill/clear this yourself
	;      Carry flag determines if screen color data must be scrolled too
	%asm {{
		bcs  +
		jmp  _scroll_screen

+               ; scroll the color memory
		ldx #39
-
	.for row=23, row>=12, row-=1
		lda  c64.Colors + 40*row,x
		sta  c64.Colors + 40*(row+1),x
	.next
		dex
		bpl  -

		ldx #39
-
	.for row=11, row>=0, row-=1
		lda  c64.Colors + 40*row,x
		sta  c64.Colors + 40*(row+1),x
	.next
		dex
		bpl  -

_scroll_screen  ; scroll the screen memory
		ldx #39
-
	.for row=23, row>=12, row-=1
		lda  c64.Screen + 40*row,x
		sta  c64.Screen + 40*(row+1),x
	.next
		dex
		bpl  -

		ldx #39
-
	.for row=11, row>=0, row-=1
		lda  c64.Screen + 40*row,x
		sta  c64.Screen + 40*(row+1),x
	.next
		dex
		bpl  -

		rts
	}}
}



asmsub  print (str text @ AY) -> clobbers(A,Y) -> ()  {
	; ---- print null terminated string from A/Y
	; note: the compiler contains an optimization that will replace
	;       a call to this subroutine with a string argument of just one char,
	;       by just one call to c64.CHROUT of that single char.    @todo do this
	%asm {{
		sta  c64.SCRATCH_ZPB1
		sty  c64.SCRATCH_ZPREG
		ldy  #0
-               lda  (c64.SCRATCH_ZPB1),y
		beq  +
		jsr  c64.CHROUT
		iny
		bne  -
+		rts
	}}
}


asmsub  print_p  (str_p text @ AY) -> clobbers(A,X) -> (ubyte @ Y)  {
	; ---- print pstring (length as first byte) from A/Y, returns str len in Y
	%asm {{
		sta  c64.SCRATCH_ZPB1
		sty  c64.SCRATCH_ZPREG
		ldy  #0
		lda  (c64.SCRATCH_ZPB1),y
		beq  +
		tax
-		iny
		lda  (c64.SCRATCH_ZPB1),y
		jsr  c64.CHROUT
		dex
		bne  -
+		rts 			; output string length is in Y
	}}
}


asmsub  print_ub0  (ubyte value @ A) -> clobbers(A,X,Y) -> ()  {
	; ---- print the ubyte in A in decimal form, with left padding 0s (3 positions total)
	%asm {{
		jsr  c64utils.ubyte2decimal
		pha
		tya
		jsr  c64.CHROUT
		txa
		jsr  c64.CHROUT
		pla
		jmp  c64.CHROUT
	}}
}


asmsub  print_ub  (ubyte value @ A) -> clobbers(A,X,Y) -> ()  {
	; ---- print the ubyte in A in decimal form, without left padding 0s
	%asm {{
		jsr  c64utils.ubyte2decimal
_print_byte_digits
		pha
		cpy  #'0'
		bne  _print_hundreds
		cpx  #'0'
		bne  _print_tens
		pla
		jmp  c64.CHROUT
_print_hundreds	tya
		jsr  c64.CHROUT
_print_tens	txa
		jsr  c64.CHROUT
		pla
		jmp  c64.CHROUT
	}}
}
	
asmsub  print_b  (byte value @ A) -> clobbers(A,X,Y) -> ()  {
	; ---- print the byte in A in decimal form, without left padding 0s
	%asm {{
		pha
		cmp  #0
		bpl  +
		lda  #'-'
		jsr  c64.CHROUT
+		pla
		jsr  c64utils.byte2decimal
		jmp  print_ub._print_byte_digits
	}}
}


asmsub  print_ubhex  (ubyte prefix @ Pc, ubyte value @ A) -> clobbers(A,X,Y) -> ()  {
	; ---- print the ubyte in A in hex form (if Carry is set, a radix prefix '$' is printed as well)
	%asm {{
		bcc  +
		pha
		lda  #'$'
		jsr  c64.CHROUT
		pla
+		jsr  c64utils.ubyte2hex
		jsr  c64.CHROUT
		tya
		jmp  c64.CHROUT
	}}
}


asmsub print_uwhex  (ubyte prefix @ Pc, uword value @ AY) -> clobbers(A,X,Y) -> ()  {
	; ---- print the uword in A/Y in hexadecimal form (4 digits)
	;      (if Carry is set, a radix prefix '$' is printed as well)
	%asm {{
		pha
		tya
		jsr  print_ubhex
		pla
		clc
		jmp  print_ubhex
	}}
}


asmsub  print_uw0  (uword value @ AY) -> clobbers(A,X,Y) -> ()  {
	; ---- print the uword in A/Y in decimal form, with left padding 0s (5 positions total)
	%asm {{
		jsr  c64utils.uword2decimal
		ldy  #0
-		lda  c64utils.word2decimal_output,y
		jsr  c64.CHROUT
		iny
		cpy  #5
		bne  -
		rts
	}}
}


asmsub  print_uw  (uword value @ AY) -> clobbers(A,X,Y) -> ()  {
	; ---- print the uword in A/Y in decimal form, without left padding 0s
	%asm {{
		jsr  c64utils.uword2decimal
		ldy  #0
		lda  c64utils.word2decimal_output
		cmp  #'0'
		bne  _pr_decimal
		iny
		lda  c64utils.word2decimal_output+1
		cmp  #'0'
		bne  _pr_decimal
		iny
		lda  c64utils.word2decimal_output+2
		cmp  #'0'
		bne  _pr_decimal
		iny
		lda  c64utils.word2decimal_output+3
		cmp  #'0'
		bne  _pr_decimal
		iny

_pr_decimal
		lda  c64utils.word2decimal_output,y
		jsr  c64.CHROUT
		iny
		cpy  #5
		bcc  _pr_decimal
		rts
	}}
}

asmsub  print_w  (word value @ AY) -> clobbers(A,X,Y) -> ()  {
	; ---- print the (signed) word in A/Y in decimal form, without left padding 0s
	%asm {{
		cpy  #0
		bpl  +
		pha
		lda  #'-'
		jsr  c64.CHROUT
		tya
		eor  #255
		tay
		pla
		eor  #255
		clc
		adc  #1
		bcc  +
		iny
+		jmp  print_uw
	}}
}

asmsub  input_chars  (uword buffer @ AY) -> clobbers(A, X) -> (ubyte @ Y)  {
	; ---- Input a string (max. 80 chars) from the keyboard. Returns length in Y.
	;      It assumes the keyboard is selected as I/O channel!

	%asm {{
		sta  c64.SCRATCH_ZPWORD1
		sty  c64.SCRATCH_ZPWORD1+1
		ldy  #0				; char counter = 0
-		jsr  c64.CHRIN
		cmp  #$0d			; return (ascii 13) pressed?
		beq  +				; yes, end.
		sta  (c64.SCRATCH_ZPWORD1),y	; else store char in buffer
		iny
		bne  -
+		lda  #0
		sta  (c64.SCRATCH_ZPWORD1),y	; finish string with 0 byte
		rts

	}}
}

asmsub  setchr  (ubyte col @Y, ubyte row @A) -> clobbers(A) -> ()  {
	; ---- set the character in SCRATCH_ZPB1 on the screen matrix at the given position
	%asm {{
		sty  c64.SCRATCH_ZPREG
		asl  a
		tay
		lda  _screenrows+1,y
		sta  _mod+2
		lda  _screenrows,y
		clc
		adc  c64.SCRATCH_ZPREG
		sta  _mod+1
		bcc  +
		inc  _mod+2
+		lda  c64.SCRATCH_ZPB1
_mod		sta  $ffff		; modified
		rts
		
_screenrows	.word  $0400 + range(0, 1000, 40)
	}}
}

asmsub  setclr  (ubyte col @Y, ubyte row @A) -> clobbers(A) -> ()  {
	; ---- set the color in SCRATCH_ZPB1 on the screen matrix at the given position
	%asm {{
		sty  c64.SCRATCH_ZPREG
		asl  a
		tay
		lda  _colorrows+1,y
		sta  _mod+2
		lda  _colorrows,y
		clc
		adc  c64.SCRATCH_ZPREG
		sta  _mod+1
		bcc  +
		inc  _mod+2
+		lda  c64.SCRATCH_ZPB1
_mod		sta  $ffff		; modified
		rts
		
_colorrows	.word  $d800 + range(0, 1000, 40)
	}}
}

		
sub  setcc  (ubyte column, ubyte row, ubyte char, ubyte color)  {
	; ---- set char+color at the given position on the screen
	%asm {{
		lda  setcc_row
		asl  a
		tay
		lda  setchr._screenrows+1,y
		sta  _charmod+2
		adc  #$d4
		sta  _colormod+2
		lda  setchr._screenrows,y
		clc
		adc  setcc_column
		sta  _charmod+1
		sta  _colormod+1
		bcc  +
		inc  _charmod+2
		inc  _colormod+2
+		lda  setcc_char
_charmod	sta  $ffff		; modified
		lda  setcc_color
_colormod	sta  $ffff		; modified
		rts
	}}	
}

asmsub  PLOT  (ubyte col @ Y, ubyte row @ A) -> clobbers(A) -> () {
	; ---- safe wrapper around PLOT kernel routine, to save the X register.
	%asm  {{
		stx  c64.SCRATCH_ZPREGX
		tax
		clc
		jsr  c64.PLOT
		ldx  c64.SCRATCH_ZPREGX
		rts
	}}
}


}  ; ---- end block c64scr
