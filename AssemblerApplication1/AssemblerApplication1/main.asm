;
; AssemblerApplication1.asm
;
; Created: 3/24/2023 12:00:40 PM
; Author : dbodn
;
.include "m328Pdef.inc"
.cseg
.org 0


;config timer
ldi R28, 0x00
out TCCR0A, R28
ldi R28, 0x04
out TCCR0B, R28
ldi R28, 0x00
out TCNT0, R28

;pin config
sbi DDRB, 3 ; LCD enable
sbi DDRB, 5

sbi PINB, 5

ldi R25, 0x04
out PORTC, R25
rcall LCDStrobe
rcall timer_delay_200us
ldi R25, 0x05
out PORTC, R25
rcall LCDStrobe
rcall timer_delay_200us



LCDStrobe:
		sbi PINB, 3
		rcall LCDStrobe_delay
		cbi PINB, 3
		rcall LCDStrobe_delay
		ret

LCDStrobe_delay:
		push R28
		ldi R28, 0xA0
	LCDStrobe_delay_loop:
		dec R28
		brne LCDStrobe_delay_loop
		pop R28
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
