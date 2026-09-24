#define __SFR_OFFSET 0
#include <avr/io.h>

.section  .text

.global   sequencer_start
.type     sequencer_start,  @function

sequencer_start:

DELAY_20MS:
  ; delay

RESET:
  ;init
  rjmp  CHECK_NEG5

CHECK_NEG5:
  ; read ADC2
  ; compare thresholds

  brlo  FAULT
  rjmp  ENABLE_5V

ENABLE_5V:
  ; enables the 5v relay
  sbi   PORTD,  2
  rcall DELAY_20MS
  rjmp  CHECK_5V

CHECK_5V:
  ; check 5v
  call  serial_power_good
  rjmp  RUN;
  
RUN:
  rcall CHECK_ALL_RAILS 

CHECK_ALL_RAILS:
  ; check rails

FAULT:
  cbi PORTD, 3  ; + 12 off
  rcall DELAY_20MS
  cbi   PORTD, 2

FAULT_LOOP:
  rjmp  FAULT_LOOP;

; These will output the message for each fault state

FAULT_STATE:

NEGATIVE_5:

_5V:

_12V:
  
RUNTIME:

NONE: