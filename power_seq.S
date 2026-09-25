#define __SFR_OFFSET 0
#include <avr/io.h>

;
;-----------------------------------------------------------
; ADC = VOLTAGE / ADC_REF * 1023
; voltage divider formula:
;       vOut = vIn * [r2 / (r1 + r2)]
;
; Ex. for 5V w/ ADC_REF = 4.82V using a 10k resistor network
;       vOut = 5.01 * (10k / (10k + 10k)) = 2.505v
;       ADC  = 2.501v / 4.82v * 1023 = 530.8 ADC
;       
;       MIN = ADC * .95  = 504 ADC
;       MAX = ADC * 1.05 = 557 ADC
;-----------------------------------------------------------
;

; 5v
.equ    DETECT_5V_PIN,  0       ; Arduino A0 = ADC0 / PC0
.equ    ENABLE_5V_PIN,  2       ; Arduino D2 = PD2

; assumptions that divider is 10k / 10k
; avcc is 4.82v
.equ    MIN_5V_ADC,     504
.equ    MAX_5V_ADC,     557

; 12v
.equ    DETECT_12V_PIN, 1       ; Arduino A1 = ADC1 / PC1
.equ    ENABLE_12V_PIN, 3       ; Arduino D3 = PD3

; assumptions of 20k / 10k divider
; avcc is 4.82v
.equ    MIN_12V_ADC,    807
.equ    MAX_12V_ADC,    891

; -5v
; assumptions that divider network is 47k/68k
; pos v = 5.01
; avcc os 4.82v
.equ    MIN_NEG5V_ADC,   173
.equ    MAX_NEG5V_ADC,   217
.equ    DETECT_NEG5V_ADC,   2   ; Arduino A2 = ADC2 / PC2

.equ    ADC_REF,        4.82

.section .text

.global sequencer_start
.type sequencer_start, @function

.extern serial_power_good
          
sequencer_start:
    rjmp SETUP

; select the multiplexer values in r24 using low 4 bits:
;   r24 -> 0 | 0 | 0 | 0 | MUX3 | MUX2 | MUX1 | MUX0
; returns result in r19:r18
; Clobbers r16, r24, SREG
GET_ADC:
    ; clear high 4 bits of r23
    andi    r24,    0x0F

    ; Select AVCC from the REFS1 and REFS0 selection registers
    ;   REFS1 = 0,  REFS0 = 1
    ;   Low 4 bits of r24 occupy MUX3-MUX0
    ldi     r16,    (1 << REFS0)
    or      r16,    r24
    sts     ADMUX,  r16

    ; set ADEN 1, Prescaler selection to 128 (ADPS2 = ADPS1 = ADPS0 = 1)
    ldi     r16,    (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts     ADCSRA, r16


    rcall   ADC_CONVERT ; val is discarded
    rcall   ADC_CONVERT ; val is kept

    lds   r18, ADCL
    lds   r19, ADCH

    ret

ADC_CONVERT:
    ; set ADSC to start conversion

    lds     r16,    ADCSRA
    ori     r16,    (1 << ADSC)
    sts     ADCSRA, r16

ADC_WAIT:
    ; poll ADSC

    lds     r16, ADCSRA
    sbrc    r16, ADSC
    rjmp    ADC_WAIT

    ret

INIT_ADC_PINS:
    ; set as inputs
    cbi     DDRC,   DETECT_5V_PIN
    cbi     DDRC,   DETECT_12V_PIN
    cbi     DDRC,   DETECT_NEG5V_ADC

    ; no internal pull-up
    cbi     PORTC,   DETECT_5V_PIN
    cbi     PORTC,   DETECT_12V_PIN
    cbi     PORTC,   DETECT_NEG5V_ADC   
    ret

INIT_OUTPUT_PINS:  
    ; set initial state low
    cbi     PORTD, ENABLE_5V_PIN
    cbi     PORTD, ENABLE_12V_PIN

    ; configure as output
    sbi     DDRD,  ENABLE_5V_PIN
    sbi     DDRD,  ENABLE_12V_PIN
    ret

;
; r24 = rdc channel
; r21:r20 = min adc val
; r23:r22 = max adc val
; returns r24:
;   1 = good
;   0 = bad
;Clobbers:
;   r16, r18-r24
CHECK_VOLTAGE:
    ; r24 contains rdc channel
    rcall   GET_ADC

    ; val < min?
    cp      r18,    r20
    cpc     r19,    r21
    brlo    VOLTAGE_BAD

    ; val > max
    cp      r22,    r18
    cpc     r23,    r19
    brlo    VOLTAGE_BAD

    ldi     r24,    1
    ret

VOLTAGE_BAD:
    clr     r24
    ret

; Clobbers the following registers
; r18, r19, r20, r21, r22, r23, r24
CHECK_NEG5V:
    ldi     r20,    lo8(MIN_NEG5V_ADC)
    ldi     r21,    hi8(MIN_NEG5V_ADC) 

    ldi     r22,    lo8(MAX_NEG5V_ADC)
    ldi     r23,    hi8(MAX_NEG5V_ADC)

    ldi     r24,    DETECT_NEG5V_ADC

    rcall   CHECK_VOLTAGE
    tst     r24
    breq    FAULT

    ret

; Clobbers the following registers
; r18, r19, r20, r21, r22, r23, r24
CHECK_5V:
    ldi     r20,    lo8(MIN_5V_ADC)
    ldi     r21,    hi8(MIN_5V_ADC) 

    ldi     r22,    lo8(MAX_5V_ADC)
    ldi     r23,    hi8(MAX_5V_ADC)

    ldi     r24,    DETECT_5V_PIN

    rcall   CHECK_VOLTAGE
    tst     r24
    breq    FAULT

    ret

; Clobbers the following registers
; r18, r19, r20, r21, r22, r23, r24
CHECK_12V:
    ldi     r20,    lo8(MIN_12V_ADC)
    ldi     r21,    hi8(MIN_12V_ADC) 

    ldi     r22,    lo8(MAX_12V_ADC)
    ldi     r23,    hi8(MAX_12V_ADC)

    ldi     r24,    DETECT_12V_PIN

    rcall   CHECK_VOLTAGE
    tst     r24
    breq    FAULT

    ret

ENABLE_5V:
    sbi     PORTD, ENABLE_5V_PIN
    rcall   DELAY_20MS
    rcall    CHECK_5V
    ret

ENABLE_12V:
    sbi     PORTD, ENABLE_12V_PIN
    rcall   DELAY_20MS
    rcall    CHECK_12V
    ret

SETUP:
    rcall   INIT_ADC_PINS
    rcall   INIT_OUTPUT_PINS
    rcall   CHECK_NEG5V
    rcall   ENABLE_5V
    rcall   ENABLE_12V
    rjmp    RUN

RUN:
    rcall   CHECK_ALL_RAILS
    rjmp    RUN

CHECK_ALL_RAILS:
    rcall   CHECK_NEG5V
    rcall   CHECK_5V
    rcall   CHECK_12V

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
