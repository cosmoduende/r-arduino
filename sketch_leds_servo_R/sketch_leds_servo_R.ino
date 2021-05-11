# include <Servo.h>

// SETTING SERVO AND RGB LEDS 
 
int rLed = 0;
int gLed = 0;
int bLed = 0;
int serv = 0;

int redLed = 6; // RED LED ON PIN 6
int greenLed = 5; // GREEN LED ON PIN 5
int blueLed = 3; // BLUE LED ON PIN 3
int theServo = 9; // SERVO ON PIN 9

Servo myServo;

void setup() {
  Serial.begin(9600);  
  
  // SETTING PINS AS OUTPUT
  
  pinMode(redLed, OUTPUT);
  pinMode(greenLed, OUTPUT);
  pinMode(blueLed, OUTPUT);

  // ATTACHING SERVO OBJECT
  
  myServo.attach(theServo);
}

void loop() {
  if (Serial.available()){
    
   // MAKING VARIABLE VISIBLE TO ONLY 1 FUNCTION
   // CALL AND PRESERVE THEIR VALUE
   
   static int t = 0;
   
   char myvalue = Serial.read();

   switch(myvalue){
    
    // MYVALUE IS A a VARIABLE WHOSE VALUE TO COMPARE WITH VARIOUS CASES
    
    case '0'...'9':
      t = t * 10 + myvalue - '0';
      break;   
        
    case 'R':
    {
      rLed = map(t, 0, 100, 0, 255);
      analogWrite(redLed, rLed);
      Serial.println(rLed);  
    }
    t = 0;
    break;
    
    case 'G':
    {
      gLed = map(t, 0, 100, 0, 255);
      analogWrite(greenLed, gLed);
      Serial.println(gLed);
    }
    t = 0;
    break;

    case 'B':
    {
      bLed = map(t, 0, 100, 0, 255);
      analogWrite(blueLed, bLed);
      Serial.println(bLed);
    }
    t = 0;
    break;

    case 'S':
    {
      
      // MAPPING ANALOGUE LED VALUE TO ANGLE FROM 0 TO 180 DEGREES
      
      serv = map(t, 0, 255, 0, 179);
      Serial.println(serv);
      delay(5);
      myServo.write (serv);
      delay(150);
    }
    t = 0;
    break;
   }
  }
}
