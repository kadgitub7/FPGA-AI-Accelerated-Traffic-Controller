#include <SoftwareSerial.h>

// FPGA TX -> Arduino D2
// Arduino RX is D2
SoftwareSerial fpgaSerial(2, 3); 
// RX = 2

void setup()
{
  Serial.begin(115200);

  fpgaSerial.begin(115200);

  // Light 1
  pinMode(13, OUTPUT); // RED_1
  pinMode(12, OUTPUT); // YELLOW_1
  pinMode(11, OUTPUT); // GREEN_1

  // Light 2
  pinMode(10, OUTPUT); // RED_2
  pinMode(9,  OUTPUT); // YELLOW_2
  pinMode(8,  OUTPUT); // GREEN_2

  // Turn everything off initially
  digitalWrite(13, LOW);
  digitalWrite(12, LOW);
  digitalWrite(11, LOW);

  digitalWrite(10, LOW);
  digitalWrite(9, LOW);
  digitalWrite(8, LOW);

  Serial.println("Arduino started");
}

void loop()
{
  if (fpgaSerial.available() >= 2)
  {
    byte light_1 = fpgaSerial.read();
    byte light_2 = fpgaSerial.read();

    Serial.print("Received Light 1: ");
    Serial.println(light_1);

    Serial.print("Received Light 2: ");
    Serial.println(light_2);

    digitalWrite(13, LOW);
    digitalWrite(12, LOW);
    digitalWrite(11, LOW);

    switch (light_1)
    {
      case 0:
        digitalWrite(13, HIGH);
        break;

      case 1:
        digitalWrite(12, HIGH);
        break;

      case 2:
        digitalWrite(11, HIGH);
        break;

      default:
        Serial.println("Invalid Light 1 value");
        break;
    }

    digitalWrite(10, LOW);
    digitalWrite(9, LOW);
    digitalWrite(8, LOW);

    switch (light_2)
    {
      case 0:
        digitalWrite(10, HIGH);
        break;

      case 1:
        digitalWrite(9, HIGH);
        break;

      case 2:
        digitalWrite(8, HIGH);
        break;

      default:
        Serial.println("Invalid Light 2 value");
        break;
    }
  }
}