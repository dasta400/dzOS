/******************************************************************************
 * kbd_controller.ino
 *
 * Teensy++ 2.0 based keyboard controller for Acorn Archimedes A3010 keyboard
 * for dastaZ80's dzOS
 * by David Asta (Jul 2022)
 * 
 * Version 1.0.1
 * Created on 15 Jul 2022
 * Last Modification 19 Nov 2022
 *******************************************************************************
 * CHANGELOG
 *   - 12 Oct 2022:
 *          Implemented keys: Esc, Backspace, Tab, Ctrl, Alt, Pound, Fn
 *          Bug: to disable the column, I was using pinMode INPUT instead of INPUT_PULLUP
 *   - 19 Nov 2022:
 *          All normal keys work now. Also shift keys
 *          Now it can be used for Serial and as USB keyboard. ScrollLock switches
 *              to where the keys are sent. ScrollLock ON, send keys only to USB
 *                                          ScrollLock is OFF, send keys only to Serial
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
  *         USB: All keys, except Pound and keypad #, working. All LEDS working.
  *         Serial: 
  *             Alphabetic: A to Z
  *             Number: 1 to 0
  *             Symbols: `~!@#$%^&*()-_=+[{]}\|;:'",<.>/?
  *             Shift key modifier: for capital alphanumeric letters and symbols
  *             Keypad: 1 to 0, /*#-+. and Enter
  *             CapsLock key
  *             LEDs: All working. Disk activity connected to pin for external
  *         Both:
  *             ScrollLock switches where keys are sent (USB or Serial)
  *     Not implemented:
  *         Function keys: F1 to F12
  *         Esc key
  *         Tab key
  *         Ctrl keys
  *         Alt keys
  *         Backspace
  *         Pound key
  *         NumLock key
  *         Special keys: Print, Break, Insert, Home, Delete, etc.
  *         Cursor keys
  *         Multiple modifier keys (e.g. Ctrl + Shift + key, Alt + Shift + key)
  */

#include "kbd_defs.h"

// Keys are sent at interval defined here, for as long as the key is pressed down
// Lower the value for sending keys quickly
#define DEBOUNCE_VALUE 20   // As per my tests, 15 is the minimum value. Less than that, and keys 
                            // start repeating on single presses. I left it as 20 to be in the safe side

// LEDs pins
#define LED_CAPSLOCK    27
#define LED_SCROLLLOCK  16
#define LED_NUMLOCK     17
// Power On LED is connected to +5V
// Disk Activity LED is connected to a pin header

/*****************************************************************************/
/* Sets Teensy++ 2.0 for reading the matrix keyboard                         */
/*****************************************************************************/
void setup() {
    Serial1.begin(115200);

    // set all LED pins as outputs and turn them OFF (HIGH=OFF, LOW=ON)
    pinMode(LED_CAPSLOCK,   OUTPUT); digitalWrite(LED_CAPSLOCK,   HIGH);
    pinMode(LED_SCROLLLOCK, OUTPUT); digitalWrite(LED_SCROLLLOCK, HIGH);
    pinMode(LED_NUMLOCK,    OUTPUT); digitalWrite(LED_NUMLOCK,    HIGH);

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

    modifierkey_shift_l = false;
    modifierkey_shift_r = false;
    capslock_on         = false;
    scrolllock_on       = false;
}

/*****************************************************************************/
/* Main loop                                                                 */
/* Reads the keyboard matrix to detect which key is pressed                  */
/* and sends the key, at intervals, for as long as the key is pressed down   */
/* Uses a debouncer to avoid the mechanical bouncing effect of keyboards     */
/*****************************************************************************/
void loop() {
    int repeatCount = 0;

     // Check modifier keys (SHIFT, ALT, CTRL)
    check_modifer_key(LSHIFT_ROW, LSHIFT_COL, KEY_LEFT_SHIFT);
    check_modifer_key(RSHIFT_ROW, RSHIFT_COL, KEY_RIGHT_SHIFT);
    check_modifer_key(LCTRL_ROW, LCTRL_COL,   KEY_LEFT_CTRL);
    check_modifer_key(RCTRL_ROW, RCTRL_COL,   KEY_RIGHT_CTRL);
    check_modifer_key(LALT_ROW, LALT_COL,     KEY_LEFT_ALT);
    check_modifer_key(RALT_ROW, RALT_COL,     KEY_RIGHT_ALT);

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
                    sendKey(r, c);
                }else if(repeatCount > DEBOUNCE_VALUE){
                    repeatCount -= DEBOUNCE_VALUE;

                    // Sends key, at intervals (DEBOUNCE_VALUE), for as long as the key is pressed down
                    // Without this code, if a key is held down it's sent only once
                    if(repeatCount % (DEBOUNCE_VALUE * 2) == 0){
                        sendKey(r, c);
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

/*****************************************************************************/
/* Checks if any (Left or Right) of the Shift, Ctrl or Alt keys is pressed   */
/* Sets (TRUE if pressed) global boolean variables for each key              */
/*****************************************************************************/
void check_modifer_key(int r, int c, int mod){
    // is the modifier key pressed?
    pinMode(colPins[c], OUTPUT);
    digitalWrite(colPins[c], LOW);
    pinMode(rowPins[r], INPUT_PULLUP);

    // If yes, send it
    if(digitalRead(rowPins[r]) == LOW){
        Keyboard.press(mod);
        
          switch (mod){
          case KEY_LEFT_SHIFT:
            modifierkey_shift_l = true;
            break;
          case KEY_RIGHT_SHIFT:
            modifierkey_shift_r = true;
            break;
          }
    }else{
        Keyboard.release(mod);

        switch (mod){
        case KEY_LEFT_SHIFT:
          modifierkey_shift_l = false;
            break;
        case KEY_RIGHT_SHIFT:
          modifierkey_shift_r = false;
          break;
        }
    }

    // disable the column and row
    pinMode(rowPins[r], INPUT_PULLUP);
    pinMode(colPins[c], INPUT_PULLUP);
}

/*****************************************************************************/
/* Sends the key value via Serial1                                           */
/* Shift, Ctrl and Alt are not send.                                         */
/*****************************************************************************/
void sendKey(int row, int col){
    if(keyMap[row][col] != KEY_SCROLL_LOCK){
        // If ScrollLock is ON, send keys only to USB
        // If ScrollLock is OFF, send keys only to Serial
        if(scrolllock_on){
            Keyboard.press(keyMap[row][col]);
            Keyboard.release(keyMap[row][col]);
        }else{
            if(keyMap_serial[0][row][col] < 129){
            if((modifierkey_shift_l || modifierkey_shift_r) ||
                (capslock_on &&  ((keyMap_serial[0][row][col] > 64 && keyMap_serial[0][row][col] < 91) || 
                                (keyMap_serial[0][row][col] > 96 && keyMap_serial[0][row][col] < 123)))){
                Serial1.write(keyMap_serial[1][row][col]);
            }else{
                Serial1.write(keyMap_serial[0][row][col]);
            }
            }
        }
        
        // Switch LEDs
        if(keyMap[row][col] == KEY_CAPS_LOCK){
            digitalWrite(LED_CAPSLOCK, !digitalRead(LED_CAPSLOCK));
            capslock_on = !capslock_on;
        }
    
        if(keyMap[row][col] == KEY_NUM_LOCK)
            digitalWrite(LED_NUMLOCK, !digitalRead(LED_NUMLOCK));
    }else{
        // Switch ScrollLock LED and ON/OFF flag
        digitalWrite(LED_SCROLLLOCK, !digitalRead(LED_SCROLLLOCK));
        scrolllock_on = !scrolllock_on;
    }
}