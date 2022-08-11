/******************************************************************************
 * VGA32_controller.ino
 *
 * The LILYGO TTGO VGA32 V1.4 is an ESP32 board with a VGA output that runs 
 * FABGL Library to provide an ANSI terminal.
 * 
 * This code was written by David Asta
 * FABGL Library is copyright of Fabrizio Di Vittorio
 * 
 * Version 1.0.0
 * Created on 11 Aug 2022
 * Last Modification 11 Aug 2022
 *******************************************************************************
 * CHANGELOG
 *   -
 *******************************************************************************
 */

/* -----------------------FABGL Library LICENSE NOTICE----------------------
 * Created by Fabrizio Di Vittorio (fdivitto2013@gmail.com) - <http://www.fabgl.com>
 * Copyright (c) 2019-2022 Fabrizio Di Vittorio.
 * All rights reserved.
 * 
 * Please contact fdivitto2013@gmail.com if you need a commercial license.
 * 
 * This library and related software is available under GPL v3.
 * 
 * FabGL is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * FabGL is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with FabGL.  If not, see <http://www.gnu.org/licenses/>.
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

#include "fabgl.h"

fabgl::VGA16Controller DisplayController;
fabgl::PS2Controller   PS2Controller;     // I'm not using the PS2 port, but without this nothing comes up on the screen
fabgl::Terminal        Terminal;

/*****************************************************************************/
void setup() {
  // I'm not using the PS2 port, but without this nothing comes up on the screen
  PS2Controller.begin(PS2Preset::KeyboardPort0_MousePort1);

  DisplayController.begin();
  DisplayController.setResolution(VGA_640x480_60Hz, -1, -1);

  Terminal.begin(&DisplayController, 0, 0);  // 0, 0 = Max columns, rows available on the monitor
  Terminal.loadFont(&fabgl::FONT_8x16);
  Terminal.setTerminalType(fabgl::ANSILegacy);
  Terminal.keyboard()->setLayout(&fabgl::UKLayout);
  Terminal.setBackgroundColor(Color::Black);
  Terminal.setForegroundColor(Color::White);
  Terminal.connectSerialPort(115200, 8, 'N', 1, 34, 2, FlowControl::None, false, -1, -1);
  Terminal.clear();
  Terminal.enableCursor(true);

  Terminal.write("* *  FabGL - Serial Terminal                            * *\r\n");
  Terminal.write("* *  2019-2022 by Fabrizio Di Vittorio - www.fabgl.com  * *\r\n\n");
}

/*****************************************************************************/
void loop() {}
