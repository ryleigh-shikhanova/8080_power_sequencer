# 8080_power_sequencer
AVR-based power sequencer and supervisor for safely controlling the Intel 8080's -5V, +5V, and +12V supply rails.

Intel 8080 Power Sequencer

A dedicated power sequencing and monitoring system for an Intel 8080 hardware test platform.

The Intel 8080 requires three supply rails: -5 V, +5 V, and +12 V, with controlled startup and shutdown sequencing. This project uses an ATmega328P-based Arduino Nano as a standalone supervisor to monitor the rails, control relay-switched +5 V and +12 V supplies, and place the system into a safe state when a power fault is detected.

The sequencer is being implemented primarily in AVR assembly, with small C++ wrappers where useful for Arduino functionality such as serial diagnostics.
