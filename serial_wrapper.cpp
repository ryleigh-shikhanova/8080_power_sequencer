#include "serial_wrapper.h"

extern "C" void serial_print_volt(uint16_t adc)
{
    Serial.println(adc);
}

extern "C" void serial_power_good()
{
    Serial.println("POWER GOOD");
}

extern "C" void serial_fault()
{
    Serial.println("POWER FAULT");
}