;
; AssemblerApplication1.asm
;
; Created: 3/24/2023 12:00:40 PM
; Author : dbodn
;
.include "m328Pdef.inc"
.cseg
.org 0

.def LCDin = R16

; pin config
sbi DDRB, 3 ; LCD enable
sbi DDRB, 5 ; RS
sbi DDRD, 3 ; PWM signal OC2B

; output pins that interface with D4-D7
sbi DDRC, 0
sbi DDRC, 1
sbi DDRC, 2
sbi DDRC, 3


; config timer used for PWM
ldi R28, 0b00110011
sts TCCR2A, R28
ldi R28, 0b00001001
sts TCCR2B, R28
ldi R28, 0x00
sts TCNT2, R28
ldi R28, 0xC8
sts OCR2A, R28
ldi R28, 0x8C
sts OCR2B, R28

; config timer used for delays
ldi R28, 0x00
out TCCR0A, R28
ldi R28, 0x04
out TCCR0B, R28
ldi R28, 0x00
out TCNT0, R28

cbi PORTB, 5 ; set RS low
cbi PORTB, 3 ; make sure E is low

rcall timer_delay_4ms
rcall timer_delay_4ms
rcall timer_delay_4ms
rcall timer_delay_4ms
rcall timer_delay_4ms

ldi LCDin, 0b00000011 ; set 8bit mode
rcall load_LCD_1strobe
rcall timer_delay_4ms ; extra delay

ldi LCDin, 0b00000011 ; set 8bit mode
rcall load_LCD_1strobe

ldi LCDin, 0b00000011 ; set 8bit mode
rcall load_LCD_1strobe

ldi LCDin, 0b00000010 ; set 4bit mode
rcall load_LCD_1strobe


ldi LCDin, 0b00101000 ; function set
rcall load_LCD

ldi LCDin, 0b00001110 ; set display and cursor underline on
rcall load_LCD

ldi LCDin, 0b00000001 ; clear display
rcall load_LCD

ldi LCDin, 0b00000110 ; set character entry mode
rcall load_LCD


; load characters on display
sbi PORTB, 5
rcall timer_delay_100ms
ldi LCDin, 0x2a ; *
rcall load_LCD

sbi PORTB, 5
rcall timer_delay_100ms
ldi LCDin, 0x48 ; H
rcall load_LCD

sbi PORTB, 5
rcall timer_delay_100ms
ldi LCDin, 0x69 ; i
rcall load_LCD

sbi PORTB, 5
rcall timer_delay_100ms
ldi LCDin, 0x21 ; !
rcall load_LCD

looop:
	nop
	rjmp looop


load_LCD:
		swap LCDin
		out PORTC, LCDin
		rcall LCDStrobe
		rcall timer_delay_200us
		swap LCDin
		out PORTC, LCDin
		rcall LCDStrobe
		rcall timer_delay_200us
		ret

load_LCD_1strobe:
		out PORTC, LCDin
		rcall LCDStrobe
		rcall timer_delay_200us
		ret
	
LCDStrobe:
		sbi PORTB, 3
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		cbi PORTB, 3
		nop
		ret

	
timer_delay_200us:
		in R22, SREG
		push R22
		push R28
		push R29

		in R28, TCCR0B
		ldi R29, 0
		out TCCR0B, R29

		in R29, TIFR0
		sbr R29, 1<<TOV0
		out TIFR0, R29

		ldi R29, 0xF2
		out TCNT0, R29
		out TCCR0B, R28

	loop_200us:
		in R29, TIFR0
		sbrs R29, TOV0
		rjmp loop_200us

		pop R29
		pop R28
		pop R22
		out SREG, R22
		ret

timer_delay_4ms:
		in R22, SREG
		push R22
		push R28
		push R29

		in R28, TCCR0B
		ldi R29, 0
		out TCCR0B, R29

		in R29, TIFR0
		sbr R29, 1<<TOV0
		out TIFR0, R29

		ldi R29, 0x00
		out TCNT0, R29
		out TCCR0B, R28

	loop_4ms:
		in R29, TIFR0
		sbrs R29, TOV0
		rjmp loop_4ms

		pop R29
		pop R28
		pop R22
		out SREG, R22
		ret

timer_delay_100ms:
		in R22, SREG
		push R22
		push R28
		push R29

		ldi R28, 0x19
	loop_100ms:
		rcall timer_delay_4ms
		dec R28
		brne loop_100ms

		pop R29
		pop R28
		pop R22
		out SREG, R22
		ret
