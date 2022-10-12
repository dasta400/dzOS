/******************************************************************************
 * kbd_controller.ino
 *
 * Teensy++ 2.0 based keyboard controller for Acorn Archimedes A3010 keyboard
 * for dastaZ80's dzOS
 * by David Asta (Jul 2022)
 * 
 * Version 1.0.1
 * Created on 15 Jul 2022
 * Last Modification 12 Oct 2022
 *******************************************************************************
 * CHANGELOG
 *   - 12 Oct 2022:
 *        Implemented keys: Esc, Backspace, Tab, Ctrl, Alt, Pound, Fn
 *        Bug: to disable the column, I was using pinMode INPUT instead of INPUT_PULLUP
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
  *         CapsLock key
  *         Function keys: F1 to F12
  *         Esc key
  *         Tab key
  *         Ctrl keys
  *         Alt keys
  *         Backspace
  *         Pound key
  *         LEDs: CapsLock, Power,Disk activity
  *     Not implemented:
  *         NumLock key
  *         Special keys: Print, Break, Insert, Home, Delete, etc.
  *         Cursor keys
  *         Multiple modifier keys (e.g. Ctrl + Shift + key, Alt + Shift + key)
  *         LEDs: Scroll Lock, Num Lock
  */

#include "kbd_defs.h"

#ifndef KEY_ESC
#error Something went wrong when including kbd_defs.h
#endif

// Keys are sent at interval defined here, for as long as the key is pressed down
// Lower the value for sending keys quickly
#define DEBOUNCE_VALUE 20   // As per my tests, 15 is the minimum value. Less than that, and keys 
                            // start repeating on single presses. I left it as 20 to be in the safe side

#define DEBUG   false       // set to true to get some debugging values on the Arduino IDE Serial Monitor

// LEDs pins
#define LED_CAPSLOCK    27
#define LED_SCROLLLOCK  16
#define LED_NUMLOCK     17
// Power On LED is connected to +5V
// Disk Activity LED is connected to CF Card BUSY signal

#define LED_ON      LOW
#define LED_OFF     HIGH

int debouncerCount[NUM_ROWS][NUM_COLS];

/*****************************************************************************/
/* Sets Teensy++ 2.0 for reading the matrix keyboard                         */
/*****************************************************************************/
void setup() {
    if(DEBUG){ Serial.begin(9600); }
    Serial1.begin(115200);

    // set all LED pins as outputs and turn them OFF (HIGH=OFF, LOW=ON)
    pinMode(LED_CAPSLOCK,   OUTPUT); digitalWrite(LED_CAPSLOCK,   LED_OFF);
    pinMode(LED_SCROLLLOCK, OUTPUT); digitalWrite(LED_SCROLLLOCK, LED_OFF);
    pinMode(LED_NUMLOCK,    OUTPUT); digitalWrite(LED_NUMLOCK,    LED_OFF);

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
}

/*****************************************************************************/
/* Main loop: continously reads the matrix keyboard                          */
/*****************************************************************************/
void loop() {
    readMatrixKBD();
}

/*****************************************************************************/
/* Checks if a key in a specific row and column is pressed                   */
/* Returns TRUE if key is pressed                                            */
/*****************************************************************************/
bool is_key_pressed(int r, int c){
    bool key_pressed = false;

    // is the modifier key pressed?
    pinMode(colPins[c], OUTPUT);
    digitalWrite(colPins[c], LOW);
    pinMode(rowPins[r], INPUT_PULLUP);

    if(digitalRead(rowPins[r]) == LOW){
        key_pressed = true;
    }

    pinMode(rowPins[r], INPUT_PULLUP);
    pinMode(colPins[c], INPUT);

    return key_pressed;
}

/*****************************************************************************/
/* Checks if any (Left or Right) of the Shift, Ctrl or Alt keys is pressed   */
/* Sets (TRUE if pressed) global boolean variables for each key              */
/*****************************************************************************/
void check_modifier_keys(){
    // Check for Left and Right Shift keys  
    modifierkey_shift = is_key_pressed(LSHIFT_ROW, LSHIFT_COL);
    if(modifierkey_shift == false){
        modifierkey_shift = is_key_pressed(RSHIFT_ROW, RSHIFT_COL);
    }

    // Check for Left and Right Ctrl keys  
    modifierkey_ctrl = is_key_pressed(LCTRL_ROW, LCTRL_COL);
    if(modifierkey_ctrl == false){
        modifierkey_ctrl = is_key_pressed(RCTRL_ROW, RCTRL_COL);
    }

    // Check for Left and Right Alt keys  
    modifierkey_alt = is_key_pressed(LALT_ROW, LALT_COL);
    if(modifierkey_alt == false){
        modifierkey_alt = is_key_pressed(RALT_ROW, RALT_COL);
    }
}

/*****************************************************************************/
/* Sends the key value via Serial1                                           */
/* Shift, Ctrl and Alt are not send.                                         */
/*****************************************************************************/
void sendKey(int row, int col, bool shift_pressed){
      int pressed_key = keyMap_normal[row][col];

    switch(keyMap_normal[row][col]){
        case KEY_CAPS_LOCK:
        if(capslock_on){
            digitalWrite(LED_CAPSLOCK, LED_OFF);
            capslock_on = false;
        }else{
            digitalWrite(LED_CAPSLOCK, LED_ON);
            capslock_on = true;
        }
        break;
        case KEY_LEFT_SHIFT:  break; // Do not send key press
        case KEY_LEFT_CTRL:   break; // Do not send key press
        case KEY_LEFT_ALT:    break; // Do not send key press
        default:
        if(DEBUG){ Serial.print("ROW: "); Serial.print(row); Serial.print(" COL: "); Serial.print(col); }
        if(shift_pressed || (capslock_on && pressed_key >= 97 && pressed_key <= 122)){
            if(DEBUG){ Serial.print(" Shifted: "); Serial.print(keyMap_shift[row][col]); Serial.print(" ("); Serial.print((char)keyMap_shift[row][col]); Serial.println(")"); }
            Serial1.write(keyMap_shift[row][col]);
        }else{
            if(DEBUG){ Serial.print(" Normal: "); Serial.print(keyMap_normal[row][col]); Serial.print(" ("); Serial.print((char)keyMap_normal[row][col]); Serial.println(")"); }
            Serial1.write(keyMap_normal[row][col]);
        }
        break;
    }
}

/*****************************************************************************/
/* Reads the keyboard matrix to detect which key is pressed                  */
/* and sends the key, at intervals, for as long as the key is pressed down   */
/* Uses a debouncer to avoid the mechanical bouncing effect of keyboards     */
/*****************************************************************************/
void readMatrixKBD(){
    int repeatCount = 0;

    check_modifier_keys(); // is any (Left or Right) of the Shift, Ctrl or Alt keys pressed?

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

                    // Sends key, at intervals (DEBOUNCE_VALUE), for as long as the key is pressed down
                    // Without this code, if a key is held down it's sent only once
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
        }

        // disable the column, by setting it as INPUT_PULLUP
        pinMode(colPins[c], INPUT_PULLUP);
    }
}