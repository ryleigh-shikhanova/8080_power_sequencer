#pragma once

#include <Arduino.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void serial_print_volt(uint16_t adc);
void serial_power_good();
void serial_fault();

#ifdef __cplusplus
}
#endif