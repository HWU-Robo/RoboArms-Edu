#include <Servo.h>

const int BAUD = 1200;

uint8_t rd_pins[] = {A0, A1, A2, A3, A4, A5, A6};
uint8_t servo_ctrl_pins[] = {3, 4, 6, 7, 8, 0};         //TODO - make this progression linear
Servo servos[] = {  Servo(), Servo(), Servo(), 
                    Servo(), Servo(), Servo()   };
// long joint_angles[] = {0, 0, 0, 0, 0, 0};
long joint_angles[] = {0, 140, 160, 90, 40, 10};               //will assign values to angles before we write ctrl signals
uint8_t servo_count = 2;                              //will use 6 in later versions using the RoboArm

void assign_pins(Servo joint_servos[], uint8_t ctrl_pins[], uint8_t pin_count, long angles[]);
void rd_angles(uint8_t read_pins[], uint8_t pin_count, long angles[]);
void wr_angles(Servo joint_servos[], uint8_t pin_count, long angles[]);
void print_angles(uint8_t pin_count, long angles[]);

// the setup routine runs once when you press reset:
void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(BAUD);
  // assign_pins(servos, servo_ctrl_pins, servo_count, joint_angles);
  assign_pins(servos, servo_ctrl_pins, 6, joint_angles);
}

// the loop routine runs over and over again forever:
void loop() {
  rd_angles(rd_pins, servo_count, joint_angles);
  print_angles(servo_count, joint_angles);
  wr_angles(servos, servo_count, joint_angles);
}

void assign_pins(Servo joint_servos[], uint8_t ctrl_pins[], uint8_t pin_count, long angles[])
{
  //Assign pins & set servo angles to home position
  for (int8_t idx = 0; idx < pin_count; idx++)
  {
    //set read pins
    pinMode(rd_pins[idx], INPUT);

    // pinMode(ctrl_pins[idx], OUTPUT);
    // Set default servo angles
    joint_servos[idx].write(angles[idx]);
    // Assign servo ctrl pins
    joint_servos[idx].attach(servo_ctrl_pins[idx]);
  }
}

void print_angles(uint8_t pin_count, long angles[])
{
  for (int8_t idx = 0; idx < pin_count; idx++)
  {
    Serial.print(angles[idx]);
    Serial.print(" \t ");
  }
  Serial.println();
}

void wr_angles(Servo joint_servos[], uint8_t pin_count, long angles[])
{
  //TODO - send ctrl signals to joint servos
  for (int8_t idx = 0; idx < pin_count; idx++)
  {
    joint_servos[idx].write(angles[idx]);
  }
}

void rd_angles(uint8_t read_pins[], uint8_t pin_count, long angles[])
{
  //collect readings from all sensors (in o.g. version, they're pots)
  //...and, convert readings to ctrl angles for joint ctrl
  for (int8_t idx = 0; idx < pin_count; idx++)
  {
    int sensorValue = analogRead(read_pins[idx]);
    joint_angles[idx] = map(sensorValue, 0, 1023, 0, 180);
  }
}
