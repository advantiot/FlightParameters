//Thanks to Adrian Fernandez for the beta-version
//Modified and updated as per latest IDE by Aritro Mukherjee (April,2016)
//Check the detailed tutorial @ www.hackster.io/Aritro
// Sensor used while demonstration (MPU-6050 GY-521,6DOF)

import processing.serial.*;

/* Flags to include / exclude code snippets */

boolean TEST_MODE = false; //set to true to use test data for animation of gauge needles
boolean ARDUINO_MODE = false; //set to true to use sensor data from Arduino
boolean API_MODE = false;  //set to true to use sensor data from API (ThingSpeak)

//Values for screen layout
int view_width = 1200; //My Laptop's screen width 
int view_height = 600;  //My Laptop's screen height

int num_rows = 2;
int num_cols = 3;

int offset_x = 5;
int offset_y = 5;

int header_width = view_width - (2 * offset_x); //1200 - (2 * 5) = 1190
int header_height = 50; //fixed

int panel_width = (header_width - (2 * offset_x))/num_cols; // 1190 - (2 * 5) = 1180/3 = 393
int panel_height = (view_height-header_height - (4 * offset_y))/num_rows;

float gauge_dia=panel_width*0.6; // 393*0.6 = 236

float SpanAngle=120; 
int NumberOfScaleMajorDivisions; 
int NumberOfScaleMinorDivisions; 
PVector v1, v2; 

//Panel and Header center points. 
//Calculate the center point for each panel. Draw everything in a panel with respect to its center point
int [][] panel_center_x = new int[num_rows][num_cols]; //2 rows and 3 cols
int [][] panel_center_y = new int[num_rows][num_cols]; //2 rows and 3 cols 
int header_center_x = 0;
int header_center_y = 0;

PFont font;

//Sensor inputs
float pitch = 0; 
float attitude = 0; 
float altitude = 0;
float airspeed = 0;
float heading = 0;
float vertical_speed = 0;
float Azimuth;

Serial port;
float Phi;    //Dimensional axis
float Theta;
float Psi;

//For testing code
int draw_counter; //Used for simulating input values from an array with every draw loop reading the next value in the input array
int direction; //Used to run through the input array backwards

void settings() {
  //fullScreen();
  size(view_width, view_height);
}

void setup() 
{  
  smooth(); 
  strokeCap(SQUARE);//Optional
  
  //Set all modes to CENTER
  rectMode(CENTER);
  imageMode(CENTER);
  ellipseMode(CENTER);
  

// The font must be located in the sketch's 
// "data" directory to load successfully
  font = loadFont("Tahoma-18.vlw");
  
  //Primarily for running through test data
  draw_counter=0; //reset to zero everytime the sketch restarts
  direction = 1;
  
  if(ARDUINO_MODE){
    println(Serial.list()); //Shows your connected serial ports //-- With Arduino
    port = new Serial(this, Serial.list()[0], 115200);  //-- With Arduino
    //Up there you should select port which arduino connected and same baud rate.
    port.bufferUntil('\n'); //-- With Arduino
  }
}

/*
 * Call this method in setup() to draw the static backdrop for the panels. This will reduce the flicker during animation.
 */
void drawBackdrop(){
  background(255);
  //Draw Header Panel
  fill(0);
  //Specifying coordinates directly, without translate
  header_center_x = offset_x+header_width/2;
  header_center_y = offset_y+header_height/2;
  
  rect(header_center_x, header_center_y, header_width, header_height);
  
  //Draw panels - 2 rows x 3 cols
  for(int i=0;i<num_rows;i++){
      for(int j=0;j<num_cols;j++){
        panel_center_x[i][j] = j*panel_width+panel_width/2+(j+1)*offset_x;
        panel_center_y[i][j] = header_height+i*panel_height+panel_height/2+(i+2)*offset_y;
        ////rectMode(CENTER);
        rect(panel_center_x[i][j], panel_center_y[i][j], panel_width, panel_height);
      }
  }
  
  //Write header text (Aircraft Code Sign, Type, Date/Time, App Name and Version
  fill(255);
  textFont(font, 18);
  //Aircraft model
  text("Aircraft Type: Boeing 747", header_center_x-header_width/2.5, header_center_y);
  //Call sign
  text("Call Sign: NV1611MU", header_center_x-header_width/5, header_center_y);
  //Date and Time
  text("Date: "+ day() + "/" + month() + "/" + year() +" Time: "+ hour() + ":" + minute() + ":" +second(), header_center_x+header_width/2.75, header_center_y);
  //Field Name
  text("Field: Carson City Airfield", header_center_x, header_center_y); 
}

void draw() 
{ 
  //Consider calling all static element draw methods in setup instead of draw
  
  drawBackdrop(); //<>//
  MakeAnglesDependentOnMPU6050();  //<>//
  AirspeedIndicator(airspeed);
  AttitudeIndicator(attitude,pitch); //<>//
  Altimeter(altitude);
  ACARS();
  HeadingIndicator(heading); //<>//
  //ShowAzimuth(); //<>//
  VerticalSpeedIndicator(vertical_speed);
  
/* 
 * START: Testing code and data 
 */
  if(TEST_MODE){
    //Array of speeds to test the Airspeed Indicator
    int[] airspeed_test = {40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,74,76,76,80};
    AirspeedIndicator(airspeed_test[draw_counter]);
    //Array of attitudes to test the Attitude Indicator
    //int[] attitude_test = {5,5,4,4,3,3,2,2,1,1,0,0,-1,-1,-2,-2,-3,-3,-4,-4,-5,-5,-6,-6,-7,-7,-8,-8,-9,-9};
    //float[] attitude_test = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    float[] attitude_test = {-5,-5,-4,-3.5,-3,-2.5,-2,-1.5,-1,-1,0,1,1.5,1,1.5,2.5,2,2,2.5,3,3,3.5,3,3.5,3.5,3,2.5,2,1.5,1,0};
    float[] pitch_test = {-5,-5,-4,-3.5,-3.0,-2.5,-2.0,-1.5,-1.0,0,1,2,3,4,5,6,7,6,6,6,5,5,4,4,3,3,3,2,1,0};
    AttitudeIndicator(attitude_test[draw_counter], pitch_test[draw_counter]);
    
    //Array of headings to test the Heading Indicator
    int[] heading_test = {40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,74,76,76,80};
    HeadingIndicator(heading_test[draw_counter]);
  
    //Array of heights to test the Altimeter
    int[] altimeter_test = {200,200,200,200,400,400,400,400,600,600,600,600,800,800,11200,11250,11350,11450,11550,11650,11750,11850,11950,12250,12500,12750,13000,13100,13250,13300,13310,13320,13330,13340,13350,13360,13370};
    Altimeter(altimeter_test[draw_counter]);
    
    //Array of Vertical Speeds to test the Vertical Speed Indicator
    int[] verticalspeed_test = {1200,1250,1350,1450,1550,1650,1750,1850,1950,1250,1200,1275,1300,1310,1325,1330,1331,1332,1333,1334,1335,1336,1337,-200,-200,-200,-200,-400,-400,-400,-400,-600,-600,-600,-600,-800,-800};
    VerticalSpeedIndicator(verticalspeed_test[draw_counter]);
    
    //Increment to indicate number of draw loops, and count down when the input array length is reached
    //Input array length capped at 30 values for now
    if(direction == 1){
      if(++draw_counter > 28) direction = -1; 
    } else {
      if(--draw_counter < 2) direction = 1;
    };
  }
/* 
 * END: Testing code and data 
 */  
}
void serialEvent(Serial port) //Reading the datas by Processing.
{
  //When reading match the way the ouput is printed in the Arduino sketch.
  ////Serial output is in reverse order, note when reading in Processing. Separator is whitespace and three values end in \n
  //Print YPR as RPY
  String input = port.readStringUntil('\n');
  if(input != null){
    input = trim(input);
    String[] values = split(input, " ");
    if(values.length == 3){
      float phi = float(values[0]);
      float theta = float(values[1]); 
      float psi = float(values[2]); 
      print(phi);
      print(theta);
      println(psi);
      Phi = phi;
      Theta = theta;
      Psi = psi;
    }
  }
}
void MakeAnglesDependentOnMPU6050() 
{ 
  //attitude =-Phi/5; 
  //pitch=Theta*10; 
  //Azimuth=Psi;
  pitch = Theta; //The p value of the ypr
  attitude = Phi*10; //The p value of the ypr (amplify by 10 for better visualization
  heading = Psi; //The p value of the ypr
}

/*
 * AirspeedIndicator: Method to draw the Airspeed Indicator
 * Sits in Panel Row 1, Col 1
 */
void AirspeedIndicator(float airspeed){
  noStroke();
  //Move origin to center of first panel 
  pushMatrix(); 
  translate(panel_center_x[0][0], panel_center_y[0][0]);
  //rectMode(CENTER);
  //ellipseMode(CENTER);
  //imageMode(CENTER);
  
  /* START STATIC BACKGROUND ELEMENTS: Will not rotate */
  // Angles for sin() and cos() start at 3 o'clock;
  // subtract HALF_PI to make them start at the top
  
  //Outer ring
  fill(100); //light gray
  ellipse(0, 0, gauge_dia, gauge_dia);
  
  //Second ring which is the main dial
  fill(50); //dark gray 
  ellipse(0, 0, gauge_dia*0.9, gauge_dia*0.9);
  
  //Draw the tick marks
  /*
  rotate(PI/2+PI/3); 
  SpanAngle=300; 
  NumberOfScaleMajorDivisions=18; 
  NumberOfScaleMinorDivisions=36;  
  CircularScale(gauge_dia*0.7); //Upper circular scale 
  rotate(-PI/2-PI/3); //Reset upper scale marking rotation.
  */
  
  CircularScale_new(gauge_dia*0.85, 30, 330, 19, 3); //Major scale
  CircularScale_new(gauge_dia*0.85, 30, 330, 38, 2); //Minor scale
  
  //Draw the range indicator arcs
  //70-120: white, 80-140: green, 140-160: yellow, 160-220: red
  noFill();
  strokeWeight(5);
  stroke(255); //white
  arc(0, 0, gauge_dia*0.75, gauge_dia*0.75, -PI/6, HALF_PI+PI/6);  
  stroke(18,135,85); //green
  arc(0, 0, gauge_dia*0.85, gauge_dia*0.85, HALF_PI, PI-PI/6);
  stroke(255,242,0); //yellow
  arc(0, 0, gauge_dia*0.85, gauge_dia*0.85, PI-PI/6, PI);
  stroke(239,41,61); //red
  //arc(0, 0, gauge_dia*0.85, gauge_dia*0.85, PI, PI+PI/3);
  arc(0, 0, gauge_dia*0.85, gauge_dia*0.85, radians(180), radians(240));
  
  //Draw the numbers from 40 to 220
  /*(
  fill(255); //text needs fill
  textSize(15);
  float count = -3.5;
  float angle;
  for(int i=min_scale_value;i<=max_scale_value;i=i+20){
      angle = count*SpanAngle/NumberOfScaleMajorDivisions; 
      //text(""+i, gauge_dia*0.6/2*cos(radians(angle)),gauge_dia*0.6/2*sin(radians(angle)));
      count+=2;
  }
  */
  
  //Draw the numbers from 40 to 220
  NumericLabels(gauge_dia*0.55, 30, 330, 40, 220, 20);
  
  //Draw the units name
  text("MPH", 0,gauge_dia*0.3/2);
  
  /* END STATIC BACKGROUND ELEMENTS: Will not rotate */
  
  /* START MOVING ELEMENTS: Will rotate */
  //Draw the needle
  //Limit the input from 40 to 220
  if(airspeed < 40) airspeed = 40;
    if(airspeed > 220) airspeed = 220;
  
  float scaled_airspeed = map(airspeed, 40, 220, 30, 330); //Mapping the airspeed range to the degrees the values span on the gauge
  
  rotate(radians(scaled_airspeed));
  noStroke();
  fill(255);
  triangle(-5, 0, 5, 0, 0, -gauge_dia*0.8/2);
  /* END MOVING ELEMENTS: Will rotate */
  rotate(-radians(scaled_airspeed));
    
  popMatrix();
}

/*
 * AttitudeIndicator: Method to draw the Attitude Indicator
 * Sits in Panel Row 1, Col 2
 */
void AttitudeIndicator(float attitude, float pitch) 
{ 
  noStroke();
  //Move origin to center of second panel
  //For each panel keep the origin at the center of the panel while drawing within the panel. Push and Pop tranlations as required within the panel.
  //Finally pop the translation to the center of the panel back the the default so subsequent panel drawing translations are from the default origin. 
  pushMatrix(); 
  translate(panel_center_x[0][1], panel_center_y[0][1]);
  ////rectMode(CENTER);
  ////imageMode(CENTER);
  ////ellipseMode(CENTER);
  
  fill(0, 180, 255); //sky blue
  //sky blue rectangle, entire background
  //rect(0, 0, panel_width*0.8, panel_height);
  //Draw a circle for the sky and a semicircle for the earth to create a circular gauge
  ellipse(0, 0, panel_width*0.625, panel_width*0.625); 
 
  fill(95, 55, 40); //earth brown  
  //rotates the entire image, so indicator needs to be counter-rotated so only background appears to rotate
  //Move origin down a quarter panel height and draw earth recatangle to fill bottom half of panel (need since we are in //rectMode(CENTER)
  //pushMatrix();
  //translate(0,panel_height/4);
  //earth brown semi-circle, lower half. Pitch reduces or increases the height of the semi-circle to simulate, well, Pitch (nose up/down)
  rotate(-radians(attitude));
  //rect(0, 0, panel_width*0.8, panel_height/2+pitch);
  arc(0, 0, panel_width*0.625, panel_width*0.625, 0-radians(pitch), PI+radians(pitch), OPEN);
  rotate(radians(attitude)); //Counter rotate so the markings and indicator are normal and only background appears rotated, simulating the bank
  //popMatrix();
  //translate(0,-panel_height/4); // move origin back to center of panel
  
  //Parts on the AttitudeIndicator
  PitchScale(); 
  Axis(); 
  Plane();
  
  /* START STATIC BACKGROUND ELEMENTS: Will not rotate */  
  //rotate(-PI-PI/6); 
  //SpanAngle=120; 
  //NumberOfScaleMajorDivisions=12; 
  //NumberOfScaleMinorDivisions=24;  
  //CircularScale(gauge_dia*0.85); //Upper circular scale
  //rotate(PI+PI/6); //Reset upper scale marking rotation. 
  //rotate(-PI/6); //This is to draw the lower scale markings at a rotated point.
  //CircularScale(gauge_dia*0.85); //Lower circular scale
  CircularScale_new(gauge_dia, 300, 60, 40, 2); //Upper circular scale
  CircularScale_new(gauge_dia, 120, 240, 40, 2); //Lower circular scale
  //rotate(PI/6); //Reset lower scale marking rotation. 

  /* END STATIC BACKGROUND ELEMENTS: Will not rotate */
  popMatrix();
}
void ShowAzimuth() 
{ 
  fill(50); 
  noStroke(); 
  rect(20, 470, 440, 50); 
  int Azimuth1=round(Azimuth); 
  textAlign(CORNER); 
  textSize(35); 
  fill(255); 
  text("Azimuth:  "+Azimuth1+" Deg", 80, 477, 500, 60); 
  textSize(40);
  fill(25,25,150);
  text("FLIGHT SIMULATOR", -350, 477, 500, 60); 
}

void Plane() 
{ 
  fill(0); 
  strokeWeight(1); 
  stroke(0, 255, 0); 
  triangle(-10, 0, 10, 0, 0, 10); 
  rect(45, 0, 60, 10); 
  rect(-45, 0, 60, 10); 
}

void Axis() 
{ 
  //One vertical and one horiontal line red in color
  stroke(255, 0, 0); 
  strokeWeight(3); 
  line(-30, 0, 30, 0); 
  line(0, gauge_dia/2*0.85, 0, -gauge_dia/2*0.85); 
  fill(100, 255, 100); 
  stroke(0); 
  //triangle(0, -285, -10, -255, 10, -255);
  triangle(0, -gauge_dia/2*0.85, -10, -gauge_dia/2*0.85+10, 10, -gauge_dia/2*0.85+10);
  //triangle(0, 285, -10, 255, 10, 255); 
  triangle(0, gauge_dia/2*0.85, -10, gauge_dia/2*0.85-10, 10, gauge_dia/2*0.85-10);
}

void PitchScale() 
{  
  stroke(255); 
  fill(255); 
  strokeWeight(3); 
  textSize(12); 
  textAlign(CENTER); 
  for (int i=-4;i<5;i++) 
  {  
    if ((i==0)==false) 
    { 
      line(30, 20*i, -30, 20*i); 
      text(""+i*10, 50, 20*i+5, 100, 30); 
      text(""+i*10, -50, 20*i+5, 100, 30);
    }
  } 
  textAlign(CORNER); 
  strokeWeight(2); 
  for (int i=-9;i<10;i++) 
  {  
    if ((i==0)==false) 
    {    
      line(10, 10*i, -10, 10*i); 
    } 
  } 
}

/*
 * Altimeter: Method to draw the Altimeter
 * Sits in Panel Row 1, Col 3
 */
void Altimeter(float altitude){
  noStroke();
  //Move origin to center of third panel 
  pushMatrix(); 
  translate(panel_center_x[0][2], panel_center_y[0][2]);
  //rectMode(CENTER);
  //ellipseMode(CENTER);
  //imageMode(CENTER);
  
  /* START STATIC BACKGROUND ELEMENTS: Will not rotate */
  // Angles for sin() and cos() start at 3 o'clock;
  // subtract HALF_PI to make them start at the top
  
  //Outer ring
  fill(100); //light gray
  ellipse(0, 0, gauge_dia, gauge_dia);
  
  //Second ring which is the main dial
  fill(50); //dark gray 
  ellipse(0, 0, gauge_dia*0.9, gauge_dia*0.9);
  
  //Draw the tick marks
  //rotate(-PI/2); 
  SpanAngle=360; 
  NumberOfScaleMajorDivisions=10; 
  NumberOfScaleMinorDivisions=50;  
  //CircularScale(gauge_dia*0.7); //Upper circular scale
  //CircularScale_new(gauge_dia*0.85, 0, 360, 11, 3); //Major scale
  //CircularScale_new(gauge_dia*0.85, 0, 360, 52, 2); //Minor scale
  
  CircularScale_new(gauge_dia*0.85, 0, 360, 10, 3); //Major scale
  CircularScale_new(gauge_dia*0.85, 0, 360, 50, 2); //Minor scale
  
  //rotate(PI/2); //Reset upper scale marking rotation.
  
  //Draw the numbers from 0 to 9
  NumericLabels(gauge_dia*0.6, 0, 324, 0, 9, 1);
  
  //fill(255); //text needs fill
  //textSize(15);
  //float start_angle=-90;
  //float angle;
  
  //for(int i=min_scale_value;i<=max_scale_value;i++){
      //angle = start_angle + (SpanAngle/NumberOfScaleMajorDivisions)*i;
      //text(""+i, gauge_dia*0.7/2*cos(radians(angle)),gauge_dia*0.6/2*sin(radians(angle)));
  //}

  //Draw the units name
  text("FEET", 0,gauge_dia*0.3/2);
  
  /* END STATIC BACKGROUND ELEMENTS: Will not rotate */
  
  /* START MOVING ELEMENTS: Will rotate */
  //Each needle will have to be rotated separately
  //First extract the 10,000 feet, 1000 feet and 100 feet multipliers
  int tenthoufeet = (int) altitude/10000;
  int thoufeet = (int) (altitude-(tenthoufeet*10000))/1000; //subtract the 10,000 feet value to get the thousands
  int hundfeet = (int) (altitude-(tenthoufeet*10000)-(thoufeet*1000))/100; //subtract the 10,000 and 1000feet values to get the hundreds
  int tenfeet = (int) (altitude-(tenthoufeet*10000)-(thoufeet*1000)-(hundfeet*100)); //subtract the 10,000 and 1000feet values to get the hundreds
  
  //And then map each value to the scale
  float scaled_tenthoufeet = map(tenthoufeet, 0, 10, 0, 360); //Mapping the airspeed range to the degrees the values span on the gauge
  float scaled_thoufeet = map(thoufeet, 0, 10, 0, 360); //Mapping the airspeed range to the degrees the values span on the gauge
  float scaled_hundfeet = map(hundfeet, 0, 10, 0, 360); //Mapping the airspeed range to the degrees the values span on the gauge
  
  //Display the tens of feet as text
  noStroke();
  fill(100);
  rect(gauge_dia*0.6/2, 0, 20, 15);
  fill(255); //text needs fill
  textSize(12);
  textAlign(CENTER, TOP);
  text(""+tenfeet, gauge_dia*0.6/2, -6);
  
  //Draw the needles, different shapes and individual rotation
  
  //10,000 feet needle - short shape
  rotate(radians(scaled_tenthoufeet));
  noStroke();
  fill(255);
  PShape tenthoufeet_needle;  // The PShape object  
  tenthoufeet_needle = createShape();
  tenthoufeet_needle.beginShape();
  tenthoufeet_needle.fill(255,165,0);
  tenthoufeet_needle.noStroke();
  tenthoufeet_needle.vertex(-5, 0);
  tenthoufeet_needle.vertex(5, 0);
  tenthoufeet_needle.vertex(8, -gauge_dia*0.8/4);
  tenthoufeet_needle.vertex(0, -gauge_dia*0.8/3);
  tenthoufeet_needle.vertex(-8, -gauge_dia*0.8/4);
  tenthoufeet_needle.vertex(-5, 0);
  
  tenthoufeet_needle.endShape(CLOSE);
  shape(tenthoufeet_needle, 0, 0);
  rotate(-radians(scaled_tenthoufeet));
  
  //1000 feet needle, long rectangle with triange tip
  rotate(radians(scaled_thoufeet));
  noStroke();
  fill(255);
  triangle(-5, 0, 5, 0, 0, -gauge_dia*0.8/2);
  rotate(-radians(scaled_thoufeet));

  //100 feet needle, longest, a thin rectangle with an inverted triangle at the tip
  rotate(radians(scaled_hundfeet));
  stroke(255);
  strokeWeight(2);
  line(0, 0, 0, -gauge_dia/2*0.75);
  noStroke();
  fill(255);
  triangle(0, -gauge_dia/2*0.75, -10, -(gauge_dia/2*0.75)-10, 10, -(gauge_dia/2*0.75)-10); //inverted triangle at tip
  rotate(-radians(scaled_hundfeet));
  /* END MOVING ELEMENTS: Will rotate */
  
  popMatrix();
}

/*
 * ACARS: Method to draw the ACARS Panel
 * Sits in Panel Row 2, Col 1
 */
void ACARS(){
  //Move origin to center of panel
  pushMatrix(); 
  translate(panel_center_x[1][0], panel_center_y[1][0]);
  rectMode(CORNER); //For ACARS only, reset at the end
  
  //Heading
  fill(255); //white
  textFont(font, 18);
  text("ACARS", 0, -0.9*panel_height/2);
  
  float left_col_offset = -0.9*panel_width/2; //minus
  float right_col_offset = 0.9*panel_width/2; //plus
  float leading_space = 20;
  float line_offset = -0.7*panel_height/2;

  //Left align left column
  textAlign(LEFT);
  
  //Line 1
  fill(255);
  textFont(font, 14);
  //First line so no leading space
  text("FLT SEQ", left_col_offset, line_offset);
  //Line 2
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("04/06", left_col_offset, line_offset); //FLT NO
  
  //Line 3
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("DATE", left_col_offset, line_offset);
  //Line 4
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("11AUG16", left_col_offset, line_offset); //DATE
  
  //Line 5
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("ETD/ATD", left_col_offset, line_offset);
  //Line 6
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("10:00/10:00", left_col_offset, line_offset); //START
  
  //Line 5
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("ETA/ATA", left_col_offset, line_offset);
  //Line 6
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("10:15/10:12", left_col_offset, line_offset); //END
  
  //Line 7
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("NOTAM", left_col_offset, line_offset);
  //Line 8
  fill(255,0,0); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("All flights to land immediately.", left_col_offset, line_offset); //END
  
  //Right align right column
  textAlign(RIGHT);
  
  line_offset = -0.7*panel_height/2; //reset line_offset for right column
  
  //Line 1
  fill(255);
  textFont(font, 14);
  //First line so no leading space
  text("FREQ", right_col_offset, line_offset);
  //Line 2
  fill(26, 182, 99); //green
  textFont(font, 18);
  line_offset += leading_space;
  text("72Mhz[OK]", right_col_offset, line_offset); //red if there is a conflict with any other flyer
  
  //Line 3
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("FUEL QTY", right_col_offset, line_offset);
  //Line 4
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("[  ] cc", right_col_offset, line_offset);
  
  //Line 5
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("WEIGHT", right_col_offset, line_offset);
  //Line 6
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("[  ] lbs", right_col_offset, line_offset);
  
  //Line 7
  fill(255);
  textFont(font, 14);
  line_offset += leading_space;
  text("WIND DIR", right_col_offset, line_offset);
  //Line 8
  fill(54, 161, 255); //blue
  textFont(font, 18);
  line_offset += leading_space;
  text("NE Mild", right_col_offset, line_offset);
  
  //reset all modes, rotations and translations
  rectMode(CENTER);
  popMatrix();
}

/*
 * HeadingIndicator: Method to draw the Heading Indicator
 * Sits in Panel Row 2, Col 2
 */
void HeadingIndicator(float heading) 
{ 
  noStroke();
  pushMatrix();
  //Move origin to center of panel
  translate(panel_center_x[1][1], panel_center_y[1][1]);
  //rectMode(CENTER);
  //ellipseMode(CENTER);
  //imageMode(CENTER);
  
/*
 * START HEADING ELEMENTS: All elements below will rotate to indicate heading
 */
  rotate(radians(heading));
  //Outer ring, with direction letters
  fill(100); //light gray
  ellipse(0, 0, gauge_dia, gauge_dia);
  
  //Second from outer ring, with tick marks
  fill(75); //dark gray 
  ellipse(0, 0, gauge_dia*0.8, gauge_dia*0.8);
  
  strokeWeight(20); 
  NumberOfScaleMajorDivisions=18; 
  NumberOfScaleMinorDivisions=36;  
  SpanAngle=180; 
  //CircularScale(gauge_dia*0.625);
  CircularScale_new(gauge_dia*0.775, 0, 360, 8, 3); //scale_dia = 236*0.775 = 183
  CircularScale_new(gauge_dia*0.775, 0, 360, 40, 2); //scale_dia = 236*0.775 = 183
  rotate(PI); 
  SpanAngle=180; 
  //CircularScale(gauge_dia*0.625); 
  rotate(-PI); 
  fill(255); 
  textSize(20); 
  textAlign(CENTER); 
  text("W", -gauge_dia/2*0.9, 0); 
  text("E", gauge_dia/2*0.9, 0); 
  text("N", 0, -gauge_dia/2*0.85); 
  text("S", 0, gauge_dia/2*0.95); 
  rotate(PI/4); 
  textSize(15); 
  text("NW", -gauge_dia/2*0.9, 0); 
  text("SE", gauge_dia/2*0.9, 0); 
  text("NE", 0, -gauge_dia/2*0.85); 
  text("SW", 0, gauge_dia/2*0.95);  
  rotate(-PI/4);
  
  //Draw an orange line from center to North
  stroke(255,165,0);
  line(0, 0, 0, -gauge_dia/2*0.775);
  
  //Inner circle
  noStroke();
  fill(0, 180, 255); //sky blue
  ellipse(0, 0, gauge_dia*0.6, gauge_dia*0.6);

  //Draw the wind direction needle
  WindDirection(45);
  
  rotate(-radians(heading));
/*
 * END HEADING ELEMENTS: All elements above will rotate to indicate heading
 */

  /* START STATIC BACKGROUND ELEMENTS: Will not rotate */
  PImage img;
  img = loadImage("airplane_icon_orange.png");
  image(img, 0, 0, gauge_dia*0.4, gauge_dia*0.4);
  /* END STATIC BACKGROUND ELEMENTS: Will not rotate */
  popMatrix(); //Reset origin to default
}

/*
 * WindDirection: Method to draw the wind direction needle inside the Heading Indicator
 * Sits in Panel Row 2, Col 2 Called inside the Heading Indicator so already translated, not required again
 */
void WindDirection(float wind_direction) 
{ 

/*
 * The wind direction indicator will also rotate along with the background
 */
  rotate(radians(wind_direction));
  
  //Draw the wind direction needle
  stroke(0, 0, 255); 
  strokeWeight(3);  
  line(0, gauge_dia/2*0.55, 0, -gauge_dia/2*0.5); 
  fill(0, 0, 255); 
  noStroke(); 
  triangle(0, -gauge_dia/2*0.55, -10, -gauge_dia/2*0.55+10, 10, -gauge_dia/2*0.55+10);
  
  rotate(-radians(wind_direction));
/*
 * END Wind Direction
 */
}

/*
 * VerticalSpeedIndicator: Method to draw the Vertical Speed Indicator
 * Sits in Panel Row 2, Col 3
 */
void VerticalSpeedIndicator(float vertical_speed){
  noStroke();
  //Move origin to center of panel row 2, col 3 
  pushMatrix(); 
  translate(panel_center_x[1][2], panel_center_y[1][2]);
  
  /* START STATIC BACKGROUND ELEMENTS: Will not rotate */
  // Angles for sin() and cos() start at 3 o'clock;
  // subtract HALF_PI to make them start at the top
  
  //Outer ring
  fill(100); //light gray
  ellipse(0, 0, gauge_dia, gauge_dia);
  
  //Second ring which is the main dial
  fill(50); //dark gray 
  ellipse(0, 0, gauge_dia*0.9, gauge_dia*0.9);
  
  //Draw the tick marks for the Climb (upper) scale
  /*
  rotate(-PI/2); 
  SpanAngle=180; 
  NumberOfScaleMajorDivisions=6; 
  NumberOfScaleMinorDivisions=30;  
  CircularScale(gauge_dia*0.7); //Upper circular scale 
  rotate(PI/2); //Reset upper scale marking rotation.
  */
  
  CircularScale_new(gauge_dia*0.85, 270, 90, 6, 3); //Upper scale
  CircularScale_new(gauge_dia*0.85, 90, 270, 6, 3); //Lower scale
  
  //Draw minor ticks between 0 and 1
  CircularScale_new(gauge_dia*0.85, 240, 300, 21, 2); //Upper scale
  
  //Draw the numbers from 1 to 6
  //The gauge diameters for upper and lowerneed to be slightly different. Possibly because they run different arcs lengths
  NumericLabels(gauge_dia*0.6, 270, 90, 0, 6, 1); //Upper scale 
  NumericLabels(gauge_dia*0.6, 90, 270, 6, 0, -1); //Lower scale
  
  //Draw the tick marks for the Descend (lower) scale
  rotate(PI/2); 
  SpanAngle=180; 
  NumberOfScaleMajorDivisions=6; 
  NumberOfScaleMinorDivisions=30;  
  //CircularScale(gauge_dia*0.7); //Upper circular scale 
  rotate(-PI/2); //Reset upper scale marking rotation.
  
  //Draw the numbers from 0 to 6 for the Climb (upper) scale
  /*
  fill(255); //text needs fill
  textSize(15);
  float start_angle=-180;
  float angle;
  for(int i=min_scale_value;i<=max_scale_value;i++){
      angle = start_angle + (SpanAngle/NumberOfScaleMajorDivisions)*i;
      text(""+i, gauge_dia*0.6/2*cos(radians(angle)),gauge_dia*0.6/2*sin(radians(angle)));
  }
  //Draw the numbers from 1 to 5 for the Descend (lower) scale (0 and 6 have already been drawn)
  start_angle=-180;
  for(int i=min_scale_value+1;i<=max_scale_value-1;i++){
      angle = start_angle - (SpanAngle/NumberOfScaleMajorDivisions)*i;
      text(""+i, gauge_dia*0.6/2*cos(radians(angle)),gauge_dia*0.6/2*sin(radians(angle)));
  }
  */
  //Draw the units name
  text("x100", 0,gauge_dia*0.1/2);
  text("FEET/MIN", 0,gauge_dia*0.3/2);
  
  //Draw the UP/DN text
  textSize(12);
  text("UP", -gauge_dia*0.75/2*cos(radians(45)),-gauge_dia*0.75/2*sin(radians(45)));
  text("DN", -gauge_dia*0.75/2*cos(radians(45)),gauge_dia*0.75/2*sin(radians(45)));
  
  
  /* END STATIC BACKGROUND ELEMENTS: Will not rotate */
  
  /* START MOVING ELEMENTS: Will rotate */
  //And then map each value to the scale. Since this is a dual scale for +ve and -ve values, conditional mapping required
  float scaled_vertical_speed=0;
  
  if(vertical_speed >= 0){
    if(vertical_speed > 6000) vertical_speed = 6000; //limit to +6000 feet/minute (climb)
    scaled_vertical_speed = map(vertical_speed, 0, 6000, -90, 90); //Mapping the airspeed range to the degrees the values span on the gauge
  }
  if(vertical_speed < 0){
    if(vertical_speed < -6000) vertical_speed = -6000; //limit to -6000 feet/minute (descent)
    scaled_vertical_speed = map(vertical_speed, -6000, 0, 90, 270); //Mapping the airspeed range to the degrees the values span on the gauge
  }
  
  //Needle, long rectangle with triange tip
  rotate(radians(scaled_vertical_speed));
  noStroke();
  fill(255);
  triangle(-5, 0, 5, 0, 0, -gauge_dia*0.8/2);
  rotate(-radians(scaled_vertical_speed));

  /* END MOVING ELEMENTS: Will rotate */
  
  popMatrix();
}

/*
 * Circular Scale: Generic method to draw circular tick marks. This will have to be called for major and minor ticks marks separately. A third length is also possible.
 * Accepts the following parameters (all float types for accuracy rounding skews the drawing):
 * scale_dia: The diameter of the virtual circle along which the tick marks will be drawn, inward from the circumference.
 * start_angle: The angle in degrees from which the ticks marks will be drawn (any value between 0 and 360). 0 is by default 3 o'clock but will be rotated to be 12 o'clock
 * end_angle: The angle in degrees to which the ticks marks will be drawn (any value between 0 and 360). 
 * num_ticks: The number of tick marks to be drawn, including first and last. First one will be at start angle and the last one will be at the end_angle. Min 2, Max 360.
 * tick_size: 1=short, 2=medium, 3=large (always draw tick marks from small to large)
 * 
 * Notes: IF any parameters are incorrect the following defaults will be assumed:
 * start_angle = 0, end_angle = 359, num_ticks = 360, tick_size = 2
 */
 
void CircularScale_new(float scale_dia, float start_angle, float end_angle, float num_ticks, int tick_size) 
{ 
  float StrokeWidth=1; 
  strokeWeight(StrokeWidth); 
  stroke(255);
  
  //test line
  //line(0,0,scale_dia,scale_dia);
  
  float gap_angle=0, current_angle=0;
  float inner_x, inner_y, outer_x, outer_y; //Draw the tick mark as a line between these two points calculated using the scale diameter and angle  
  float outer_inner_diff=0; //this is the tick length
  
  //Check for valid inputs or set defaults
  if(start_angle < 0) start_angle = 0;
  if(start_angle > 360) start_angle = 360;
  if(end_angle < 0) start_angle = 0;
  if(end_angle > 360) start_angle = 360;
  if(num_ticks < 2) num_ticks = 2;
  if(num_ticks > 360) num_ticks = 360;
  if(tick_size != 1 && tick_size != 2 && tick_size != 3) tick_size = 2;
  
  //Set a outer_inner_diff as a percentage of the scale diameter (depending on the tick_size parameter 1=short, 2=medium and 3=long values) 
  //The tick length is the difference between inner and outer length
  
  if(tick_size == 1){ //short
    outer_inner_diff = scale_dia/30;
  }
  else if(tick_size == 2){ //medium
    outer_inner_diff = scale_dia/20;
  }
  if(tick_size == 3){ //long
    outer_inner_diff = scale_dia/10;
  }
  
  if(end_angle > start_angle){ //for example 90 to 180 (6 to 9 o'clock on a clock face)
    gap_angle = (end_angle - start_angle)/num_ticks; //first and last tick will be at the start and end angles
  }
  else{ //for example 180 to 90  (9 to 6 o'clock on a clock face)
    //gap_angle = 360 - (start_angle - end_angle)/(num_ticks-1);
    gap_angle = (360 - (start_angle - end_angle))/num_ticks;
  }

  //0 is by default 3 o'clock so rotate such that it is 12 o'clock
  rotate(-PI/2);
  
  for (float tick_count=0;tick_count<num_ticks;tick_count++) 
  { 
    current_angle = start_angle + gap_angle*tick_count;
    
    //If current_angle > 360 subtract 360 ( the angle crosses the 0 degree mark, usually when end_angle less than start_angle)
    if(current_angle >360) current_angle -= 360;
    
    inner_x = (scale_dia/2 - outer_inner_diff) * cos(radians(current_angle));
    inner_y = (scale_dia/2 - outer_inner_diff) * sin(radians(current_angle));
    outer_x = scale_dia/2 * cos(radians(current_angle));
    outer_y = scale_dia/2 * sin(radians(current_angle));
    //Draw tick mark
    line(inner_x, inner_y, outer_x, outer_y);
  }
  //Cancel rotation
  rotate(PI/2);
}

void NumericLabels(float scale_dia, int start_angle, int end_angle, int min_value, int max_value, int increment) 
{ 
  fill(255);
  textSize(15);
  
  float gap_angle=0, current_angle=0;
  float x, y; //label coordinates
  int [] labels = new int[360]; //Max labels unlikely to exceed 360. Check for dynamic array options
  int label_count=0;
  
  //Determine label values and count based on min, max and increment values
  if(increment > 0){ //positive increment, max greater than min
    for(int i=min_value; i<=max_value; i=i+increment){
      labels[label_count] = i;
      label_count++;
    }
  }
  if(increment < 0){ //negative increment, max less than min
    for(int i=min_value; i>=max_value; i=i+increment){
      labels[label_count] = i;
      label_count++;
    }
  }
  
  //Check for valid inputs or set defaults
  if(start_angle < 0) start_angle = 0;
  if(start_angle > 360) start_angle = 360;
  if(end_angle < 0) start_angle = 0;
  if(end_angle > 360) start_angle = 360;
  
  if(end_angle > start_angle){ //for example 90 to 180 (6 to 9 o'clock on a clock face)
    gap_angle = (end_angle - start_angle)/(label_count-1);   
  }
  else{ //for example 180 to 90  (9 to 6 o'clock on a clock face)
    gap_angle = (360 - (start_angle - end_angle))/(label_count-1);
  }

  //0 is by default 3 o'clock so rotate such that it is 12 o'clock
  //However, rotate does not work as it rotates the text as well. So offset the angle values by -PI/2
  
  for (int i=0; i<label_count; i++) 
  { 
    current_angle = start_angle + gap_angle*i; //in degrees
    
    //If current_angle > 360 subtract 360 ( the angle crosses the 0 degree mark, usually when end_angle less than start_angle)
    if(current_angle >360) current_angle -= 360;
    
    x = scale_dia/2 * cos(radians(current_angle) - PI/2);
    y = scale_dia/2 * sin(radians(current_angle) - PI/2);
    //Draw label
    textAlign(CENTER, CENTER);
    text(""+labels[i], x,   y);
  }
}

void CircularScale(float scale_dia) 
{   
  float StrokeWidth=1; 
  float an;
  
  float DivxPhasorCloser; 
  float DivxPhasorDistal; 
  float DivyPhasorCloser; 
  float DivyPhasorDistal; 
  strokeWeight(StrokeWidth); 
  stroke(255);
  float DivCloserPhasorLength=scale_dia*0.7-scale_dia/9-StrokeWidth; //This is an arbitrary calculation to get the length of the radial line 
  float DivDistalPhasorLength=scale_dia*0.7-scale_dia/6.5-StrokeWidth; //The dividends (9 and 7.5) to get a difference bwteen the two radial lines whick is the tick mark
  for (int Division=0;Division<NumberOfScaleMinorDivisions+1;Division++) 
  { 
    an=SpanAngle/2+Division*SpanAngle/NumberOfScaleMinorDivisions;  
    DivxPhasorCloser=DivCloserPhasorLength*cos(radians(an)); 
    DivxPhasorDistal=DivDistalPhasorLength*cos(radians(an)); 
    DivyPhasorCloser=DivCloserPhasorLength*sin(radians(an)); 
    DivyPhasorDistal=DivDistalPhasorLength*sin(radians(an));   
    line(DivxPhasorCloser, DivyPhasorCloser, DivxPhasorDistal, DivyPhasorDistal); 
  }
  DivCloserPhasorLength=scale_dia*0.7-scale_dia/10-StrokeWidth; 
  DivDistalPhasorLength=scale_dia*0.7-scale_dia/6.4-StrokeWidth;
  for (int Division=0;Division<NumberOfScaleMajorDivisions+1;Division++) 
  { 
    an=SpanAngle/2+Division*SpanAngle/NumberOfScaleMajorDivisions;  
    DivxPhasorCloser=DivCloserPhasorLength*cos(radians(an)); 
    DivxPhasorDistal=DivDistalPhasorLength*cos(radians(an)); 
    DivyPhasorCloser=DivCloserPhasorLength*sin(radians(an)); 
    DivyPhasorDistal=DivDistalPhasorLength*sin(radians(an)); 
    if (Division==NumberOfScaleMajorDivisions/2|Division==0|Division==NumberOfScaleMajorDivisions) 
    { 
      strokeWeight(8); 
      stroke(0); 
      line(DivxPhasorCloser, DivyPhasorCloser, DivxPhasorDistal, DivyPhasorDistal); 
      strokeWeight(4); 
      stroke(100, 255, 100); 
      line(DivxPhasorCloser, DivyPhasorCloser, DivxPhasorDistal, DivyPhasorDistal); 
    } 
    else 
    { 
      strokeWeight(1); 
      stroke(255); 
      line(DivxPhasorCloser, DivyPhasorCloser, DivxPhasorDistal, DivyPhasorDistal); 
    } 
  } 
}