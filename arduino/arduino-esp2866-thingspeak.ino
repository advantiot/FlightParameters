// Sending data from Arduino to ThingsSpeak via an ESP8266
// Notes: This sends data to ThingSpeak just fine but the Serial Monitor outputs error messages and an ROR message. Check later.
/*
 ESP8266 IP CONFIG (Hogwarts):
  
  ESP8266 BAUD RATE: was 115200 changed to 9600
  Using Putty, Enter+Ctrl-J to submit an AT command
  
  CWMODE=1
  
  +CIFSR:STAIP,"192.168.1.38" ////IP may change
  +CIFSR:STAMAC,"18:fe:34:cb:23:ef"
  
  ESP8266 Wire Color Codes
  
  YELLOW: RX (any input needs to be pulled down to 3.3V)
  BROWN: TX (may need to be pulled up to 5 V)
  GREEN: GND
  RED,ORANGE: VCC
  
  https://www.youtube.com/watch?v=qU76yWHeQuw
  
  ARDUINO Wire Color Codes:
  
  WHITE: Arduino RX (Pin 10) (to BROWN TX on ESP8266)
  ORANGE: Arduino TX (Pin 11) + YELLOW from Voltage divider to 3.3V  (to YELLOW RX on ESP8266)
 */

#include <SoftwareSerial.h>

long rand_num1, rand_num2;

// replace with your channel's thingspeak API key
String apiKey = "4S859NATN9F06J47";
String channel_key = "CD0X6YS7DQ790J44";

//RX is digital pin 10 (connect to TX of other device)
//TX is digital pin 11 (connect to RX of other device)
// connect 10 to TX of Serial USB
// connect 11 to RX of serial USB

SoftwareSerial esp2866_Serial(10,11); //RX,TX

// this runs once
void setup() {                
  // initialize the digital pin as an output.
  //pinMode(ledPin, OUTPUT);

  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);    // turn the LED off by making the voltage LOW. No relevance except that the LED stayed on and don't know if that was a problem.

  // enable debug serial
  Serial.begin(9600); 

  // define pin modes for tx, rx:
  //pinMode(rxPin, INPUT);
  //pinMode(txPin, OUTPUT);
  // enable software serial, the baud rate depends on what the connected device supports
  esp2866_Serial.begin(9600);
  
  // reset ESP8266
  esp2866_Serial.println("AT+RST");
  
  delay(800);
  Serial.println("AT+RST");
  Serial.println(esp2866_Serial.read());
}


// the loop 
void loop() {
  //AT Commands to send data to ThingSpeak via ESP8266
  //AT+CIPSTATUS - get the connection status, 4 is not connected
  //AT+CIFSR - get IP address
  //AT+CIPSTART="TCP","184.106.153.149",80
  //AT+CIPSEND=46
  //GET /update?api_key=CD0X6YS7DQ790J44&field1=15 //Try adding HTTP/1.0 at the end
  //The value for CIPSEND is the total number of characters in the command. Count '\r' & '\n' as one character each and do not count the last \r\n sequence.
  //AT+CIPSEND=64
  //POST /update.json?api_key=CD0X6YS7DQ790J44&field1=10.5&field2=15
  //AT+CIPCLOSE - close the connection

  // TCP connection
  String cmd = "AT+CIPSTART=\"TCP\",\"184.106.153.149\",80";
  cmd += "\r\n\r\n";
  esp2866_Serial.println(cmd);

  Serial.println("Command: " + cmd);
  Serial.println("Response: " + esp2866_Serial.read());
 
  if(esp2866_Serial.find("ERROR")){
    Serial.println("AT+CIPSTART error");
    return;
  }

  // convert to string
  //char buf[16];
  //String strTemp = dtostrf(15, 4, 1, buf);
  
  // prepare GET string
  //String getStr = "GET /update?api_key=";
  //getStr += channel_key;
  //getStr +="&field1=";
  //getStr += String(strTemp);
  //getStr += String(randNumber); //Hardcoded value for now, this will be a sensor reading
  //getStr += "\r\n\r\n";
  //getStr += "HTTP/1.1\n";

  //Generate two random numbers for now, these will eventually be sensor values
  rand_num1 = random(10,20);
  rand_num2 = random(10,20);

  //length=61 bytes + 2 (for one \r and \n don't count the second set)
  String getStr = "GET /update.json?api_key=" + channel_key + "&field1=" + String(rand_num1) + "&field2=" + String(rand_num2); 
  getStr += "\r\n\r\n";
  
  //The ESP8266 needs to know the size of the GET request
  esp2866_Serial.println("AT+CIPSEND=63");
  
  Serial.println("Command: AT+CIPSEND=63");
  //esp2866_Serial.println(getStr.length());

  // send data length
  //cmd = "AT+CIPSEND=";
  //cmd += String(getStr.length());
  //cmd += "\r\n";
  //esp2866_Serial.println(cmd);
  //Serial.println(cmd);

  delay(1000);
  Serial.println("Response: " + esp2866_Serial.read()); 
  
  if(esp2866_Serial.find(">")){
    esp2866_Serial.print(getStr);
    Serial.println("Command: " + getStr);
    delay(1000);
    Serial.println("Response:" + esp2866_Serial.read());
  }
  else{
    esp2866_Serial.println("AT+CIPCLOSE");
    // alert user
    Serial.println("Command: AT+CIPCLOSE");
  }
    
  // thingspeak needs 15 sec delay between updates
  delay(16000);  
}
