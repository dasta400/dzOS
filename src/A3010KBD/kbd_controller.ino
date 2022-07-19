/******************************************************************************
 * kbd_controller.ino
 *
 * Teensy++ 2.0 based keyboard controller for Acorn Archimedes A3010 keyboard
 * for dastaZ80's dzOS
 * by David Asta (Jul 2022)
 * 
 * Version 1.0.0
 * Created on 15 Jul 2022
 * Last Modification 15 Jul 2022
 *******************************************************************************
 * CHANGELOG
 *   -
 *******************************************************************************
 */

/* ---------------------------LICENSE NOTICE-------------------------------- 
 *  MIT License
 *  
 *  Copyright (c) 2022 David Asta
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

 /* 
  * CURRENT STATUS
  * ==========================================================================
  *     Implemented:
  *         Alphabetic: A to Z
  *         Number: 1 to 0
  *         Symbols: `~!@#$%^&*()-_=+[{]}\|;:'",<.>/?
  *         Shift key modifier: for capital alphanumeric letters and symbols
  *         Keypad: 1 to 0, /*#-+. and Enter
  *     Not implemented:
  *         Function keys: F1 to F12
  *         Esc key
  *         Tab key
  *         Ctrl keys
  *         Alt keys
  *         CapsLock key
  *         NumLock key
  *         Special keys: Print, Break, Insert, Home, Delete, etc.
  *         Cursor keys
  *         Backspace
  *         Multiple modifier keys (e.g. Ctrl + Shift + key, Alt + Shift + key)
  *         LEDs: CapsLock, Scroll Lock, Num Lock, Power, Disk activity
  *         Pound key (I have to figure out what to print, as I'm not using that symbol)
  */

#include "kbd_defs.h"

#ifndef KEY_ESC
#error Something went wrong when including kbd_defs.h
#endif

#define LED_BUILTIN 6     // LED on Teensy++ 2.0 will flash everytime time a key is pressed

#define DEBOUNCE_VALUE 40

// LEDs
#define LED_CAPSLOCK 14    // C4
#define LED_SCROLLLOCK 15  // C5
#define LED_NUMLOCK 16     // C6
#define LED_POWERON 45     // F7
//#define LED_DISKACTIV      // Not used

int debouncerCount[NUM_ROWS][NUM_COLS];

/*****************************************************************************/
void setup() {
  // Uncomment for debugging Serial.begin(9600);
  Serial1.begin(115200);
  
  // turn off Arduino on-board LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // set all LED pins as outputs and turn them OFF
  pinMode(LED_CAPSLOCK,   OUTPUT); digitalWrite(LED_CAPSLOCK,   HIGH);
  pinMode(LED_SCROLLLOCK, OUTPUT); digitalWrite(LED_SCROLLLOCK, HIGH);
  pinMode(LED_NUMLOCK,    OUTPUT); digitalWrite(LED_NUMLOCK,    HIGH);
  pinMode(LED_POWERON,    OUTPUT); digitalWrite(LED_POWERON,    HIGH);
  //pinMode(LED_DISKACTIV,  OUTPUT); digitalWrite(LED_DISKACTIV,  HIGH);  // Not used
  pinMode(LED_BUILTIN,    OUTPUT); digitalWrite(LED_BUILTIN,    LOW);


  // set all ROWS pins as input pull-up
  for(int r=0; r<NUM_ROWS; r++){
    pinMode(rowPins[r], INPUT_PULLUP);
  }

  // set all COLS pins as inputs
  for(int c=0; c<NUM_COLS; c++){
    pinMode(colPins[c], INPUT);

    // clear debouncer counts
    for(int r=0; r<NUM_ROWS; r++){
      debouncerCount[r][c] = 0;
    }
  }

  capslock_on = false;

  // Switch ON the Power On LED
  digitalWrite(LED_POWERON, LOW);
}

/*****************************************************************************/
void loop() {
  readMatrixKBD();
}

/*****************************************************************************/
bool check_modifer_key(int r, int c, int mod){
  modifier_key = false;
  
  // is the modifier key pressed?
  pinMode(colPins[c], OUTPUT);
  digitalWrite(colPins[c], LOW);
  pinMode(rowPins[r], INPUT_PULLUP);
  
  if(digitalRead(rowPins[r]) == LOW){
    modifier_key = true;
  }

  pinMode(rowPins[r], INPUT_PULLUP);
  pinMode(colPins[c], INPUT);

  return modifier_key;
}

/*****************************************************************************/
bool check_modifer_key_shift(){
  bool shift_pressed = false;
  
  shift_pressed = check_modifer_key(LSHIFT_ROW, LSHIFT_COL, KEY_LEFT_SHIFT);

  if(shift_pressed == false){
    shift_pressed = check_modifer_key(RSHIFT_ROW, RSHIFT_COL, KEY_RIGHT_SHIFT);
  }

  return shift_pressed;
}

/*****************************************************************************/
void sendKey(int row, int col, bool shift_pressed){
  digitalWrite(LED_BUILTIN, HIGH);
  // Uncomment for debugging Serial.println(keyMap_shift[row][col], HEX);
  
  if(shift_pressed){
    Serial1.write(keyMap_shift[row][col]);
  }else{
    Serial1.write(keyMap_normal[row][col]);
  }
}

/*****************************************************************************/
void readMatrixKBD(){
  int repeatCount = 0;

  bool modifierkey_shift = check_modifer_key_shift(); // is the Left or Right Shift key pressed?

  // for each column
  for(int c=0; c<NUM_COLS; c++){
    // enable column, by setting it as OUTPUT and LOW
    pinMode(colPins[c], OUTPUT);
    digitalWrite(colPins[c], LOW);
      
    // for each row
    for(int r=0; r<NUM_ROWS; r++){
      pinMode(rowPins[r], INPUT_PULLUP);

      // if there is LOW on a row read, then a key was pressed
      if(digitalRead(rowPins[r]) == LOW){
        // apply a key debouncer to avoid the mechanical bouncing effect of keyboards
        debouncerCount[r][c]++;
        repeatCount = debouncerCount[r][c];

        if(repeatCount == 1){
          sendKey(r, c, modifierkey_shift);
        }else if(repeatCount > DEBOUNCE_VALUE){
          repeatCount -= DEBOUNCE_VALUE;

          if(repeatCount % (DEBOUNCE_VALUE * 2) == 0){
            sendKey(r, c, modifierkey_shift);
          }
        }
      }else{
        // clear debouncer count for ROW, COLUMN
        debouncerCount[r][c] = 0;
      }

      // disable the row, by setting it as INPUT_PULLUP
      pinMode(rowPins[r], INPUT_PULLUP);
      digitalWrite(LED_BUILTIN, LOW);
    }

    // disable the column, by setting it as INPUT
    pinMode(colPins[c], INPUT);
  }
}