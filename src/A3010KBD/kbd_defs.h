/******************************************************************************
 * kbd_defs.h
 *
 * Keyboard definitions to include in kbd_controller.ino
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
 *        Bug: KEY_F7 was assigned to KEY_F9 instead
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
 
#include <Keyboard.h>

#ifndef KEY_A
#error Something went wrong when including Keyboard.h
#endif

#define NUM_ROWS 16       // TOP Connector: pins 1, 2, 3 and 4 are Not connected (NC)
#define NUM_COLS 14       // BOTTOM Connector: pins 1, 17, 18, 19 and 20 are for LEDS, and pin 16 is +5Vcc

// Shift keys position in the matrix
#define LSHIFT_COL 6
#define LSHIFT_ROW 8
#define RSHIFT_COL 6
#define RSHIFT_ROW 2

// Ctrl keys position in the matrix
#define LCTRL_COL 6
#define LCTRL_ROW 9
#define RCTRL_COL 6
#define RCTRL_ROW 1

// Alt keys position in the matrix
#define LALT_COL 6
#define LALT_ROW 14
#define RALT_COL 6
#define RALT_ROW 0

// Caps Lock position in the matrix
#define CAPSLOCK_COL 2
#define CAPSLOCK_ROW 15

// Modifier keys
#define SER_KEY_LEFT_CTRL           0x81
#define SER_KEY_RIGHT_CTRL          0x82
#define SER_KEY_LEFT_SHIFT          0x83
#define SER_KEY_RIGHT_SHIFT         0x84
#define SER_KEY_LEFT_ALT            0x85
#define SER_KEY_RIGHT_ALT           0x86
#define SER_KEY_CAPS_LOCK           0x87

// Function keys
#define SER_KEY_F1                  0x88
#define SER_KEY_F2                  0x89
#define SER_KEY_F3                  0x8A
#define SER_KEY_F4                  0x8B
#define SER_KEY_F5                  0x8C
#define SER_KEY_F6                  0x8D
#define SER_KEY_F7                  0x8E
#define SER_KEY_F8                  0x8F
#define SER_KEY_F9                  0x90
#define SER_KEY_F10                 0x91
#define SER_KEY_F11                 0x92
#define SER_KEY_F12                 0x93

// Special keys
#define SER_KEY_BACKSPACE       0x08
#define SER_KEY_TAB             0x09
#define SER_KEY_RETURN          0x0D
#define SER_KEY_ESC             0x1B
#define SER_KEY_PRINTSCREEN         0x95
#define SER_KEY_SCROLL_LOCK         0x96
#define SER_KEY_PAUSE               0x80
#define SER_KEY_INSERT              0x98
#define SER_KEY_HOME                0x99
#define SER_KEY_PAGE_UP             0x9A
#define SER_KEY_DELETE              0x7F
#define SER_KEY_END                 0x9B
#define SER_KEY_PAGE_DOWN           0x9C
#define SER_KEY_UP                  0x9D
#define SER_KEY_DOWN                0x9E
#define SER_KEY_RIGHT               0x9F
#define SER_KEY_LEFT                0xA0

// Symbol keys
#define SER_KEY_POUND               0xA1

// Keypad keys
#define SER_KEY_NUM_LOCK        0xA2
#define SER_KEY_ENTER           0x0D

bool capslock_on;
bool scrolllock_on;         // ScrollLock controls where keys are sent:
                            //  scrollLock = on             : USB only
                            //  scrollLock = off  (default) : Serial only
bool modifierkey_shift_l;
bool modifierkey_shift_r;
bool modifierkey_ctrl;
bool modifierkey_alt;

int debouncerCount[NUM_ROWS][NUM_COLS];

/*
 *     A3010 Keyboard Matrix:
 *      Key               Row Column
 *     ------------------------------
 *      Esc                15      1
 *      F1                 10      2
 *      F2                 11      2
 *      F3                 11      3
 *      F4                 10      3
 *      F5                  7      7
 *      F6                  7     11
 *      F7                  5     13
 *      F8                  4     13
 *      F9                  7     13
 *      F10                 7     12
 *      F11                 5     12
 *      F12                 4     12
 *      ~ `                13      1
 *      1 !                 7      1
 *      2 @                 5      2
 *      3 #                 5      3
 *      4 $                10      4
 *      5 %                 7      4
 *      6 ^                 7      5
 *      7 &                10      5
 *      8 *                10      7
 *      9 (                10     11
 *      0 )                11     13
 *      - _                10     12
 *      = +                 7     10
 *      £                  10     10
 *      Backspace           5     10
 *      Tab                11      1
 *      Left Ctrl           9      6
 *      Left Shift          8      6
 *      Caps Lock          15      2
 *      Left Alt           14      6
 *      A                   4      1
 *      B                  15      4
 *      C                  13      3
 *      D                  12      3
 *      E                   4      3
 *      F                  11      4
 *      G                  12      4
 *      H                  12      5
 *      I                   5      7
 *      J                  11      5
 *      K                  12      7
 *      L                  11     11
 *      M                  13      5
 *      N                  15      5
 *      O                   5     11
 *      P                  13     13
 *      Q                   5      1
 *      R                   5      4
 *      S                  12      2
 *      T                   4      4
 *      U                   5      5
 *      V                  13      4
 *      W                   4      2
 *      X                  13      2
 *      Y                   4      5
 *      Z                  12      1
 *      [ {                12     13
 *      ] }                 4     11
 *      \ |                11      7
 *      ; :                15     13
 *      ' "                12     11
 *      , <                13      7
 *      . >                13     11
 *      / ?                15     11
 *      Return              4      7
 *      Right Shift         2      6
 *      Right Alt           0      6
 *      Right Ctrl/Action   1      6
 *      Print               3      6
 *      Scroll Lock         4      0
 *      Break/Pause         5      0
 *      Insert              4     10
 *      Home                6      6
 *      Page Up            10      0
 *      Delete             10      9
 *      Copy/End            5      9
 *      Page Down           4      9
 *      Cursor Up           4      8
 *      Cursor Left        15      7  
 *      Cursor Down        13      8
 *      Cursor Right       12      8
 *      Num Lock           11      0
 *      Numpad /           11     12
 *      Numpad *           11     10
 *      Numpad #           11      9
 *      Numpad -           12      9
 *      Numpad +           13      9
 *      Numpad Enter       15      9
 *      Numpad .           11      8
 *      Numpad 1           15      0
 *      Numpad 2           15     12
 *      Numpad 3           15     10
 *      Numpad 4           13      0
 *      Numpad 5           13     12
 *      Numpad 6           13     10
 *      Numpad 7           12      0
 *      Numpad 8           12     12
 *      Numapd 9           12     10
 *      Numpad 0           15      8
 */

//                          Pins on Teensy++ 2.0
// bottom cable -> columns (D0, D1, D4, D5, D6, D7, E0, E1, C0, C1, C2, C3, C4, C5)
int colPins[NUM_COLS] =    { 0,  1,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15};
// top cable ----> rows    (F6, F5, F4, F3, F2, F1, F0, E6, E7, B0, B1, B2, B3, B4, B5, B6)
int rowPins[NUM_ROWS] =    {44, 43, 42, 41, 40, 39, 38, 18, 19, 20, 21, 22, 23, 24, 25, 26};

// Missing key definitions
#define KEY_POUND   0x00
#define KEYPAD_HASH 0x00

// Key definitions for USB
unsigned int keyMap[NUM_ROWS][NUM_COLS] = {
    /* Row 0  pin 5  */ {0, 0, 0, 0, 0, 0, KEY_RIGHT_ALT, 0, 0, 0, 0, 0, 0, 0},
    /* Row 1  pin 6  */ {0, 0, 0, 0, 0, 0, KEY_RIGHT_CTRL, 0, 0, 0, 0, 0, 0, 0},
    /* Row 2  pin 7  */ {0, 0, 0, 0, 0, 0, KEY_RIGHT_SHIFT, 0, 0, 0, 0, 0, 0, 0},
    /* Row 3  pin 8  */ {0, 0, 0, 0, 0, 0, KEY_PRINTSCREEN, 0, 0, 0, 0, 0, 0, 0},
    /* Row 4  pin 9  */ {KEY_SCROLL_LOCK, KEY_A, KEY_W, KEY_E, KEY_T, KEY_Y, 0, KEY_RETURN, KEY_UP, KEY_PAGE_DOWN, KEY_INSERT, KEY_RIGHT_BRACE, KEY_F12, KEY_F8},
    /* Row 5  pin 10 */ {KEY_PAUSE, KEY_Q, KEY_2, KEY_3, KEY_R, KEY_U, 0, KEY_I, 0, KEY_END, KEY_BACKSPACE, KEY_O, KEY_F11, KEY_F9},
    /* Row 6  pin 11 */ {0, 0, 0, 0, 0, 0, KEY_HOME, 0, 0, 0, 0, 0, 0, 0},
    /* Row 7  pin 12 */ {0, KEY_1, 0, 0, KEY_5, KEY_6, 0, KEY_F5, 0, 0, KEY_EQUAL, KEY_F6, KEY_F10, KEY_9},
    /* Row 8  pin 13 */ {0, 0, 0, 0, 0, 0, KEY_LEFT_SHIFT, 0, 0, 0, 0, 0, 0, 0},
    /* Row 9  pin 14 */ {0, 0, 0, 0, 0, 0, KEY_LEFT_CTRL, 0, 0, 0, 0, 0, 0, 0},
    /* Row 10 pin 15 */ {KEY_PAGE_UP, 0, KEY_F1, KEY_F4, KEY_4, KEY_7, 0, KEY_8, 0, KEY_DELETE, KEY_POUND, KEY_9, KEY_MINUS, 0},
    /* Row 11 pin 16 */ {KEY_NUM_LOCK, KEY_TAB, KEY_F2, KEY_F3, KEY_F, KEY_J, 0, KEY_BACKSLASH, KEYPAD_PERIOD, KEYPAD_HASH, KEYPAD_ASTERIX, KEY_L, KEYPAD_SLASH, KEY_0},
    /* Row 12 pin 17 */ {KEYPAD_7, KEY_Z, KEY_S, KEY_D, KEY_G, KEY_H, 0, KEY_K, KEY_RIGHT, KEYPAD_MINUS, KEYPAD_9, KEY_QUOTE, KEYPAD_8, KEY_LEFT_BRACE},
    /* Row 13 pin 18 */ {KEYPAD_4, KEY_TILDE, KEY_X, KEY_C, KEY_V, KEY_M, 0, KEY_COMMA, KEY_DOWN, KEYPAD_PLUS, KEYPAD_6, KEY_PERIOD, KEYPAD_5, KEY_P},
    /* Row 14 pin 19 */ {0, 0, 0, 0, 0, 0, KEY_LEFT_ALT, 0, 0, 0, 0, 0, 0, 0},
    /* Row 15 pin 20 */ {KEYPAD_1, KEY_ESC, KEY_CAPS_LOCK, KEY_SPACE, KEY_B, KEY_N, 0, KEY_LEFT, KEYPAD_0, KEYPAD_ENTER, KEYPAD_3, KEY_SLASH, KEYPAD_2, KEY_SEMICOLON}
};

// Key definitions for Serial 1
unsigned int keyMap_serial[2][NUM_ROWS][NUM_COLS] = {
  { // Normal keys
  /* Row 0  pin 5  */ {0, 0, 0, 0, 0, 0, SER_KEY_RIGHT_ALT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 1  pin 6  */ {0, 0, 0, 0, 0, 0, SER_KEY_RIGHT_CTRL, 0, 0, 0, 0, 0, 0, 0},
  /* Row 2  pin 7  */ {0, 0, 0, 0, 0, 0, SER_KEY_RIGHT_SHIFT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 3  pin 8  */ {0, 0, 0, 0, 0, 0, SER_KEY_PRINTSCREEN, 0, 0, 0, 0, 0, 0, 0},
  /* Row 4  pin 9  */ {SER_KEY_SCROLL_LOCK, 'a', 'w', 'e', 't', 'y', 0, SER_KEY_RETURN, SER_KEY_UP, SER_KEY_PAGE_DOWN, SER_KEY_INSERT, ']', SER_KEY_F12, SER_KEY_F8},
  /* Row 5  pin 10 */ {SER_KEY_PAUSE, 'q', '2', '3', 'r', 'u', 0, 'i', 0, SER_KEY_END, SER_KEY_BACKSPACE, 'o', SER_KEY_F11, SER_KEY_F7},
  /* Row 6  pin 11 */ {0, 0, 0, 0, 0, 0, SER_KEY_HOME, 0, 0, 0, 0, 0, 0, 0},
  /* Row 7  pin 12 */ {0, '1', 0, 0, '5', '6', 0, SER_KEY_F5, 0, 0, '=', SER_KEY_F6, SER_KEY_F10, SER_KEY_F9},
  /* Row 8  pin 13 */ {0, 0, 0, 0, 0, 0, SER_KEY_LEFT_SHIFT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 9  pin 14 */ {0, 0, 0, 0, 0, 0, SER_KEY_LEFT_CTRL, 0, 0, 0, 0, 0, 0, 0},
  /* Row 10 pin 15 */ {SER_KEY_PAGE_UP, 0, SER_KEY_F1, SER_KEY_F4, '4', '7', 0, '8', 0, SER_KEY_DELETE, SER_KEY_POUND, '9', '-', 0},
  /* Row 11 pin 16 */ {SER_KEY_NUM_LOCK, SER_KEY_TAB, SER_KEY_F2, SER_KEY_F3, 'f', 'j', 0, '\\', '.', '#', '*', 'l', '/', '0'},
  /* Row 12 pin 17 */ {'7', 'z', 's', 'd', 'g', 'h', 0, 'k', SER_KEY_RIGHT, '-', '9', '\'', '8', '['},
  /* Row 13 pin 18 */ {'4', '`', 'x', 'c', 'v', 'm', 0, ',', SER_KEY_DOWN, '+', '6', '.', '5', 'p'},
  /* Row 14 pin 19 */ {0, 0, 0, 0, 0, 0, SER_KEY_LEFT_ALT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 15 pin 20 */ {'1', SER_KEY_ESC, SER_KEY_CAPS_LOCK, ' ', 'b', 'n', 0, SER_KEY_LEFT, '0', SER_KEY_ENTER, '3', '/', '2', ';'}
  },
  { // Keys + Shift
  /* Row 0  pin 5  */ {0, 0, 0, 0, 0, 0, SER_KEY_RIGHT_ALT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 1  pin 6  */ {0, 0, 0, 0, 0, 0, SER_KEY_RIGHT_CTRL, 0, 0, 0, 0, 0, 0, 0},
  /* Row 2  pin 7  */ {0, 0, 0, 0, 0, 0, SER_KEY_RIGHT_SHIFT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 3  pin 8  */ {0, 0, 0, 0, 0, 0, SER_KEY_PRINTSCREEN, 0, 0, 0, 0, 0, 0, 0},
  /* Row 4  pin 9  */ {SER_KEY_SCROLL_LOCK, 'A', 'W', 'E', 'T', 'Y', 0, SER_KEY_RETURN, SER_KEY_UP, SER_KEY_PAGE_DOWN, SER_KEY_INSERT, '}', SER_KEY_F12, SER_KEY_F8},
  /* Row 5  pin 10 */ {SER_KEY_PAUSE, 'Q', '@', '#', 'R', 'U', 0, 'I', 0, SER_KEY_END, SER_KEY_BACKSPACE, 'O', SER_KEY_F11, SER_KEY_F7},
  /* Row 6  pin 11 */ {0, 0, 0, 0, 0, 0, SER_KEY_HOME, 0, 0, 0, 0, 0, 0, 0},
  /* Row 7  pin 12 */ {0, '!', 0, 0, '%', '^', 0, SER_KEY_F5, 0, 0, '+', SER_KEY_F6, SER_KEY_F10, SER_KEY_F9},
  /* Row 8  pin 13 */ {0, 0, 0, 0, 0, 0, SER_KEY_LEFT_SHIFT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 9  pin 14 */ {0, 0, 0, 0, 0, 0, SER_KEY_LEFT_CTRL, 0, 0, 0, 0, 0, 0, 0},
  /* Row 10 pin 15 */ {SER_KEY_PAGE_UP, 0, SER_KEY_F1, SER_KEY_F4, '$', '&', 0, '*', 0, SER_KEY_DELETE, SER_KEY_POUND, '(', '_', 0},
  /* Row 11 pin 16 */ {SER_KEY_NUM_LOCK, SER_KEY_TAB, SER_KEY_F2, SER_KEY_F3, 'F', 'J', 0, '|', '.', '#', '*', 'L', '/', ')'},
  /* Row 12 pin 17 */ {'7', 'Z', 'S', 'D', 'G', 'H', 0, 'K', SER_KEY_RIGHT, '-', '9', '"', '8', '{'},
  /* Row 13 pin 18 */ {'4', '~', 'X', 'C', 'V', 'M', 0, '<', SER_KEY_DOWN, '+', '6', '>', '5', 'P'},
  /* Row 14 pin 19 */ {0, 0, 0, 0, 0, 0, SER_KEY_LEFT_ALT, 0, 0, 0, 0, 0, 0, 0},
  /* Row 15 pin 20 */ {'1', SER_KEY_ESC, SER_KEY_CAPS_LOCK, ' ', 'B', 'N', 0, SER_KEY_LEFT, '0', SER_KEY_ENTER, '3', '?', '2', ':'}
  }
};