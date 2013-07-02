/**
 *  BT RFID Reader 
 * 
 *  Dr. Michael Kroll 2011
 *  
 *  @see:    http://www.stronglink.cn/english/sl030.htm
 *
 *  Arduino to SL030 wiring:
 *  A3/OUT     5
 *  A4/SDA     3
 *  A5/SCL     4
 *  5V         -
 *  GND        6
 *  3V3        1
 */

// For playing tones
#include "pitches.h"

#include <Wire.h>
#include <SL018.h>

// TAG pin (low level when tag present)
#define TAG 17       // A3

#define BUZZER       6
#define YELLOW_LED   8
#define GREEN_LED    9
#define BUTTON_PIN   2

#define TAG_DETECTED_TONE NOTE_DS8
#define CONNECTED_TONE    NOTE_CS1

SL018 rfid;
boolean tagPresent = false;
boolean connected = false;

// Constants for HID Raw Mode
const unsigned char eject_pressed_report[7] = {0x9f, 0x05, 0xa1, 0x03, 0x80, 0x00, 0x00};
const unsigned char eject_released_report[7] = {0x9f, 0x05, 0xa1, 0x03, 0x00, 0x00, 0x00};

void setup() { 
  pinMode(TAG, INPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(YELLOW_LED, OUTPUT); 
  //pinMode(A0, INPUT);
  
  // set the external interrupt on pin 2
  // If the button is pressed the method: buttonPressed is called
  attachInterrupt(0, buttonPressed, RISING);

  // set the external interrupt on pin 3
  // If the carrier is detected bt WT-12 PIO7 is set high the method: carrierDetect is called
  attachInterrupt(1, carrierDetect, RISING);
  
  digitalWrite(GREEN_LED, HIGH);  
  Wire.begin();
  Serial.begin(9600);
}

/**
 * Interrupt method which is called if an external interrupt is 
 * detected on pin 2
 */
void carrierDetect() {
  delay(2000);
  //Bluetooth
  Serial.println("select 0");
}

/**
 * Interrupt method which is called if an external interrupt is 
 * detected on pin 3
 */
void buttonPressed() {
  static unsigned long last_interrupt_time = 0;
  unsigned long interrupt_time = millis();
  // If interrupts come faster than 200ms, assume it's a bounce and ignore
  if (interrupt_time - last_interrupt_time > 200) {
    for (int i = 0; i < 7; i++) {
      //Bluetooth
      Serial.print((byte)eject_pressed_report[i]);
    }  
    for (int i = 0; i < 7; i++) {
      //Bluetooth
      Serial.print((byte)eject_released_report[i]);
    }
  }
  last_interrupt_time = interrupt_time;
}

void loop() {
      
  if(!tagPresent && !digitalRead(TAG)) {
    tagPresent = true;
    // tag has to be selected first
    rfid.selectTag();
    digitalWrite(YELLOW_LED, HIGH);  
    tone(BUZZER, TAG_DETECTED_TONE);  
  }
  
  // check if tag has gone
  if(tagPresent && digitalRead(TAG)) {
    tagPresent = false;
    digitalWrite(YELLOW_LED, LOW);
    noTone(BUZZER);
  }
  
  if(rfid.available()) {
     switch(rfid.getCommand()) {
        case SL018::CMD_SEEK:
        case SL018::CMD_SELECT:          
          //Bluetooth
          Serial.println(rfid.getTagString());
   
          delay(200);
   
          // terminate seek
          rfid.haltTag();
          digitalWrite(YELLOW_LED, LOW);
          noTone(BUZZER);
       }
   }
}