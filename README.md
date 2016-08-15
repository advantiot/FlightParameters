# FlightParameters
This project reads flight parameters from Model Aerial Vehicles and displays on them a cross-platform app.
Base version cloned from AritroMukherjee/FlightSimulatorCodes

The project includes Arduino and Processing sketch (code) files in their respective directories:
- FlightParameters.pde: This is the Processing sketch to display a flight instrument cluster that displays values from the sensors
- MPU6050_DMP6_SensorInput.ino: This is the Arduino code to read the flight motion sensors.
- arduino-esp2866-thingspeak.ino: This is a standalone sketch that sends a series of random data values to a Test Channel on ThingSpeak via the ESP2866 Wifi breakout board. This code will need to be adapted and incorporated into other Arduino sketches that need to send data to ThingSpeak. 
