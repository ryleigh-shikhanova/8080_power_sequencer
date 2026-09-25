enum class PowerState {
    STARTUP,
    ENABLE_5V,
    ENABLE_12V,
    RUNNING,
    FAULT
};

enum class FaultState {
  NEGATIVE_5V,
  _5V,
  _12V,
  RUNTIME,
  NONE
};

const byte DETECT_5V = A0;
const byte DETECT_12V = A1;
const byte DETECT_NEG5V = A2;

const byte ENABLE_5V = 2;
const byte ENABLE_12V = 3;

const byte GOOD_LED = 11;
const byte BAD_LED = 9;

constexpr float _5V_MIN_VOLTAGE = 4.75;
constexpr float _12V_MIN_VOLTAGE = 11.4;
constexpr float _NEG5V_MIN_VOLTAGE = -4.75;

constexpr float ADC_REF = 4.82;

PowerState state = PowerState::STARTUP;
FaultState fState = FaultState::NONE;

const bool DEBUG = false;

float adcVoltage(byte pin)
{
    return analogRead(pin) * (ADC_REF / 1023.0);
}

float read5V() {
  return adcVoltage(DETECT_5V);                                                                                                                                           
}

float read12V() {
 return adcVoltage(DETECT_12V) * 3; 
}

float readNEG5V() {
    const float R1 = 47000.0;  // +5V to A2
    const float R2 = 68000.0;  // A2 to negative rail
    const float POS_SUPPLY = 5.01;

    float sense = adcVoltage(DETECT_NEG5V);
    return (sense * (R1 + R2) - POS_SUPPLY * R2) / R1;                                                                                                                                       
}

bool check5V() {
  float v = read5V();
  return v >= 4.5 && v <= 5.50;
}

bool check12V() {
  float v = read12V();
  return v >= 11.00 && v <= 13;
}

bool checkNEG5V() {
  float v = readNEG5V();
  return v >= -5.5 && v <= -4.50;
}

bool enable5V() {
  digitalWrite(ENABLE_5V, HIGH);
  delay(20);
  return check5V();
}

bool enable12V() {
  digitalWrite(ENABLE_12V, HIGH);
  delay(20);
  return check12V();
}

bool disable5V() {
  digitalWrite(ENABLE_5V, LOW);
  return !check5V();
}

bool disable12V() {
  digitalWrite(ENABLE_12V, LOW);
  return !check12V();
}

 void outputFaultState() {
  switch(fState) {
    case FaultState::NEGATIVE_5V:
      Serial.println("The Negative 5V Rail is Not Present");
      break;
    case FaultState::_5V:
      Serial.println("The 5V Rail is Not Present");
      break;
    case FaultState::_12V:
      Serial.println("The 12V Rail is Not Present");
      break;
    case FaultState::NONE:
      Serial.println("No faults are detected");
      break;
    case FaultState::RUNTIME:
      Serial.println("A power rail was disconnected during runtime");
      break;
  }
 }

void badLedEnable() {
  digitalWrite(GOOD_LED, LOW);
  digitalWrite(BAD_LED, HIGH);
}

void goodLedEnable() {
  digitalWrite(GOOD_LED, HIGH);
  digitalWrite(BAD_LED, LOW);
}
