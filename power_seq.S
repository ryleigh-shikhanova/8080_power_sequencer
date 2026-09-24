#define __SFR_OFFSET 0
#include <avr/io.h>

.equ    DETECT_5V_PIN,  0       ; Arduino A0 = ADC0 / PC0
.equ    ENABLE_5V_PIN,  2       ; Arduino D2 = PD2
.equ    MIN_5V,         4750    ; mV
.equ    MAX_5V,         5250    ; mV

.equ    DETECT_12V_PIN, 1       ; Arduino A1 = ADC1 / PC1
.equ    ENABLE_12V_PIN, 3       ; Arduino D3 = PD3
.equ    MIN_12V,        1750    ; mV
.equ    MAX_12V,        2150    ; mV

.equ    MIN_NEG5V,      -5250   ; mV
.equ    MAX_NEG5V,      -4750   ; mV
.equ    DETECT_NEG5V_ADC,   2   ; Arduino A2 = ADC2 / PC2

.equ    ADC_REF,        5

.section .text

.global sequencer_start
.type sequencer_start, @function

.extern serial_power_good
          
sequencer_start:
    rjmp SETUP

SETUP:
    rcall   INIT_ADC_PINS
    rcall   INIT_OUTPUT_PINS
    rjmp    RESET

; set detection pins to input
; disable internal pull-up
INIT_ADC_PINS:
    ; set as inputs
    cbi DDRC,   DETECT_5V_PIN
    cbi DDRC,   DETECT_12V_PIN
    cbi DDRC,   DETECT_NEG5V_ADC

    ; no internal pull-up
    cbi PORTC,   DETECT_5V_PIN
    cbi PORTC,   DETECT_12V_PIN
    cbi PORTC,   DETECT_NEG5V_ADC   
    ret

INIT_OUTPUT_PINS:  
    ; set initial state low
    cbi PORTD, ENABLE_5V_PIN
    cbi PORTD, ENABLE_12V_PIN

    ; configure as output
    sbi DDRD,  ENABLE_5V_PIN
    sbi DDRD,  ENABLE_12V_PIN
    ret

RESET:
    ; Configure relay pins as outputs eventually.

    rjmp CHECK_NEG5


CHECK_NEG5:
    ; Read ADC2.
    ; Compare against acceptable ADC thresholds.

    ; Example later:
    ; brlo FAULT

    rjmp ENABLE_5V


ENABLE_5V:
    ; Enable +5 V relay.
    sbi PORTD, 2

    rcall DELAY_20MS
    rjmp CHECK_5V


CHECK_5V:
    ; Read ADC0 and validate +5 V.

    call serial_power_good
    rjmp ENABLE_12V


ENABLE_12V:
    sbi PORTD, 3

    rcall DELAY_20MS
    rjmp CHECK_12V


CHECK_12V:
    ; Read ADC1 and validate +12 V.

    rjmp RUN


RUN:
    rcall CHECK_ALL_RAILS
    rjmp RUN


CHECK_ALL_RAILS:
    ; Check -5 V
    ; Check +5 V
    ; Check +12 V
    ;
    ; On failure:
    ; rjmp FAULT

    ret


FAULT:
    ; +12 V OFF first
    cbi   PORTD, 3

    rcall DELAY_20MS

    ; +5 V OFF second
    cbi   PORTD, 2

    rjmp  FAULT_LOOP


FAULT_LOOP:
    rjmp FAULT_LOOP


DELAY_20MS:
    ; Temporary placeholder.
    ; IMPORTANT: must return.
    ret
