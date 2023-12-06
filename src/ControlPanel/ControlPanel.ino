/******************************************************************************
 * ControlPanel.ino
 *
 * Control Panel controler for dastaZ80
  * by David Asta (Oct 2023)
 * 
 * Version 1.1.0
 * Created on 17 Oct 2022
 * Last Modification 06 Dec 2023
 *******************************************************************************
 * CHANGELOG
 *   - 29 Nov 2023 - I've realised that the Tenssy 2.0 has no analog outputs,
 *                      therefore there is no point of having the code that was
 *                      fading the POWER LED.
 *                 - Also, moved switchFanOnOff() to loop(), because otherwise
 *                      was only working when display was at page 0.
 *   - 06 Dec 2023 - Changed Clock Select for HardDisk Select
 *******************************************************************************
 ********************************************************************************
 * To Do
 *   - If dz80IsOn is ON, do not make changes when Select is pressed
 *******************************************************************************
 */

/* ---------------------------LICENSE NOTICE--------------------------------
 *  MIT License
 *  
 *  Copyright (c) 2023 David Asta
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

#include <LiquidCrystal.h>

// LCD pins
#define PIN_LCD_RS        0
#define PIN_LCD_E         1
#define PIN_LCD_D4        2
#define PIN_LCD_D5        3
#define PIN_LCD_D6        4
#define PIN_LCD_D7        5

// Other Input PINS
#define PIN_SYSON     10      // Detects if dastaZ80 is switched ON
#define PIN_TEMP      A0      // Thermistor
#define PIN_DOWN      6       // Push button -
#define PIN_UP        7       // Push button +
#define PIN_SELE      8       // Push button Select


// Other Output PINS
#define PIN_VID_VGA   11      // Activates/Deactivates the Video output to VGA
#define PIN_ROM_HIGH  12      // Activates/Deactivates the ROM select at $4000
#define PIN_FAN       13      // Activates/Deactivates a fan for cooling
#define PIN_POWER_LED 14      // LED to show if Power ON/OFF
#define PIN_HDD_EXT   15      // Activates/Deactivates the HardDisk Drive to External

// Other constants
#define RGB_SYSON_DELAY 8
#define TEMP_DELAY      400
#define TEMP_ADJUST     2.5
#define MAXTEMP         28      // when temperature reaches this value, it will switch the fan ON
#define MINTEMP         26      // when temperature reaches this value, it will switch the fan OFF
#define MAXHYSTERESIS   20      // hysteresis delay to turn on/off the fan
#define SPINDELAY       20      // speed at which the fan animation characters change
#define WARNDELAY       80      // speed at which the heat warning symbol (!) blinks

LiquidCrystal lcd(PIN_LCD_RS, PIN_LCD_E, PIN_LCD_D4, PIN_LCD_D5, PIN_LCD_D6, PIN_LCD_D7);

int currentPage = 0;    // current page displayed
int romAddr = 0;        // current ROM Address selected
int hddSele = 0;        // current HDD (Internal/External) selected
int videoSele = 0;      // Current Video Output selected (0=TTL, 1=VGA)
int tempDelay;          // delay counter for updating temperature
int spinDelay;          // delay counter for updating a spinning animation when the fan is ON
int spinning = 0;       // index for fanspin array
char fanspin[5]="<^>v"; // array to make an animation of a spinning fan
int warningDelay;       // delay counter for updating the warning symbol
int warning = 0;        // index for fanwarn array
char fanwarn[5]="! ! "; // array to make an animation of a blinking exclamation mark
float curTemp;          // current temperature read
int hystCount = 0;      // hysteresis delay to turn on/off the fan
int maxPage = 6;        // number of pages displayed

bool fanIsOn = false;
bool dz80IsOn = false;

// int rgb_syson_brigthness_max = 50;
// int rgb_syson_brigthness_min = 10;
// int rgb_syson_brigthness = rgb_syson_brigthness_min;
// int rgb_syson_fadeamount = 1;
// int rgb_syson_delay_count = 0;

unsigned long debounceDelay = 150; // delay time to avoid bounce from the push-button
unsigned long lastDebounce = 0;   // time since push-button was last pressed


void setup() {
    lcd.begin(16, 2);    // Set up 16 columns, 2 rows

    // Configure some pins
    pinMode(PIN_UP,   INPUT_PULLUP);
    pinMode(PIN_DOWN, INPUT_PULLUP);
    pinMode(PIN_SELE, INPUT_PULLUP);
    pinMode(PIN_SYSON, INPUT);
    
    pinMode(PIN_FAN, OUTPUT);
    pinMode(PIN_VID_VGA, OUTPUT);
    pinMode(PIN_ROM_HIGH, OUTPUT);
    pinMode(PIN_POWER_LED, OUTPUT);
    pinMode(PIN_HDD_EXT, OUTPUT);

    // Configure an ISR for each push-button
    attachInterrupt(digitalPinToInterrupt(PIN_UP),   pinup,   LOW);
    attachInterrupt(digitalPinToInterrupt(PIN_DOWN), pindown, LOW);
    attachInterrupt(digitalPinToInterrupt(PIN_SELE), pinsele, LOW);

    tempDelay = TEMP_DELAY;
}

void loop() {
    if(dz80IsOn) switchFanOnOff(curTemp);
  
    // Show current page number in first character of each of the two lines
    lcd.setCursor(0, 0);
    lcd.print(currentPage);
    lcd.setCursor(0, 1);
    lcd.print(currentPage);
    lcd.setCursor(1, 1);
  
    switch(currentPage){
        case 0:
          showPage0();
          break;
        case 1:
          showPage1();
          break;
        case 2:
          showPage2();
          break;
        case 3:
          showPage3();
          break;
        case 4:
          showPage4();
          break;
        case 5:
          showPage5();
          break;
        case 6:
          showPage6();
          break;
        default:
          break;
    }
}

void pinup(){
// When Up button is pressed, show previous page
    if((millis() - lastDebounce) > debounceDelay){
        if(digitalRead(PIN_UP) == LOW){
            currentPage--;
            if(currentPage < 0) currentPage = maxPage;
        }
        lastDebounce = millis(); // reset debounce timer
    }
}

void pindown(){
// When Down button is pressed, show next page
    if((millis() - lastDebounce) > debounceDelay){
    if(digitalRead(PIN_DOWN) == LOW){
        currentPage++;
        if(currentPage > maxPage) currentPage = 0;
    }
    lastDebounce = millis(); // reset debounce timer
    }
}

void pinsele(){
// When Select button is pressed, change configuration accordingly
    if((millis() - lastDebounce) > debounceDelay){
      if(digitalRead(PIN_SELE) == LOW){
          switch(currentPage){
          case 1:
              romAddr = 0;
              digitalWrite(PIN_ROM_HIGH, romAddr);
              break;
          case 2:
              romAddr = 1;
              digitalWrite(PIN_ROM_HIGH, romAddr);
              break;
          case 3:
              hddSele = 0;
              digitalWrite(PIN_HDD_EXT, videoSele);
              break;
          case 4:
              hddSele = 1;
              digitalWrite(PIN_HDD_EXT, videoSele);
              break;
          case 5:
              videoSele = 0;
              digitalWrite(PIN_VID_VGA, videoSele);
              break;
          case 6:
              videoSele = 1;
              digitalWrite(PIN_VID_VGA, videoSele);
              break;
          default:
              break;
          }
          currentPage = 0;
      }
      lastDebounce = millis(); // reset debounce timer
    }
}

void showPage0(){
// Page 0: Configuration and Temperature
    lcd.setCursor(2, 0);

    // Rom Address
    if(romAddr == 0) lcd.print("$0000   ");
    else lcd.print("$4000   ");

    // HDD selected
    lcd.setCursor(9, 0);
    if(hddSele == 0) lcd.print("HDD Int");
    else lcd.print("HDD Ext");

    // Video Output selected
    lcd.setCursor(12, 1);
    if(videoSele == 0) lcd.print("TTL");
    else lcd.print("VGA");

    // Temperature
    if(tempDelay == 0){
        lcd.setCursor(2, 1);
        curTemp = getTemp();
        lcd.print(curTemp);
        lcd.setCursor(7, 1);
        lcd.print((char)223);   // degree symbol
        lcd.print("       ");
        tempDelay = TEMP_DELAY;
    }else{
        tempDelay--;
    }

    // Fan ON/OFF and animation, depending if dastaZ80 is switched ON or OFF
    if(dz80IsOn){
        if(fanIsOn){
            if(spinDelay == 0){
                lcd.setCursor(8, 1);
                lcd.print(fanspin[spinning]);
                spinning++;
                if(spinning > 3) spinning = 0;
                spinDelay = SPINDELAY;
            }else{
                spinDelay--;
            }
        }else{
            lcd.setCursor(8, 1);
            lcd.print(" ");
        }
    }else{
        // If temperature is above max, show a warning symbol when computer if OFF
        lcd.setCursor(8, 1);
        if(curTemp > MAXTEMP){
            if(warningDelay == 0){
                lcd.print(fanwarn[warning]);
                warning++;
                if(warning > 3) warning = 0;
                warningDelay = WARNDELAY;
            }else{
                warningDelay--;
            }
        }else{
            lcd.print(" ");
        }
    }

    dz80IsOn = digitalRead(PIN_SYSON);
}

void showPage1(){
// Page 1: ROM Address $0000
    lcd.setCursor(2, 0);
    lcd.print("ROM Start Addr");
    lcd.setCursor(2, 1);
    lcd.print(" $0000        ");
}

void showPage2(){
// Page 2: ROM Address $4000
    lcd.setCursor(2, 0);
    lcd.print("ROM Start Addr");
    lcd.setCursor(2, 1);
    lcd.print(" $4000        ");
}

void showPage3(){
// Page 3: HDD Internal
    lcd.setCursor(2, 0);
    lcd.print("HardDisk Drive");
    lcd.setCursor(2, 1);
    lcd.print(" Internal     ");
}

void showPage4(){
// Page 4: HDD External
    lcd.setCursor(2, 0);
    lcd.print("HardDisk Drive");
    lcd.setCursor(2, 1);
    lcd.print(" External     ");
}

void showPage5(){
// Page 5: Video Output TTL
    lcd.setCursor(2, 0);
    lcd.print("Video Output  ");
    lcd.setCursor(2, 1);
    lcd.print(" TTL          ");
}

void showPage6(){
// Page 6: Video Output VGA
    lcd.setCursor(2, 0);
    lcd.print("Video Output  ");
    lcd.setCursor(2, 1);
    lcd.print(" VGA          ");
}

float getTemp(){
// Read the thermistor value, convert it to Kelvin and then to Celsius
    int tempReading;
    double tempK;
    float tempC;

    tempReading = analogRead(PIN_TEMP);
    tempK = log(10000.0 * ((1024.0 / tempReading - 1)));
    tempK = 1 / (0.001129148 + (0.000234125 + (0.0000000876741 * tempK * tempK )) * tempK );
    tempC = tempK - 273.15;
    tempC -= TEMP_ADJUST;

    return tempC;
}

void switchFanOnOff(float temp){
// Switch fan ON or OFF depending on threshold (hysteresis applied)
    if((temp > MAXTEMP && !fanIsOn) || (temp < MINTEMP && fanIsOn)) hystCount++;
    else hystCount = 0;

    if(hystCount >= MAXHYSTERESIS){
        fanIsOn = !fanIsOn;
        digitalWrite(PIN_FAN, fanIsOn);
    }
}
