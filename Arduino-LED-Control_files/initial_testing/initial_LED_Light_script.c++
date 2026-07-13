// C++ code
//

int light = 0;

void setup()
{
  Serial.begin(9600);
  pinMode(11, OUTPUT); // RED
  pinMode(10, OUTPUT); // Yellow
  pinMode(9, OUTPUT); // Green
  
}

void loop()
{
  for(int i = 0; i < 30; i++){
    digitalWrite(11, HIGH);
    delay(1000);
    digitalWrite(11, LOW);
    
    digitalWrite(10, HIGH);
    delay(1000);
    digitalWrite(10, LOW);
    
    digitalWrite(9, HIGH);
    delay(1000);
    digitalWrite(9, LOW);
  }
  
}