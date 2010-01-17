/*

Arduino Turntable - An Arduino sketch that allows input from a hard drive spindle.
Copyright (C) 2010 George Caley.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

/*
The hard drive motor I chose to use was from an old Seagate hard drive.
While most hard drive motors have four pins, this one had three.
I'm sure it wouldn't be too difficult to modify the project to use a four-pin
motor however.

One of the pins from the motor goes into +5V, and the other two go into
analog pins 0 and 1.
There's only 6 possible arrangements, so upload the sketch to your board and
keep changing the pin configuration until you get some valid data from the
serial port.
*/

// Turntable Pins
int turntableOne = 0;
int turntableTwo = 1;

// Stores whether the turntable is spinning
int spinning = 0;

// Stores the analog values from the two turntable pins
int valA = 0;
int valB = 0;

// Stores the digital values
int digA = 0;
int digB = 0;

// Stores the last four 'patterns'
int prevPatterns[4] = {0, 0, 0, 0};

// Stores the current 'pattern'
int currPattern = 0;

void setup() {
  Serial.begin(9600);
}

void loop() {
  // Read in the analog values of the turntable pins...
  valA = 1023 - analogRead(turntableOne);
  valB = 1023 - analogRead(turntableTwo);
  
  // ...and convert them to digital.
  digA = toDigital(valA);
  digB = toDigital(valB);
  
  /*
  Each state of the turntable can be read as a 'pattern'.
  We refer to the two pins as A and B, and the current pattern
  can be one pin on, both pins on, or no pins on.
  
  By determining the order in which the patterns are changing, we
  can determine the direction that the spindle is spinning in.
  
  The pattern should go A-AB-B-NONE-A-AB-B-NONE in one direction
  and B-AB-A-NONE-B-AB-A-NONE in the other direction.
  
  So, we have to store the previous pattern in a variable.
  0 = Not set
  1 = A
  2 = AB
  3 = B
  4 = None
  */
  
  if (digA && !digB) {
    // Only A is on
    currPattern = 1;
  } else if (!digA && digB) {
    // Only B is on
    currPattern = 3;
  } else if (digA && digB) {
    // Both A and B are on
    currPattern = 2;
  } else if (!digA && !digB) {
    // Neither A nor B are on
    currPattern = 4;
  }
  
  if (currPattern != prevPatterns[0]) {
    // The current pattern is different to the last one, and is not just a repetition.
  
    // Shift patterns up, where prevPatterns[0] is the newest
    for (int i = 3; i > 0; i--) {
      prevPatterns[i] = prevPatterns[i - 1];
    }
    prevPatterns[0] = currPattern;

    if (arrayMatches(prevPatterns, 1, 2, 3, 4) || arrayMatches(prevPatterns, 2, 3, 4, 1) || arrayMatches(prevPatterns, 3, 4, 1, 2) || arrayMatches(prevPatterns, 4, 1, 2, 3)) {
      // Direction A (anticlockwise)
      Serial.print("<");
    } else if (arrayMatches(prevPatterns, 3, 2, 1, 4) || arrayMatches(prevPatterns, 2, 1, 4, 3) || arrayMatches(prevPatterns, 1, 4, 3, 2) || arrayMatches(prevPatterns, 4, 3, 2, 1)) {
      // Direction B (clockwise)
      Serial.print(">");
    }
  }

  delay(5);
}

int arrayMatches(int array[], int a, int b, int c, int d) {
  // If a, b, c & d match array items 0 to 3, then return true.
  return (array[0] == a && array[1] == b && array[2] == c && array[3] == d);
}

int toDigital(int hdd) {
  // If the analog signal is greater than the threshold (set to 10 at the moment),
  // then we pretend that it's a HIGH signal.
  if (hdd > 10)
    return HIGH;
  else
    return LOW;
}
