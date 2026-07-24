// C++ code
//

#include <string>

void setup()
{
  Serial.begin(115200);
  pinMode(0, INPUT); // Input Commands for lights
  pinMode(13, OUTPUT); // RED_1
  pinMode(12, OUTPUT); // Yellow_1
  pinMode(11, OUTPUT); // Green_1
  
  pinMode(10, OUTPUT); // RED_2
  pinMode(9, OUTPUT); // Yellow_2
  pinMode(8, OUTPUT); // Green_2
  
}

// Research on traffic light control shows 4 way intersection has
// around 27 s Green, 3 s Yellow and 30 s Red light duration. This is the reason for the below delay values.

void loop()
{   
    std::string control_input = "";
    while(len(control_input) < 2){
        if (Serial.available() > 0) {
    
        // Read the oldest incoming byte from the buffer
        std::string incomingByte = Serial.read();

        control_input += incomingByte;
        }
    }
    Serial.print("Received: ");
    Serial.println(incomingByte);

    int light_1 = std::stoi(control_input.substr(1,3));
    int light_2 = std::stoi(control_input.substr(5,7))
    
    switch(light_1){
        digitalWrite(13,LOW);
        digitalWrite(12,LOW);
        digitalWrite(11,LOW);
        case(00):
            digitalWrite(13, HIGH);
            break;

        case(01):
            digitalWrite(12, HIGH);
            break;

        case(10):
            digitalWrite(11, HIGH);
            break;

        default: break;
    };

    switch(light_2){
        digitalWrite(10,LOW);
        digitalWrite(9,LOW);
        digitalWrite(8,LOW);
        case(00):
            digitalWrite(10, HIGH);
            break;

        case(01):
            digitalWrite(9, HIGH);
            break;

        case(10):
            digitalWrite(8, HIGH);
            break;

        default: break;
    };
}