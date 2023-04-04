;
; AssemblerApplication1.asm
;
; Created: 3/24/2023 12:00:40 PM
; Author : dbodn
;
.include "m328Pdef.inc"
.cseg
.org 0
jmp main

;;;;;;;;;;;;;;;;;;;;;;;INTERUPT STUFF;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0006
jmp isr_pcint0


;;;;;;;;;;;;;;;;;;;;;;;;CONFIGURATION;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org INT_VECTORS_SIZE

dcmessage: .db "DC ="
fanOn: .db "FAN:  ON"
fanOff: .db "FAN: OFF"

main:
.def LCDin = R16
.def fanState = R18
	ldi fanState, 0x01 ;fanState controls on/off
.def fanspd = R17
	ldi fanspd, 0x00 ;8c
.def upperdigit = R26
	ldi upperdigit, 9
.def lowerdigit = R27
	ldi lowerdigit, 9
.def updateDisplay = R20
	ldi updateDisplay, 0x00

; interupt control register config
ldi R28, 0b00000111
sts PCMSK0, R28

ldi R28, 0b00001111
sts EICRA, R28

ldi R28, 0b00000001
sts PCICR, R28


; pin config
sbi DDRB, 3 ; LCD enable
sbi DDRB, 5 ; RS
sbi DDRD, 3 ; PWM signal OC2B

cbi DDRB, 2 ; pushbutton input
cbi DDRB, 0
cbi DDRB, 1

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
sts OCR2B, fanspd

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

sei ; enable interupts

	rcall update_display

looop:
	rcall timer_delay_100ms
	ldi R28, 0x00
	cpse updateDisplay, R28
		rcall update_display
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


inc_fan_speed:
		cpi fanspd, 0
		breq inc_fan_speed_end
		dec fanspd
		dec fanspd
		rcall inc_duty_cycle_value
		sts OCR2B, fanspd
	inc_fan_speed_end:
		ret
dec_fan_speed:
		cpi fanspd, 0xC8
		breq dec_fan_speed_end
		inc fanspd
		inc fanspd
		rcall dec_duty_cycle_value
		sts OCR2B, fanspd
	dec_fan_speed_end:
		ret


turn_fan_off:
		push R28
		in R28, SREG
		push R28

		ldi R28, 0xC8
		sts OCR2B, R28
		ldi fanState, 0x00
		
		pop R28
		out SREG, R28
		pop R28
		ret

turn_fan_on:
		push R28
		in R28, SREG
		push R28

		sts OCR2B, fanspd
		ldi fanState, 0x01

		pop R28
		out SREG, R28
		pop R28
		ret


update_display:
		cbi PORTB, 5
		rcall timer_delay_100ms
		ldi LCDin, 0b00000001 ; clear display
		rcall load_LCD

		sbi PORTB,5
		rcall timer_delay_100ms
		ldi ZH, HIGH(dcmessage<<1)
		ldi ZL, LOW(dcmessage<<1)
		ldi R29, 4
		display_duty_cycle_loop:
		lpm LCDin, Z
		rcall load_LCD
		adiw zh:zl, 1
		dec R29
		brne display_duty_cycle_loop

		ldi LCDin, 0x20 ; space
		rcall load_LCD

		ldi R28, 48
		add upperdigit, R28
		add lowerdigit, R28
		mov LCDin, upperdigit
		rcall load_LCD
		mov LCDin, lowerdigit
		rcall load_LCD
		sub upperdigit, R28
		sub lowerdigit, R28

		ldi LCDin, 0x25
		rcall load_LCD

		cbi PORTB, 5
		rcall timer_delay_100ms
		ldi LCDin, 0b11000000 ; write to second line of display
		rcall load_LCD

		sbi PORTB,5
		rcall timer_delay_100ms

		ldi R24, 8
		cpi fanState, 0
		breq display_fan_off
		ldi ZH, HIGH(fanOn<<1)
		ldi ZL, LOW(fanOn<<1)
		rjmp display_fan_loop
	display_fan_off:
		ldi ZH, HIGH(fanOff<<1)
		ldi ZL, LOW(fanOff<<1)
	display_fan_loop:
		lpm LCDin, Z
		rcall load_LCD
		adiw zh:zl, 1
		dec R24
		brne display_fan_loop

		ldi updateDisplay, 0x00
		ret

inc_duty_cycle_value:
		push R22
		in R22, SREG
		push R22

		ldi R22, 9
		cpse lowerdigit, R22
			rjmp inc_lower_digit
		cpse upperdigit, R22
			rjmp inc_upper_digit
		rjmp end_inc_duty_cycle
	inc_upper_digit:
		inc upperdigit
		ldi lowerdigit, 0
		rjmp end_inc_duty_cycle
	inc_lower_digit:
		inc lowerdigit
		rjmp end_inc_duty_cycle

	end_inc_duty_cycle:
		pop R22
		out SREG, R22
		pop R22
		ret

dec_duty_cycle_value:
		push R22
		in R22, SREG
		push R22

		ldi R22, 0
		cpse lowerdigit, R22
			rjmp dec_lower_digit
		cpse upperdigit, R22
			rjmp dec_upper_digit
		rjmp end_dec_duty_cycle

	dec_lower_digit:
		dec lowerdigit
		rjmp end_dec_duty_cycle

	dec_upper_digit:
		dec upperdigit
		ldi lowerdigit, 9

	end_dec_duty_cycle:
		pop R22
		out SREG, R22
		pop R22
		ret

		;used to debounce rpg
delay_short:
		push R30
		push R31

		.equ count2 = 0x2710
		ldi r30, low(count2)
		ldi r31, high(count2)
	d3:
		sbiw r31:r30, 1	
		brne d3

		pop R31
		pop R30
		ret

;looks at input from rpg to tell if it is rotating
check_rpg_inputs:
		push R24
		push R25
		in R24, PINB
		andi R24, 0x03
		lsl R24
		lsl R24
		mov R25, R24
		rcall delay_short
		in r24, PINB
		andi R24, 0x03
		or R24, R25
		andi R24, 0x0F
		ldi R25, 0x04
		cpse R24, R25
			rjmp next_check
		rcall dec_fan_speed
		rjmp check_inputs_end

	next_check:
		ldi R25, 0x08
		cpse R24, R25
			rjmp check_inputs_end
		rcall inc_fan_speed
	check_inputs_end:
		pop R25
		pop R24
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Timed Delays;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
timer_delay_200us:
		push R22
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
		pop R22
		ret

timer_delay_4ms:
		push R22
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
		pop R22
		ret

timer_delay_100ms:
		push R22
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
		pop R22
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;Interupt Routines;;;;;;;;;;;;;;;;;;;;;;;

isr_pcint0:
	in R19, PINB
	push R28
	in R28, SREG
	push R28

	sbic PINB, 2
		rjmp check_rpg

	ldi R28, 0x00
	cpse fanState, R28
		rjmp isr_turn_off
	rcall turn_fan_on
	rjmp isr_pcint0_end

	isr_turn_off:
	rcall turn_fan_off
	rjmp isr_pcint0_end

	check_rpg:
	ldi R28, 0x00
	cpse fanState, R28
		rcall check_rpg_inputs

	isr_pcint0_end:
	ldi updateDisplay, 0x01
	pop R28
	out SREG, R28
	pop R28
	reti