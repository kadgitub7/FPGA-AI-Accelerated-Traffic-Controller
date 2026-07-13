// C++ code
//

void setup()
{
  Serial.begin(9600);
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
  while(true){
    digitalWrite(13, HIGH);
    digitalWrite(8, HIGH);
    delay(27000);
    digitalWrite(8, LOW);
    digitalWrite(9, HIGH);
    delay(3000);
    digitalWrite(13, LOW);
    digitalWrite(9, LOW);
    
    digitalWrite(11, HIGH);
    digitalWrite(10, HIGH);
    delay(27000);
    digitalWrite(11, LOW);
    digitalWrite(12, HIGH);
    delay(3000);
    digitalWrite(12, LOW);
    digitalWrite(10, LOW);
  }
}