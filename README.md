# FlightParameters
This project reads flight parameters from Model Aerial Vehicles and displays on them a cross-platform app.
Base version cloned from AritroMukherjee/FlightSimulatorCodes

The following files are from the original version, kept for reference only:
- ArduinoCode.ino
- ProcessingIDEcode.pde

The new files are:
- FlightParameters_v1.pde: This is the Processing sketch to display a flight instrument cluster that displays values from the sensors
- arduino-esp2866-thingspeak.ino: This is a standalone sketch that sends a series of random data values to a Test Channel on ThingSpeak via the ESP2866 Wifi breakout board. This code will need to be adapted and incorporated into other Arduino sketches that need to send data to ThingSpeak. 
