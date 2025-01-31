'' FMB_digital_length.spin
''
'' This program is the main program for the MACE FMB.
''
'' After the board has been calibrated using FMB_calibrate.spin, this
'' program should be programmed to the board's primary EEPROM
'' to then use the board to acquire measurements.
''
'' Note that this is in an early stage of development.  Many
'' features have not been developed.  Mainly code for controlling
'' the board via the user interface panel and some basic sensor
'' testing routines. These will be developed as time allows.
''
''
'' Rick Towler
'' IT Specialist
'' Midwater Asessment and Conservation Engineering Group
'' Alaska Fisheries Science Center
'' rick.towler@noaa.gov
''
'' Revision History:
''      Version 0.8 :
''          1. Initial Release by Rick Towler...
''
''
''      Version 0.9 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    29 Jan 2008
''          1. Added "readEEPROM" procedure to read calibration data from Boot EEPROM
''             on Parallax's Proto-board assembly. Had problems reading EEPROM using procedures
''             in "i2cObjec" object.  Used "Basic_I2C_Driver" object instead.
''
''          2. Added "writeEEPROM" procedure to write calibration data to Boot EEPROM
''             on Parallax's Proto-board assembly. Had problems writing EEPROM using procedures
''             in "i2cObject" object.  Used "Basic_I2C_Driver" object instead.
''
''          3. Added "Display_Menu" procedure which will allow us to display any type of menu
''             on the LCD display. Also added "Menu" data type in "DAT" section to control the look
''             of each menu..
''
''          4. Added "measure_Length" procedure to capture length measurement from the EP2 Linear-position
''             sensor and display value on the LCD screen as well as outputting the value on either
''             Bluetooth or RS-232 serial data communication channels.
''
''          5. Added "setup_FMB" procedure to grab all of the measuring board's calibration/setup variables from
''             EEPROM.
''
''      Version 0.91 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    30 July 2008
''          1. Added "getRawLength" procedure. This procedure will return the "RAW" length value from the
''             EP2 sensor. The reason for making this a procedure is so that when the calibration routine is added
''             to this code, the calibration will also be able to use this procedure.
''
''          2. Incorporated the Calibration routines into this code so that it can run from the main code. You
''             do not need to load the Calibration code separately when you want to do a calibration.  
''
''      Version 1.00 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    5 April 2010
''          1. Initial Firmware Release for production fishboards...
''
''      Version 1.01 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    26 May 2011
''          1. In an effort to speed up the response of the fishboard to length measurements,
''             modified constant "initDelay". Changed the value from 20,000,000 to 5,000,000.
''             This corresponds to a change in the initial delay time in making a measurement
''             from 250.0 msec to 62.5 msec.
''
''      Version 1.02 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    3 Nov 2011
''          1. Removed the 'cmd_PC := monitor_Comm' statement from the main REPEAT code of the MAIN procedure. This
''             statement allowed us to program the serial number for the Display Assembly. Moved this statement to
''             the initial boot process for the Display. The operator must press and hold the NEXT button for 5 sec. The
''             PROGRAMMING screen will then be displayed. At this point, the Display will monitor the RS232 COM port to wait for
''             programming commands. Once the programming is done, the Display assembly will continue the normal boot
''             process and enter the main REPEAT loop.
''
''      Version 1.10 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    14 Jan 2014
''          1. Changed the "nSamples" constant value to 1. This will speed up the fishboard measurements. "nSamples"
''             was used to counteract any movement of the measurement wand with respect to the fishboard when the
''             operator was making a measurement. This tended to slow down the board. Operators were complaining
''             about the lack of response of the fishboad.
''
''      Version 1.20 : Joseph M. Godlewski, NOAA/NMFS, NEFSC
''                    12 Dec 2014
''          1. As per converstation with Chuck Schroeder and Ian McCoy at the Southeast Fisheries Science Center (SEFSC),
''             added software changes to round the serial output when configured on "Limno" mode, for example: 
''              1.a With Decimal setting on, measurement displayed on screen 645.5mm will look like 0646.0rr on
''                  serial output.
''              1.b With Decimal setting off, measurement displayed on screen 646 mm will look like 0646.0rr on
''                  serial output.
''          2. Added variable "intTemp" to convert the "Float" length measurement to a rounded "Integer" for the Limnoterra length formatting.
''             (Changes made by SEFSC.)
''          3. Modified "measure_Length" procedure to convert the length measurement from a "Float" decimal number to a "rounded Integer"
''             value when formating the length output into the Limnoterra Fish Board (LIMNO) format. The reason for this modification
''             is due to the fact that the Limnoterra Boards would always round the decimal output to the nearest .0 mm length measurement. 
''             (Changes made by SEFSC.)
''             NOTE: Also need to change the format for the Ichthystick II output as well. When in "no_Decimal" mode, the length measurement
''                   needed to be rounded to the nearest .0 mm.
''          4. Previous versions of this firmware would allow intermitent length measurements to inadvertently register as the measurement wand
''             wandered across the sensor, especially if the wand had a strong magnet installed. This measurement would show up as a length of
''             approximately 910 mm, which is actually the area where a magnet is permanently attaced to the end of the sensor's measurement
''             zone. Modified the main IF statement in "measure_Length" function to make sure that the actual length value was larger than 0 and
''             less than the "thr" (Threshold) value which indicates the end of the sensor measurement area. See "measure_Length" function for
''             modifications.
''          5. The SEFSC discovered a bug in which the LED indicator on the Display Assembly's front panel would flash continually, while not allowing
''             any more length measurements to be made. I was able to duplicate this problem here at NEFSC as well. It seems that when the measurement
''             wand was placed close to the end of the senor's measurement zone (ie. near the permanently attached magnet on the sensor), the
''             interaction between the measurement wand's magnet and the permanently installed magnet would result in changing the "thr" value which
''             tells the firmware where the end of the sensor's valid measuring area is. This created a situation where the firmware would get stuck
''             in the "REPEAT WHILE" loop ("measure_Length" function) that handles the LED indicator flashing mechanism. Modified this loop to allow
''             for the recalculation of the "thr" value as well as putting a loop counter variable in the loop to allow for a graceful exit from the
''             loop in case the "thr" recalculation does not work. The system will return to normal once this "REPEAT WHILE" loop exits.
''             NOTE: Operators should not leave the measurement wand on the sensor after a measurement. This should be standard practice for any
''                   type of electronic fish measuring board.
''          6. Modified the "handle_Comm" function to bypass the option of changing the baud_Rate variable. The format of the fishboard output
''             determines the actual baud rate needed, so I just bypassed the code for changing baud_Rate. The Display will now show the proper
''             baud rate on the LCD when in the MENU section. (Originally, it was a bit confusing as to what the actual baud rate was depending on
''             what format you were in.)  Code is still there, so if anyone wants to add other baud_Rates, they have the ability.
''
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  FWVersion     = 1.20

  '  hardware pin-out and configuration parameters
  '  these values are specific to the MACE Digital Lengthboard Controller - modify as required
  
  serialRx      = 31                  '  RS232 serial out Rx pin
  serialTx      = 30                  '  RS232 serial out Tx pin
  serialBaud    = 9600                '  RS232 serial out baud rate
  b_serialRx    = 17                  '  Bluetooth serial in Rx pin  ---- NEFSC setup..
  b_serialTx    = 16                  '  Bluetooth serial out Tx pin ---- NEFSC setup..

' Used only for modifying certain parameters in the ESD110 Bluetooth Transceiver.
  ESD110        = 1                   '  Generate Serial Communication for ESD110 Bluetooth transceiver..
  RS232         = 0                   '  Generate Serial Communication for RS-232 port..

  LCDBaud       = 19_200              '  LCD baud rate ---- NEFSC setup..
  LCDLines      = 4                   '  Number of display lines on LCD
  LCDRx         = 9                   '  LCD Rx pin

  LEDOne        = 10

  menu_Button   = 12                  '  Interface board pin-outs  --- NEFSC setup..
  next_Button   = 13
  prev_Button   = 14
  entr_Button   = 15

  sound_pin     = 25                  '  Buzzer is tied to pin 25 of the microcontroller.

  i2cSDA        = 27                  '  Secondary EEPROM SDA pin
  i2cSCL        = 26                  '  Secondary EEPROM SCL pin
  EEPROM_ADDR   = %1010_0000          '  24LC256 ic2 device address

  '  Secondary EEPROM data addresses. Secondary EEPROM is used to store various calibration and setup parameters.
  
  lenAddr       = $0000               '  First byte is length of serial identifier stored on secondary EEPROM
  serAddr       = $0001               '  Serial Identifier occupies bytes $0001-$000F stored on secondary EEPROM
  stdAddr       = $0010               '  Address where sensor's standard value is stored on secondary EEPROM
  thrpAddr      = $0014               '  Address where sensor threshold percentage is stored on secondary EEPROM
  slpAddr       = $0018               '  Address where calibration slope is stored on secondary EEPROM
  intAddr       = $001C               '  Address where calibration intercept is stored on secondary EEPROM
  offAddr       = $0020               '  Address where calibration length offset is stored on secondary EEPROM

' ----------------------------------- NEFSC Setup... ------------------------------------------
  comAddr       = $0030               '  Address where communication-type flag is stored on secondary EEPROM.
                                      '  If value stored at this address = $A, then we want Bluetooth serial communication.
                                      '  If value stored at this address = $5, then we want RS-232 serial communication.

  baudAddr      = $0031               '  Address where communication baud rate is stored on secondary EEPROM.
                                      '  "baud_Rate" is a LONG variable and is stored in address $0031 to $0034.

  fmtAddr       = $0035               '  Address where Serial output format flag is stored on secondary EEPROM.
                                      '  If value stored at this address = 0, then we want Icthystick Serial Data format.
                                      '  If value stored at this address = 1, then we want Scantrol Serial Data format.

  measAddr      = $0040               '  Address where measurement-type flag is stored on secondary EEPROM.
                                      '  If value stored at this address = $0, then we want length measurement in MM.
                                      '  If value stored at this address = $1, then we want length measurement in CM.

  presAddr      = $0041               '  Address where measurement precision flag is stored on secondary EEPROM.
                                      '  If value stored at this address = $0, then we want length measurement with no decimal.
                                      '  If value stored at this address = $1, then we want length measurement with one decimal place.

  soundAddr     = $0050               '  Address where sound flag is stored on secondary EEPROM.
                                      '  If value stored at this address = $0, then we want to disable sound output.
                                      '  If value stored at this address = $1, then we want to enable sound output.

  oneByte       = 8                   '  Flag to read only one Byte [8  bits] from EEPROM...
  oneWord       = 16                  '  Flag to read only one Word [16 bits] from EEPROM...
  oneLong       = 32                  '  Flag to read only one Long Data Word [32 bits] from EEPROM...
' ---------------------------------------------------------------------------------------------

'  sensor sampling parameters
  
'  nSamples      = 5                   '  number of raw values sampled and average for one raw reading
  nSamples      = 1                   '  number of raw values sampled and average for one raw reading
  sampleDev     = 15                  '  max deviation (in raw units) between samples  (note ~30 raw units per mm)
'
' ----- Ver 1.01 -- Changed initDelay to 1,000,000 which corresponds to an initial delay time of 125.0 msec. ----
' initDelay     = 20_000_000          '  initial delay from when the stylus is "sensed" to when raw values are sampled
  initDelay     = 5_000_000           '  initial delay from when the stylus is "sensed" to when raw values are sampled
  sampDelay     = 1_000_000           '  inner loop delay (in clock cycles)
  sampRate      = 8_000_000           '  outer loop delay (in clock cycles)
  convert_mm    = 10                  '  Convert centimeter value to millimeter value. --- NEFSC setup..
  units_MM      = 0                   '  Flag to specify that we want measurement units in millimeters (mm).. --- NEFSC Setup.
  units_CM      = 1                   '  Flag to specify that we want measurement units in centimeters (cm).. --- NEFSC Setup.

  no_Decimal    = 0                   '  Flag to specify no decimal places will be displayed..                --- NEFSC Setup.
  one_Decimal   = 1                   '  Flag to specify decimal measurement will be to one decimal place..   --- NEFSC Setup.

  ON            = 1                   '  Generic ON  flag..  --- NEFSC setup
  OFF           = 0                   '  Generic OFF flag..  --- NEFSC setup

  HI            = 1                   '  Set HI indicator..  --- NEFSC setup
  LO            = 0                   '  Set LO indicator..  --- NEFSC setup

  blueTooth     = $A                  '  Flag for Bluetooth type communication setup..  --- NEFSC setup
  rs232_Ser     = $5                  '  Flag for RS232 type communication setup..      --- NEFSC setup

  fmt_ITHY      = 0                   '  Flag to specify that we want the Ithystick Serial output format..    --- NEFSC Setup.
  fmt_SCAN      = 1                   '  Flag to specify that we want the Scantrol Serial output format..     --- NEFSC Setup.
  fmt_LMNO      = 2                   '  Flag to specify that we want the Limnoterra Serial output format..   --- NEFSC Setup.

  delaytime     = 100                 '  Used to control the delay time for WAITCNT statements.  (ie. 0.1 seconds)
  soundtime     = 500                 '  Used to control the delay time for outputting a sound.  (ie. 0.5 seconds)

' ----- Ver 1.20 -- Added maxLoopCNT = 1,000,000,000 which corresponds to a delay time of 12.5 sec. -----------------------------------------------

  maxLoopCNT    = 100                 '  Max number of times the "LED Flashing" REPEAT loop in the "meas_Length" procedure will execute.
                                      '  When the measurement wand gets within approximately 2 CM of the magnet mounted at the end of the sensor,
                                      '  it tends to interfer with the electrical pulse generated at the sensor's end, thus changing the value of
                                      '  the "thr" value. When this happens, the "LED Flashing" REPEAT loop would get stuck in an infinite loop.
                                      '  Adding the "maxLoopCNT" variable will allow the REPEAT loop to exit gracefully if this condition occures.
                                      '  Once the REPEAT loop exits, a new value for "thr" will be calculated, and fishboard should return to
                                      '  normal measurement mode. This maxLoopCNT value translates into about 12 seconds of delay prior to the
                                      '  loop exiting. (Note: This condition only occures when someone leaves the measurement wand on the sensor
                                      '  after a valid measurement is taken near the end of the board. Remember, it is not good practice to leave
                                      '  measurement wand on the board sensor after you've taken a measurement. Try to avoid this at all costs.)
'---------------------------------------------------------------------------------------------------------------------------------------------------

'  Parameters that control which menu to display..

  Main_MNU      = 0                   '  Display Main Screen Data..   --- NEFSC setup
  Comm_MNU      = 1                   '  Display Communication Menu.. --- NEFSC setup
  Display_MNU   = 2                   '  Display DISPLAY Menu..       --- NEFSC setup
  Sound_MNU     = 3                   '  Display Sound Menu..         --- NEFSC setup
  Meas_MNU      = 4                   '  Display Measurement Menu..   --- NEFSC setup
  Cal_MNU       = 5                   '  Display Calibration Menu..   --- NEFSC setup
  Save_MNU      = 6                   '  Display Save Menu..          --- NEFSC setup

'  Calibration specific parameters

  threshPct     = 0.005               '  percentage of lengthboard                                                
  nCalPositions = 8                   '  number of values in the calPositions DAT block

'  Commands issued from PC to control Fishboard microcontroller functions..

  cPRGM         = $A                  '  "Program" ESD110 Bluetooth Transceiver..
  cPING         = $F                  '  "PING" command to Fishboard from PC. Fishboard will send "IFMB>" prompt to PC
  
OBJ
  sensor    : "mts_ep2d"
  lcd       : "Serial_Lcd"
  mcuSerial : "Extended_FDSerialNew"
  tstSer[2] : "Extended_FDSerialNew"
  f         : "FloatMath"
  fstr      : "FloatString"
  numbers   : "Simple_Numbers"
  base_i2c  : "Basic_I2C_Driver"

VAR

  long  lastRaw                       'Last RAW value read from sensor...
  long  stdLen                        'Temperature/humidity length compensation value.
  long  lenDisp[3]
  long  LINE0, LINE1, LINE2, LINE3    'Hold address of the String info for each LCD Line..   --- NEFSC setup..
  long  std                           'Sensor standard length..
  long  thrp                          'Sensor threshold percentage..
  long  slp                           'Slope of linear measurement values..
  long  int                           'Intercept of linear measurement values..
  long  lenMM                         'Actual length measurement converted to either MM or CM.
  long  thr                           'Maximum length measurement value for the FMB. Derived from "lastRaw" and "thrp".
  long  ofst                          'Offset value measured during calibration. Used to correct misalignment issures in forward position of FMB.
  byte  meas_units                    'Flag variable to determine which measurement units to use..  --- NEFSC setup..
  byte  num_Precision                 'Flag variable to determine what decimal precision to use..   --- NEFSC setup..
  byte  button_Sel                    'Flag variable to determine if a certain button is HI or LO.. --- NEFSC setup..

' Variables for RS-232/Bluetooth Communication...   --- NEFSC setup..
  byte  comm_Select                   'Flag to determine whether Bluetooth or RS-232 will be the serial comm channel...
  long  baud_Rate                     'Serial communication Baud rate in Bits per second.. (ie. 9600 bps)
  byte  comm_FMT                      'Flag to determine what format to use for the serial comm channel...
                                      '   Ithystk = "XXXXX.X mm" format where XXXX.X is the measurement value..
                                      '   Scantrl = ": 0235 001 LENGTH XXXXXXXXXXXXXXXXX.X   229 #8F" format, where the string simulates an output
                                      '             the Scantrol Length Boards.
  word  cmd_PC                        'Hold command received from PC..
  byte  rx_buffer[80]                 'Receive buffer for RS232 communications.
  byte  cSerNum[15]                   'Holds the Serial Number of the Fishboard. Allow us to change serial
                                      'number of the fishboard and the ESD110 bluetooth transceiver.

' Variables for LCD Display setup...   --- NEFSC setup..
  byte  backlight_LCD                 'Save state of LCD backlight...

' Variable for Sound setup...          --- NEFSC setup..
  byte  sound_State                   'Save state for the Sound.

' Variables for the Calibration Procedure. These are temporary variables that will be stored in EEPROM if user so desires.
  long  rawCalVals[nCalPositions]     'Raw calibration values returned for each of the calibration positions.
  long  stdVal                        'Current length of the FMB with no stylus applied to the board.
  long  mThresh                       'Threshold value of the length of the fishboard. mThresh -> stdVal - 0.005 %.
  long  slope                         'New value for the slope of the linear function determined from the calibration.
  long  intcpt                        'New y-intercept for the linear function.
  long  offset                        'Offset determined when measuring a calibrated 60 millimeter long rod. This value
                                      'is used to correct misalignment issues in forward position of fishboard...
  long  deltaOffset                   'Actual measurement difference between the calibrated 60 millimeter rod and the measured
                                      'value that we obtained from the FMB. This value will be stored in EEPROM.
  byte  calFlag                       'Flag indicating if the Calibration routine was performed.

' Variable to convert a decimal measurement value to a rounded Integer value. Correction to Limno formatting error discovered by SEFSC. Ver 1.20, JMG, 12 Dec 2014
  long  intTemp                       'Temp Integer to convert from Float to Integer after rounding.  Used in Limno rounding.

PUB Main | x, idx, proceed

  '  reset the front panel LED's
  dira[LEDOne]~~
  outa[LEDOne]~~                     ' Turn LEDOne on...

  '  initialize i2c object
  base_i2c.Initialize(i2cSCL)        ' Initialize Boot EEPROM.... Use for Protoboard only...
  
  '  initialize the LCD display
  lcd.Start(LCDRx, LCDBaud,LCDLines)
  lcd.cls
  lcd.backlight(ON)                   'Turn on the LCD backlight....
  backlight_LCD := ON                 'Save LCD backlight state...
  lcd.cursor(OFF)                     'Turn off the blinking cursor..

  '  set default floatString precision
' fstr.SetPrecision(1)

  '  STARTUP PROCESS
  lcd.str(string("Starting Ichthystick"))
  lcd.newline
  waitcnt(clkfreq + cnt)
  lcd.str(string("."))
  
  '  start control panel processes  - haven't written interface panel code

  waitcnt(clkfreq + cnt)
  lcd.str(string("."))

  '  test the sensor  - haven't written test code   

  waitcnt(clkfreq + cnt)
  lcd.str(string("."))

  '  display serial number
'  lcd.newline
  lcd.cls
  lcd.str(string("Serial ID: "))

'    Read in serial identifier length..

  idx := 0
  idx := readEEPROM(i2cSCL, EEPROM_ADDR, lenAddr, oneByte)

'    Read in serial number and store in variable "cSerNum"..
  if idx > 0 AND idx < 15

    bytefill(@cSerNum, 0, 15)
    repeat x from 0 to idx-1

      cSerNum[x] := readEEPROM(i2cSCL, EEPROM_ADDR, serAddr+x, oneByte)
      lcd.putc(cSerNum[x])
      waitcnt(150_000 + cnt)

  else
    lcd.str(string("NONE"))
    
'    Display firmware revision number...
  lcd.newline
  lcd.str(string("Firmware ver:"))
  lcd.str(fstr.FloatToFormat(FWVersion,4,2," "))
  lcd.newline
  waitcnt((3 * clkfreq) + cnt)
  lcd.cls

  '  Configure the FMB for operation..
  setup_FMB

  '  Look for NEXT button press..
  button_Sel := LO
  button_Sel := monitor_Button(next_Button)              'Check to see if NEXT button was pressed....

  if button_Sel == HI
    lcd.cls

    lcd.gotoxy(1,0)
    lcd.str(string("Programming"))
    proceed := 0
    repeat while proceed == 0
      cmd_PC := monitor_Comm                               ' Monitor the communication channel (RS232 or Bluetooth) to see
                                                           ' if PC wants to do something..

      if cmd_PC <> 0
        case cmd_PC
          cPRGM:                                           ' If "cPRGM" (program) command is received from the PC:
              handle_Program                               ' Program the ESD110 Bluetooth Transceiver...
              proceed := 1

          cPING:                                           ' If "cPING" (ping) command is received from the PC:
              handle_Ping                                  ' Send a message back to PC telling of Fishboard status...
              proceed := 0

'         OTHER:                                           ' If no command is received from the PC (default mode):
'             quit                                         ' Leave CASE statement, no message was received from the PC...

  outa[LEDOne]~                      ' Turn LEDOne off after FMB setup...

  '  Display main menu..
  lcd.cls
  Display_Menu(Main_MNU)
  case meas_units                                      'Insert measurement units at end of measurement text..
    units_MM:
      lcd.gotoxy(18,3)
      lcd.str(string("mm"))
    units_CM:
      lcd.gotoxy(18,3)
      lcd.str(string("cm"))

  '  start the sensor monitoring process
  sensor.start

  '  Calculate initial stdLen value. This variable compensates for heat/humidity variation
  ' as compared to the last calibration of the sensor.
  lastRaw := sensor.getPosition
  stdLen := f.FDiv(f.FFloat(lastRaw), f.FFloat(std))
  
    '  calculate measurement threshold
  thr := f.FMul(f.FFloat(lastRaw), thrp)
  thr := lastRaw - f.FRound(thr)

  
  repeat

    button_Sel := LO
    button_Sel := monitor_Button(menu_Button)              'Check to see if MENU button was pressed....

    if button_Sel == HI
      handle_Menu(button_Sel)                              'MENU button was pressed.  Lets handle the FMB configure changes..
      setup_FMB                                            'Init all variables associated with FMB to new values.
      lcd.cls
      Display_Menu(Main_MNU)
      case meas_units                                      'Insert measurement units at end of measurement text..
        units_MM:
          lcd.gotoxy(18,3)
          lcd.str(string("mm"))
        units_CM:
          lcd.gotoxy(18,3)
          lcd.str(string("cm"))

    measure_Length                       ' Get Length measurement from the Temposonics Linear-Position Sensor...
    
    waitcnt(sampRate + cnt)

  return

PUB  setup_FMB | x
''    This procedure will read the various calibration and setup parameters from EEPROM and store them in local variables
'' for use elsewhere in the code...
'' 

'     -------------  Get measurement variables from EEPROM. -------------
  std  := readEEPROM(i2cSCL, EEPROM_ADDR, stdAddr, oneLong)
  thrp := readEEPROM(i2cSCL, EEPROM_ADDR, thrpAddr, oneLong)
  slp  := readEEPROM(i2cSCL, EEPROM_ADDR, slpAddr, oneLong)
  int  := readEEPROM(i2cSCL, EEPROM_ADDR, intAddr, oneLong)
  ofst := readEEPROM(i2cSCL, EEPROM_ADDR, offAddr, oneLong)
  meas_units := readEEPROM(i2cSCL, EEPROM_ADDR, measAddr, oneByte)
  num_Precision := readEEPROM(i2cSCL, EEPROM_ADDR, presAddr, oneByte)

  '  set default floatString precision
' fstr.SetPrecision(num_Precision)

'     -------------  Get Communication variables from EEPROM. -------------
  comm_Select := readEEPROM(i2cSCL, EEPROM_ADDR, comAddr, oneByte)

  baud_Rate   := readEEPROM(i2cSCL, EEPROM_ADDR, baudAddr, oneLong)

' --- Check for default baud_Rate.. Need this if new EEProms are installed. -------
  if baud_Rate <> 9_600
    baud_Rate := 9_600
  
  comm_FMT    := readEEPROM(i2cSCL, EEPROM_ADDR, fmtAddr, oneByte)

'     -------------  Get Sound State variable from EEPROM. -------------
  sound_State := readEEPROM(i2cSCL, EEPROM_ADDR, soundAddr, oneByte)

  if comm_Select == blueTooth          ' Lets open an Bluetooth comm channel...
      lcd.gotoxy(0, 0)
      lcd.str(string("Starting Bluetooth  "))
{
    Notes on Parani ESD110 Bluetooth device:
    
         The Parani ESD110 Bluetooth module comes from the factory with a default MODE
         equal to "MODE0" --> Bluetooth Device is waiting for AT commands.. In this mode,
         the Parani ESD110 module will not connect to any other device until the command
         AT+BTSCAN is issued.  However, when the Parani ESD110 is set to "MODE3" using
         command "AT+BTMODE3", the device will automatically go into a mode where the
         module will sit and wait for a MASTER bluetooth device to connect. Prior to installing
         a new Parani ESD110 Bluetooth module onto the FMB circuit board, make sure this
         device is set to "MODE3".  See Parani ESD110 manual for more information.

 }                                         
      mcuSerial.start(b_serialRx, b_serialTx, 0, baud_Rate)
      repeat x from 1 to 30
        waitcnt(clkfreq / 10 + cnt)       ' Wait 3 seconds to make sure ESD110 Bluetooth module is ready.

  else
      lcd.gotoxy(0, 0)
      lcd.str(string("Starting RS-232     "))
      repeat x from 1 to 30
        waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

      if comm_FMT == fmt_LMNO
        mcuSerial.start(serialRx, serialTx, 0, 1_200)
      else    
        mcuSerial.start(serialRx, serialTx, 0, baud_Rate)

  return

PUB  monitor_Comm : rData | x, data_str, pData_str
''    This procedure will monitor the default comm port (either Bluetooth or RS-232) and return any commands received
'' from the PC.. Variable "rData" is the receive buffer which will store the commands/data received from the PC.

  rData := mcuSerial.rxHexTime(500)
  return
 
PUB  handle_Program | check_Data, cData, dData, cmd, cNum, rcvd, i, x, numLength
''    This procedure will handle the interaction between the PC, the Parallax microcontroller, and Parani ESD110 Bluetooth Transceiver.
'' This interface will allow us to program the ESD110 Bluetooth Transceiver and the Fishboard Serial Number.
''
  mcuSerial.stop                                        'Stop normal Serial Communications.

' ------ Let's setup a communication path from the PC to the ESD110, through the microcontroller. -------
'
' Open up a test serial port with the PC on the RS232 connector..
  tstSer[RS232].start(serialRx, serialTx, 0, 9_600)

' Open up a test serial port with the Bluetooth Transceiver..
  tstSer[ESD110].start(b_serialRx, b_serialTx, 0, 9_600)
'--------------------------------------------------------------------------------------------------------

  repeat
    cmd := program_Menu
    case cmd
      1:                                                'Change Serial Numbers of fishboard and ESD110.

        repeat
          cNum := string("IFMB")                        'Standard beginning of serial number ID.
          bytefill(@cSerNum, 0, 15)
          bytemove(@cSerNum, cNum, strsize(cNum))
        
          tstSer[RS232].str(string("Enter device Serial Number and press ENTER:"))
          tstSer[RS232].str(string(13,10))
          tstSer[RS232].str(string("Note: Number should be between 1 and 999."))
          tstSer[RS232].str(string(13,10))
          tstSer[RS232].str(string(">>"))
          tstSer[RS232].rxflush                         'Flush the receive buffer...
          tstSer[RS232].RxStr(@cData)                   'Get the data from the PC.

          dData := StrToFloat(@cData)                   'Convert string DATA to a decimal..
          check_Data := f.FTrunc(dData)                 'Convert decimal value into an integer value.

          if check_Data => 1 AND check_Data =< 999
        
                cData := fstr.FloatToFormat(dData, 3, 0, "0")
        
                bytemove(@cSerNum + strsize(@cSerNum), cData, strsize(cData)+1) 'Append number to "IFMB"
                numLength := strsize(@cSerNum)
                
'----------------------------- Write Serial Number Length to EEPROM. -----------------------------
                ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, lenAddr, oneByte, numLength)
                  tstSer[RS232].str(string("Error Writing SerNum Length to EEPROM."))
                  tstSer[RS232].str(string(13,10))

'----------------------------- Write Actual Serial Number to EEPROM. -----------------------------
                repeat x from 0 to numLength-1
                  writeEEPROM(i2cSCL, EEPROM_ADDR, serAddr+x, oneByte, cSerNum[x])
                  waitcnt(clkfreq / 10 + cnt)           'Wait for 100 milliseconds.

'----------------------------- Change Name of ESD110 Bluetooth Transceiver. -----------------------------
                tstSer[ESD110].str(string("AT+BTCANCEL")) 'Set Bluetooth Device into "Standby" mode.
                tstSer[ESD110].str(string(13,10))
                waitcnt(clkfreq / 10 + cnt)             'Wait for 100 milliseconds.
                tstSer[ESD110].rxflush                  'Flush the receive buffer...

                tstSer[ESD110].str(string("AT+BTNAME=")) 'Command for changing name of Bluetooth Device.
                tstSer[ESD110].str(string(34))          'Name needs to be inclosed in quotes -> " = hex22 = dec34
                tstSer[ESD110].str(@cSerNum)
                tstSer[ESD110].str(string(34))          'Name needs to be inclosed in quotes -> " = hex22 = dec34
                tstSer[ESD110].str(string(13,10))
                waitcnt(clkfreq / 10 + cnt)             'Wait for 100 milliseconds.
                tstSer[ESD110].rxflush                  'Flush the receive buffer...

                tstSer[ESD110].str(string("ATZ"))       'Reboot Bluetooth Device.
                tstSer[ESD110].str(string(13,10))
                waitcnt(clkfreq / 10 + cnt)             'Wait for 100 milliseconds.
                tstSer[ESD110].rxflush                  'Flush the receive buffer...


                tstSer[RS232].str(string("Serial Number changed to: "))
                tstSer[RS232].str(@cSerNum)
                tstSer[RS232].str(string(13,10))
                quit
          else
                tstSer[RS232].str(string("Number was not between 1 and 999. "))
                tstSer[RS232].str(string(13,10))
                tstSer[RS232].str(string("Try again.......... "))
                tstSer[RS232].str(string(13,10))
                tstSer[RS232].str(string(13,10))
                

      2:
        tstSer[RS232].str(string("Changing ESD110 Mode value to MODE3.."))
        tstSer[RS232].str(string(13,10))
 
'----------------------------- Change Name of ESD110 Bluetooth Transceiver. -----------------------------
        tstSer[ESD110].str(string("AT+BTCANCEL"))       'Set Bluetooth Device into "Standby" mode.
        tstSer[ESD110].str(string(13,10))
        waitcnt(clkfreq / 10 + cnt)                     'Wait for 100 milliseconds.
 
        tstSer[ESD110].str(string("AT+BTMODE,3"))       'Command for changing MODE of Bluetooth Device.
        tstSer[ESD110].str(string(13,10))
        waitcnt(clkfreq / 10 + cnt)                     'Wait for 100 milliseconds.

'----------------------------- Output ESD110 Parameters to user. -----------------------------
        bytefill(@rx_buffer, 0, 80)

        tstSer[ESD110].str(string("AT+BTINFO?"))        'Display bluetooth settings.
        tstSer[ESD110].str(string(13,10))
        waitcnt(clkfreq / 10 + cnt)                     'Wait for 100 milliseconds.
        rcvd := tstSer[ESD110].RxTime(9600)             'First character in any response is a "CR"
        if rcvd <> -1
          i := 0
          repeat until rcvd == -1
                rcvd := tstSer[ESD110].RxTime(9600)     'Grab next character
                rx_buffer[i] := rcvd                    'Copy to receive buffer
                i++                                     'Increment buffer index
                
          rx_buffer[i-1] := 0                           'Zero terminate receive buffer
          tstSer[RS232].str(string(13,10))
          tstSer[RS232].str(string("ESD110 Bluetooth Parameters: "))
          tstSer[RS232].str(string(13,10))
          tstSer[RS232].str(@rx_buffer)                 'Output buffer to RS232
          tstSer[RS232].str(string(13,10))

      3:
        tstSer[RS232].str(string("Quitting Menu."))
        tstSer[RS232].str(string(13,10))
        waitcnt(clkfreq / 10 + cnt)       ' Display message for 1 seconds.

'------------- Stop the test serial connections between the PC and ESD110. ---------
        tstSer[RS232].stop
        tstSer[ESD110].stop
'-----------------------------------------------------------------------------------
        lcd.cls
        setup_FMB                                       ' Restart the Fishboard to begin normal operations.
        lcd.cls
        Display_Menu(Main_MNU)
        quit                                            ' Exit CASE and REPEAT statement and return...
      OTHER:
        tstSer[RS232].str(string("Invalid Menu Item........."))
        tstSer[RS232].str(string("Enter only numbers 1 to 3."))
        tstSer[RS232].str(string(13,10))

  return
 
PUB  program_Menu : rCmd 
''    This procedure will output a menu to the RS-232 port to allow the operator to change the serial number
'' of the Fishboard and ESD110 devices, as well as change the ESD110 Mode number.

  tstSer[RS232].str(string("-------------------------------------------------------"))
  tstSer[RS232].str(string(13,10))
  tstSer[RS232].str(string("1: Change Device Serial Number."))
  tstSer[RS232].str(string(13,10))
  tstSer[RS232].str(string("2: Change ESD110 Mode Number."))
  tstSer[RS232].str(string(13,10))
  tstSer[RS232].str(string("3: Quit Menu and return."))
  tstSer[RS232].str(string(13,10))
  tstSer[RS232].str(string("-------------------------------------------------------"))
  tstSer[RS232].str(string(13,10))
  tstSer[RS232].str(string("Enter Menu number and press return key."))
  tstSer[RS232].str(string(13,10))
  tstSer[RS232].str(string(">>"))

  rCmd := tstSer[RS232].rxHex                                  ' Wait for a command from the user...
  tstSer[RS232].rxflush                                        ' Flush the receive buffer...
  
  return
 
PUB  handle_Ping | x
''    This procedure will let the PC know that the fishboard is up and running...

  mcuSerial.str(string("Icthystick Fishboard is operational."))
  mcuSerial.str(string(13,10))

  return  

PUB  handle_Menu(HI_LO) | count
''  This procedure will control what is to be done when the MENU button is selected. Various sub-procedures
''will be called to handle all of the menu items as well as store all the calibration/variable changes for
''the FMB..            
''

  mcuSerial.stop                        ' Stop serial data communications...
  count := 1                            ' Set counter to 1.
  repeat count from 1 to 6

      case count
        1:
          Display_Menu(Comm_MNU)        ' Display the Communication menu...
          handle_Comm                   ' Handle the configuration changes for the serial communications..
        2:
          Display_Menu(Display_MNU)     ' Display the Display menu...
          handle_Disp                   ' Handle the LCD display changes.
        3:
          Display_Menu(Sound_MNU)       ' Display the Sound menu...
          handle_Sound                  ' Handle the Sound configuration changes.
        4:
          Display_Menu(Meas_MNU)        ' Display the Measure menu...
          handle_Meas                   ' Handle the length measurement unit changes.
        5:
          Display_Menu(Cal_MNU)         ' Display the Calibration menu...
          handle_Cal                    ' Handle the Save/Quit preference..
        6:
          Display_Menu(Save_MNU)        ' Display the Save Config menu...
          handle_Save                   ' Handle the Save/Quit preference..
          quit

  lcd.cls                               ' Clear the LCD Screen...

  return

PUB  handle_Comm | menu_item, protocol, baud, format, tmp_Baudrate, x
''  This procedure will handle all the configuration changes required for the FMB communication channels. This menu will
''allow the operator to change the following variables:                              
''        comm_Select = RS-232 or Bluetooth
''        baud_Rate   = 9600 BPS.
''        comm_FMT    = "Icthysk", "Limno", or "Scantrl"
''
''Initial Communication Menu:
''            ┌────────────────────┐   Note: The Display is a 4X20 Serial LCD
''            │Communication Menu: │         Backlit, Prix (P/N 27979) from Parallax, Inc.
''            │ Protocol:  RS-232 <│  <--- Or "BlueTH" depending on what "comm_Select" is..
''            │ BAUD Rate: 9600    │  <--- Note: "baud_Rate" is default at 9600.. We could add different baud rates at a later time.
''            │ Format:    Icthysk │  <--- "Limno" Or "Scantrl" depending on what type of output we would like coming from Serial Channel..
''            └────────────────────┘
''

  protocol  := 0
  baud      := 1
  format    := 2

  lcd.gotoxy(12,1)                                      'Go to the "Protocol:" Line, and insert either RS-232 or BlueTH text..
  case comm_Select
    rs232_Ser:
      lcd.str(string("RS-232"))

    blueTooth:
      lcd.str(string("BlueTH"))

    OTHER:                                              'Default to RS-232...
      comm_Select := rs232_Ser
      lcd.str(string("RS-232"))
    
  lcd.gotoxy(12,2)                                      'Go to the "BAUD Rate:" Line, and insert either 9600 text..

  if comm_FMT == fmt_LMNO                               'If format equals LIMNO mode, change baud rate to 1200. Ver 1.20, JMG, 12 Dec 2014
    baud_Rate := 1200
    
  tmp_Baudrate := baud_Rate
  case baud_Rate
'    4800:
'      lcd.str(string("4800"))
    1200:                                               'Added baud rate for Limno format. Ver 1.20, JMG, 12 Dec 2014
      lcd.str(string("1200"))
    9600:
      lcd.str(string("9600"))
    OTHER:                                              'Default to a baud_rate = 9600
      baud_Rate := 9600
      lcd.str(string("9600"))

  lcd.gotoxy(12,3)                                      'Go to the "Format:" Line, and insert either "Icthysk" or "Scantrl" text..
  case comm_FMT
    fmt_SCAN:
      lcd.str(string("Scantrl"))                        'Display "Scantrl" on Format line if "comm_FMT" = fmt_SCAN = 0
    fmt_ITHY:
      lcd.str(string("Icthsyk"))                        'Display "Icthysk" on Format line if "comm_FMT" = fmt_ITHY = 1
    fmt_LMNO:
      lcd.str(string("Limno  "))                        'Display "Limno  " on Format line if "comm_FMT" = fmt_LMNO = 2                        
    OTHER:
      comm_FMT := fmt_ITHY
      lcd.str(string("Icthsyk"))                        'Default Display "Icthysk" on Format line.

  menu_item := protocol
  repeat while (monitor_button(menu_Button)) == LO

    if menu_item == protocol
      lcd.gotoxy(19,1)                                  'Draw arrow "<" character next to "Protocol" field..
      lcd.str(string("<"))
      if (monitor_button(next_Button)) == HI            'Check to see if NEXT button has been pressed.
                                                        'If so, let's switch to BAUD field.
        'menu_item := baud
        menu_item := format                             'Disabled the "baud" section of the menu. The BAUD display will show the baud rate of
                                                        'of the currently selected serial output "format". Ver 1.20, JMG 12 Dec 2014.
      elseif (monitor_button(prev_Button)) == HI        'Check to see if PREV button has been pressed.
                                                        'If so, let's switch to FORMAT field.
        menu_item := format
      else
        if (monitor_button(entr_Button)) == HI          'Check to see if ENTER button was pressed.  Enter button will change
                                                        'the displayed variable.
          case comm_Select                              'If we are currently in RS-232 communication mode, change to
            rs232_Ser:                                  'Bluetooth mode..
              comm_Select := blueTooth
              lcd.gotoxy(12,1)
              lcd.str(string("BlueTH"))

            blueTooth:                                  'If we are currently in Bluetooth communication mode, change to
              comm_Select := rs232_Ser                  'RS-232 mode..
              lcd.gotoxy(12,1)
              lcd.str(string("RS-232"))

      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
      lcd.gotoxy(19,1)                                  'Clear arrow "<" character next to "Protocol" field..
      lcd.str(string(" "))
      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.

    elseif menu_item == baud
      lcd.gotoxy(19,2)                                  'Draw arrow "<" character next to "BAUD Rate" field..
      lcd.str(string("<"))
      if (monitor_button(next_Button)) == HI            'Check to see if NEXT button has been pressed.
                                                        'If so, let's switch to Protocol field.
        menu_item := format
      elseif (monitor_button(prev_Button)) == HI        'Check to see if PREV button has been pressed.
                                                        'If so, let's switch to PROTOCOL field.
        menu_item := protocol
      else
        if (monitor_button(entr_Button)) == HI          'Check to see if ENTER button was pressed.  Enter button will change
                                                        'the displayed variable.
          case tmp_Baudrate                                
{           4800:                                       'If we currently have a BAUD rate = 4800, change to 9600..
              tmp_Baudrate := 9600
              lcd.gotoxy(12,2)
              lcd.str(string("9600  "))
}
            9600:                                       'If we currently have a BAUD rate = 9600, change to 9600..
              tmp_Baudrate := 9600
              lcd.gotoxy(12,2)
              lcd.str(string("9600  "))


      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
      lcd.gotoxy(19,2)                                  'Clear arrow "<" character next to "Protocol" field..
      lcd.str(string(" "))
      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
 
    else
      lcd.gotoxy(19,3)                                  'Draw arrow "<" character next to "Format" field..
      lcd.str(string("<"))
      if (monitor_button(next_Button)) == HI            'Check to see if NEXT button has been pressed.
                                                        'If so, let's switch to Protocol field.
        menu_item := protocol
      elseif (monitor_button(prev_Button)) == HI        'Check to see if PREV button has been pressed.
                                                        'If so, let's switch to BAUD field.
        'menu_item := baud
        menu_item := protocol                           'Disabled the "baud" section of the menu. The BAUD display will show the baud rate of
                                                        'of the currently selected serial output "format". Ver 1.20, JMG 12 Dec 2014.
      else
        if (monitor_button(entr_Button)) == HI          'Check to see if ENTER button was pressed.  Enter button will change
                                                        'the displayed variable.
          case comm_FMT                                    

            fmt_ITHY:                                   'If we currently have the format set to Icthystick, change to Scantrol..
              comm_FMT := fmt_SCAN
              lcd.gotoxy(12,3)
              lcd.str(string("Scantrl"))
              lcd.gotoxy(12,2)                          'Add the baud rate for Scantrol on the LCD display. Ver 1.20, JMG, 12 Dec 2014
              lcd.str(string("9600  "))                 'Scantrol format is set to 9600 baud.
              baud_Rate := 9600                         'Set baud rate for Scantrol format.

            fmt_SCAN:                                   'If we currently have the format set to Scantrol, change to Limnoterra..
              comm_FMT := fmt_LMNO
              lcd.gotoxy(12,3)
              lcd.str(string("Limno  "))                                        
              lcd.gotoxy(12,2)                          'Add the baud rate for Limnoterra on the LCD display. Ver 1.20, JMG, 12 Dec 2014
              lcd.str(string("1200  "))                 'Limno format is set to 1200 baud.
              baud_Rate := 1200                         'Set baud rate for Limnoterra format.

            fmt_LMNO:                                   'If we currently have the format set to Limnoterra, change to Icthystick..
              comm_FMT := fmt_ITHY
              lcd.gotoxy(12,3)
              lcd.str(string("Icthysk"))
              lcd.gotoxy(12,2)                          'Add the baud rate for Icthysk on the LCD display. Ver 1.20, JMG, 12 Dec 2014
              lcd.str(string("9600  "))                 'Icthysk format is set to 9600 baud.
              baud_Rate := 9600                         'Set baud rate for Ichthystick format.
 
            OTHER:                                      'Default to a communication format = Icthystick...
              comm_FMT := fmt_ITHY
              lcd.gotoxy(12,3)
              lcd.str(string("Icthysk"))
              lcd.gotoxy(12,2)                          'Add the baud rate for Icthysk on the LCD display. Ver 1.20, JMG, 12 Dec 2014
              lcd.str(string("9600  "))                 'Icthysk format is set to 9600 baud.
 

      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
      lcd.gotoxy(19,3)                                  'Clear arrow "<" character next to "Protocol" field..
      lcd.str(string(" "))
      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.


  return

PUB  handle_Disp | x
''  This procedure will handle all the configuration changes required for the LCD display. It will allow the operator
'' to turn ON/OFF the LCD backlighting..  We will NOT save this value to EEPROM (no need!!).  We will always power up
'' the FMB with the LCD backlighting ON. If the operator wants to turn the backlighting OFF, he can do it in this menu..
''
'' Display Menu:
''              ┌────────────────────┐   Note: The Display is a 4X20 Serial LCD
''              │Display Menu:       │         Backlit, Prix (P/N 27979) from Parallax, Inc.
''              │                    │
''              │ Backlighting: OFF  │
''              │                    │
''              └────────────────────┘
  lcd.gotoxy(15,2)                                      'Go to the "Backlighting:" Line, and insert either ON or OFF text..
  case backlight_LCD
    ON:                                                 'Display "ON " after "Backlighting:" text...
      lcd.str(string("ON "))
    OFF:                                                'Display "OFF " after "Backlighting:" text...
      lcd.str(string("OFF"))
    OTHER:                                              'Default to backlighting ON...
      backlight_LCD := ON
      lcd.backlight(ON)                                 'Turn the LCD backlight OFF....
      lcd.str(string("ON "))

  repeat while (monitor_button(menu_Button)) == LO
    
    lcd.gotoxy(19,2)                                    'Draw arrow "<" character next to "UNITS:" field..
    lcd.str(string("<"))
    if (monitor_button(entr_Button)) == HI              'Check to see if ENTER button was pressed.  Enter button will change
                                                        'the displayed variable.
        case backlight_LCD                                
          ON:                                           'If the LCD backlighting is currently ON, let's turn it OFF..
            backlight_LCD := OFF                      
            lcd.backlight(OFF)                          'Turn the LCD backlight OFF....
            lcd.gotoxy(15,2)
            lcd.str(string("OFF"))

          OFF:                                          'If the LCD backlighting is currently OFF, let's turn it ON..
            backlight_LCD := ON                      
            lcd.backlight(ON)                          'Turn the LCD backlight ON....
            lcd.gotoxy(15,2)
            lcd.str(string("ON "))

    repeat x from 1 to 2
      waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
    lcd.gotoxy(19,2)                                  'Clear arrow "<" character next to "Protocol" field..
    lcd.str(string(" "))
    repeat x from 1 to 2
      waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.

  return

PUB  handle_Sound | x
''  This procedure will handle all the configuration changes required for the Sound control. It will allow the operator
'' to turn FMB sound ON/OFF..  We will NOT save this value to EEPROM (no need!!).  We will always power up
'' the FMB with sound turned ON. If the operator wants to turn the sound OFF, he can do it in this menu..
''
'' Sound Menu:
''              ┌────────────────────┐   Note: The Display is a 4X20 Serial LCD
''              │Sound Menu:         │         Backlit, Prix (P/N 27979) from Parallax, Inc.
''              │                    │
''              │ Sound: OFF         │
''              │                    │
''              └────────────────────┘
  lcd.gotoxy(8,2)                                       'Go to the "Sound:" Line, and insert either ON or OFF text..
  case sound_State
    ON:                                                 'Display "ON " after "Sound:" text...
      lcd.str(string("ON "))
    OFF:                                                'Display "OFF " after "Sound:" text...
      lcd.str(string("OFF"))
    OTHER:                                              'Default to sound ON...
      sound_State := ON
      lcd.str(string("ON "))

  repeat while (monitor_button(menu_Button)) == LO
    
    lcd.gotoxy(12,2)                                    'Draw arrow "<" character next to "UNITS:" field..
    lcd.str(string("<"))
    if (monitor_button(entr_Button)) == HI              'Check to see if ENTER button was pressed.  Enter button will change
                                                        'the displayed variable.
        case sound_State                                
          ON:                                           'If the sound is currently ON, let's turn it OFF..
            sound_State := OFF                      
            lcd.gotoxy(8,2)
            lcd.str(string("OFF"))

          OFF:                                          'If the sound is currently OFF, let's turn it ON..
            sound_State := ON                      
            beep(soundtime, sound_pin)
            lcd.gotoxy(8,2)
            lcd.str(string("ON "))

    repeat x from 1 to 2
      waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
    lcd.gotoxy(12,2)                                  'Clear arrow "<" character next to "Protocol" field..
    lcd.str(string(" "))
    repeat x from 1 to 2
      waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.

  return

PUB  handle_Meas | menu_item, units, precision, x
''  This procedure will handle all the configuration changes required for the measurements units. It will allow the
'' the operator to select either centimeter (CM) or millimeter (MM) units of measurement..
''
'' Measurement Menu:
''              ┌────────────────────┐   Note: The Display is a 4X20 Serial LCD
''              │Measurement Menu:   │         Backlit, Prix (P/N 27979) from Parallax, Inc.
''              │                    │
''              │ UNITS: MM          │
''              │ DEC:   XXXX.X      │
''              └────────────────────┘

  units     := 0
  precision := 1

  lcd.gotoxy(8,2)                                       'Go to the "Units:" Line, and insert either MM or CM text..
  case meas_units
    units_MM:                                           'Display "MM" on Units line if "meas_units" = units_MM = $0
      lcd.str(string("MM"))
    units_CM:                                           'Display "CM" on Units line if "meas_units" = units_CM = $1
      lcd.str(string("CM"))
    OTHER:                                              'Default to millimeter measurement units...
      meas_units := units_MM
      lcd.str(string("MM"))

  lcd.gotoxy(8,3)
  case num_Precision                                        
    one_decimal:                                        'Display "XXXX.X" on Precision line if "num_Precision" = one_Decimal = $1
      num_Precision := one_decimal
      lcd.str(string("XXXX.X "))
    no_decimal:                                         'Display "XXXXXX" on Precision line if "num_Precision" = no_Decimal = $0
      num_Precision := no_decimal
      lcd.str(string("XXXXXX "))
    OTHER:                                              'Default to one_decimal precision..
      num_Precision := one_decimal
      lcd.str(string("XXXX.X "))

  menu_item := units
  repeat while (monitor_button(menu_Button)) == LO
    
    if menu_item == units
      lcd.gotoxy(19,2)                                'Draw arrow "<" character next to "UNITS:" field..
      lcd.str(string("<"))
      if (monitor_button(next_Button)) == HI          'Check to see if NEXT button has been pressed.
                                                      'If so, let's switch to PRECISION field.
        menu_item := precision

      elseif (monitor_button(prev_Button)) == HI      'Check to see if PREV button has been pressed.
                                                      'If so, let's switch to PRECISION field.
        menu_item := precision

      else
        if (monitor_button(entr_Button)) == HI        'Check to see if ENTER button was pressed.  Enter button will change
                                                      'the displayed variable.
          case meas_units                                
            units_MM:                                 'If we are currently displaying length in millimeters, let's change
              meas_units := units_CM                  'length measurements to centimeters..
              lcd.gotoxy(8,2)
              lcd.str(string("CM"))

            units_CM:                                 'If we are currently displaying length in centimeters, let's change
              meas_units := units_MM                  'length measurements to millimeters..
              lcd.gotoxy(8,2)
              lcd.str(string("MM"))

      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                   'Display message on screen for 0.2 seconds.
      lcd.gotoxy(19,2)                                'Clear arrow "<" character next to "Protocol" field..
      lcd.str(string(" "))
      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                   'Display message on screen for 0.2 seconds.
    else
      lcd.gotoxy(19,3)                                'Draw arrow "<" character next to "BAUD Rate" field..
      lcd.str(string("<"))
      if (monitor_button(prev_Button)) == HI            'Check to see if PREV button has been pressed.
                                                        'If so, let's switch to Protocol field.
        menu_item := units

      elseif (monitor_button(next_Button)) == HI      'Check to see if NEXT button has been pressed.
                                                      'If so, let's switch to UNITS field.
        menu_item := units

      else
        if (monitor_button(entr_Button)) == HI          'Check to see if ENTER button was pressed.  Enter button will change
                                                        'the displayed variable.
          case num_Precision                                
            no_decimal:                                 'If we currently have no decimal precision, change to one_decimal..
              num_Precision := one_decimal
              lcd.gotoxy(8,3)
              lcd.str(string("XXXX.X "))

            one_decimal:                                'If we currently have one_decimal precision, change to no_decimal..
              num_Precision := no_decimal
              lcd.gotoxy(8,3)
              lcd.str(string("XXXXXX "))

      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.
      lcd.gotoxy(19,3)                                  'Clear arrow "<" character next to "Protocol" field..
      lcd.str(string(" "))
      repeat x from 1 to 2
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.2 seconds.

  return

PUB  handle_Cal | n, x
''  This procedure performs a series of measurements to calculate the
''  slope and intercept of the linear function that converts raw
''  sensor values to millimeters.  You can specify the number of 
''  measurements and their locations.  Slopes are calculated between
''  these points and averaged.  Then an intercept is calculated. These
''  values are then stored in the secondary EEPROM.
''
''  The fishboard uses a fixed magnet placed just inside the far end of
''  the measurement stroke of the sensor as an internal reference
''  to allow the board to compensate for changes in density of the
''  sensor's magnetostrictive wire as a function of temperature.  This
''  procedure records and stores the raw value of the fixed magnet
''  at the time of calibration. This value is then used during normal
''  operation to calculate a temperature compensation factor.
''
''  This procedure also stores the boards raw threshold percentage. This
''  value is the percentage of the total sensor length (starting from
''  the reference magnet) that is defined as dead space. If a raw value
''  is returned from the sensor w/in this dead space no measurement is
''  taken. This provides a bit of a buffer so that noise in the sensor
''  signal doesn't trigger an erroneous reading. 
''
''Calibration Menu:
''            ┌────────────────────┐   Note: The Display is a 4X20 Serial LCD
''            │Calibration Menu:   │         Backlit, Prix (P/N 27979) from Parallax, Inc.
''            │                    │
''            │Press ENT begin CAL │  <--- Begin FMB Calibration routine..
''            │Press MNU to Quit   │  <--- Exit Calibration menu without performing cal..
''            └────────────────────┘
''
  calFlag := 0                                          'Initialize calibration flag to 0, indicating calibration wasn't performed.
  repeat

    if (monitor_button(menu_Button)) == HI              'If MNU button is pressed, we want to quit the Calibration routine without
                                                        'changing any calibration values...
      lcd.cls
      lcd.str(string("QUIT CALIBRATION"))
      repeat x from 1 to 50
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.5 seconds.
      quit
    if (monitor_button(entr_Button)) == HI              'If ENT button is pressed, we want to perform a calibration on the FMB.
                                                        'Let's perform the calibration, and save the calibration factors in temporary
                                                        'variables for saving at a later time.
      calFlag := 1                                      'Set calibration flag to 1, indicating we are performing a calibration.
      lcd.cls
      lcd.str(string("BEGIN CALIBRATION"))
  '  tell the user to remove the stylus from the board
      displayRemoveText(5, 1) 

  '  get board standard value
      stdVal := sensor.getPosition
  '  calculate measurement threshold
      mThresh := f.FMul(f.FFloat(stdVal), threshPct)
      mThresh := stdVal - f.FRound(mThresh)

  '  take raw readings at specified positions
      repeat n from 0 to nCalPositions - 1
        rawCalVals[n] := getCalSample(calPositions[n])

  '  calculate slope
      slope := calcAvgSlope

  '  calculate intercept
      intcpt := f.FMul(f.FFloat(rawCalVals[0]), slope)
      intcpt := f.FSub(f.FFloat(calPositions[0]), intcpt)

  '  Now let's determine an offset if there is one....
  '  The "getCalOffset" procedure will ask the operator to place the measurement device at the zero position on the fishboard
  '  and take a measurement. The actual measurement value made will be compared to 0 mm length to determine an 
  '  offset value....
  '
      offset := getCalOffset

      if offset > 0
        
        offset := f.FMul(offset, slope)
        offset := f.FAdd(offset, intcpt)
        deltaOffset := f.FAdd(0.0, f.Fneg(offset))        'Calculate the actual measurement offset from the theoretical.
        lcd.cls
        lcd.str(string("Offset Value:"))
        lcd.gotoxy(0, 1)
        lcd.str(fstr.FloatToFormat(deltaOffset, 8, 5, "0"))

        repeat x from 1 to 50
          waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.5 seconds.

      lcd.cls
      lcd.str(string("CALIBRATION"))
      lcd.gotoxy(0, 1)
      lcd.str(string("COMPLETE..."))
      repeat x from 1 to 50
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.5 seconds.
      quit

  return

PUB  handle_Save | menu_item, protocol, baud, x
''  This procedure will ask the operator if he wants to save the configuration changes (using ENT key)
'' or quit without saving changes (using MNU key).
''
''Save Configuration Menu:
''            ┌────────────────────┐   Note: The Display is a 4X20 Serial LCD
''            │Save Config Menu:   │         Backlit, Prix (P/N 27979) from Parallax, Inc.
''            │                    │
''            │Press ENT to Save   │  <--- Save all configuration changes to EEPROM..
''            │Press MNU to Quit   │  <--- Reload default configurations, discard any changes to configuration..
''            └────────────────────┘
''
  repeat

    if (monitor_button(menu_Button)) == HI              'If MNU button is pressed, we want to quit without saving any
                                                        'changes to the FMB configuration... Note:  Procedure "setup_FMB"
                                                        'will read EEPROM again and load config setup.
      lcd.cls
      lcd.str(string("EXIT WITHOUT SAVING."))
      repeat x from 1 to 50
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.5 seconds.
      quit
    if (monitor_button(entr_Button)) == HI              'If ENT button is pressed, we want to save the configuration
                                                        'changes to the FMB EEPROM... Note:  Procedure "setup_FMB"
                                                        'will read EEPROM again and load config setup.
      lcd.cls
      lcd.str(string("SAVING CONFIGURATION"))
'     -------------  Save Communication Type to EEPROM address $0030. -------------
      ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, comAddr, oneByte, comm_Select)
        lcd.gotoxy(1,3)
        lcd.str(string("ERROR Writing Comm."))
        repeat x from 1 to 30
          waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

'     -------------  Save Comm Baud Rate to EEPROM address $0031. -------------
      ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, baudAddr, oneLong, baud_Rate)
        lcd.gotoxy(1,3)
        lcd.str(string("ERROR Writing Comm Baudrate."))
        repeat x from 1 to 30
          waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

'     -------------  Save Output Format to EEPROM address $0035.      -------------
      ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, fmtAddr, oneByte, comm_FMT)
        lcd.gotoxy(1,3)
        lcd.str(string("ERROR Writing FMT."))
        repeat x from 1 to 30
          waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

'     -------------  Save Measurement Units Type to EEPROM address $0040. -------------
      ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, measAddr, oneByte, meas_units)
        lcd.gotoxy(1,3)
        lcd.str(string("ERROR Writing Meas."))
        repeat x from 1 to 30
          waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

'     -------------  Save Measurement Precision to EEPROM address $0041. -------------
      ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, presAddr, oneByte, num_Precision)
        lcd.gotoxy(1,3)
        lcd.str(string("ERROR Writing Pres."))
        repeat x from 1 to 30
          waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

'     -------------  Save Sound State to EEPROM address $0050. -------------
      ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, soundAddr, oneByte, sound_State)
        lcd.gotoxy(1,3)
        lcd.str(string("ERROR Writing Sound."))
        repeat x from 1 to 30
          waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

      if calFlag == 1                                   'A calibration was performed. Let's save the data.
      
'     -------------  Save FMB Standard Length value to EEPROM address $0010. -------------
        ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, stdAddr, oneLong, stdVal)
          lcd.gotoxy(1,3)
          lcd.str(string("ERROR Writing Standard Value."))
          repeat x from 1 to 30
                waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.
'     -------------  Save FMB Threshold percentage value to EEPROM address $0014. -------------
        ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, thrpAddr, oneLong, threshPct)
          lcd.gotoxy(1,3)
          lcd.str(string("ERROR Writing Threshold Percent Value."))
          repeat x from 1 to 30
                waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.
'     -------------  Save FMB Slope value to EEPROM address $0018. -------------
        ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, slpAddr, oneLong, slope)
          lcd.gotoxy(1,3)
          lcd.str(string("ERROR Writing Slope Value."))
          repeat x from 1 to 30
                waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.
'     -------------  Save FMB Intercept value to EEPROM address $001C. -------------
        ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, intAddr, oneLong, intcpt)
          lcd.gotoxy(1,3)
          lcd.str(string("ERROR Writing Intercept Value."))
          repeat x from 1 to 30
                waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.
'     -------------  Save FMB Offset value to EEPROM address $0020. -------------
        ifnot writeEEPROM(i2cSCL, EEPROM_ADDR, offAddr, oneLong, deltaOffset)
          lcd.gotoxy(1,3)
          lcd.str(string("ERROR Writing Offset Value."))
          repeat x from 1 to 30
                waitcnt(clkfreq / 10 + cnt)       ' Display message on screen for 3 seconds.

      repeat x from 1 to 50
        waitcnt(clkfreq / 10 + cnt)                     'Display message on screen for 0.5 seconds.
      quit

  return

PUB  measure_Length | tmpMeas, chkTHR, loopCNT, tmpLOOP
''  This procedure will capture the length measurement from Temposonics EP2 Linear-Position Sensor.
'' The length value will then be displayed on the LCD display as well as output on either the Bluetooth or
'' RS-232 serial data channels.
''
'' Ver 1.20 JMG 10 Dec 2014
'' Added local variables:
''    tmpMeas : Used to verify that the lenMM variable is a valid length measurement.
''    chkTHR  : Verifies that the measurement wand has been removed from the board after a valid measurement is made.
''    loopCNT : Allows the LED flashing REPEAT loop to exit gracefully if the measurement wand came withing about 2 CM of the magnet mounted
''              at the end of the measurement area of the Temposonic Sensor.  

    lastRaw := sensor.getPosition

    if lastRaw < thr
      lenMM := getRawLength
      tmpMeas := f.FRound(lenMM)                        'Added new local variable "tmpMeas" to check if "lenMM" is valid measurement. Ver 1.20 JMG 10 Dec 2014.
      '  if we have a valid length measurement convert RAW length to length in "mm" or "cm".
      'if lenMM > 0
      if tmpMeas > 0 AND tmpMeas < thr                  'Added new IF statement conditions to make sure the measurement it valid. Ver 1.20 JMG 10 Dec 2014.

        lenMM := f.FMul(lenMM, stdLen)                  ' Adjust raw length value for temperature/humidity effects "stdLen"..
        lenMM := f.FMul(lenMM, slp)                     ' Let's find the actual length in centimeters (CM) by multiplying
        lenMM := f.FAdd(lenMM, int)                     ' raw value by the slope of the linear function, and then adding in the
                                                        ' y-intercept....
        lenMM := f.FAdd(lenMM, ofst)                    ' Now let's add in the offset value determined during calibration.
                                                        ' Note: "ofst" was added so that different measuring rigs, such as
                                                        ' those used during NEFSC clam/scallop cruises, can be used with this FMB.
                                                        ' "ofst" value is in centimeters (CM).

        if meas_units == units_MM
          lenMM := f.FMul(lenMM, f.FFloat(convert_mm))  ' Multiply measurement by 10 to get value in millimeters.
                                                        ' "lenMM" was actually a centimeter measurement prior to adding
                                                        ' this line.  Joe Godlewski, 20 Nov 2007....
        '  shift the values in the display buffer and display
        lenDisp[1] := lenDisp[2]
        lenDisp[2] := lenMM
        printToLCD
        
        if sound_State == ON                            ' Output a beep if "sound_State" is active...
          beep(soundtime, sound_pin)
           
        '  Output measurement to Serial interface -- either Bluetooth or RS-232...
        '
        if comm_FMT == fmt_SCAN                         'If format is Scantrol, lets output the Scantrol RS232 data string..
        '
        'Scantrol Format:  Allows fish board to communicate with older versions of FSCS..
        '  Output looks like:
        '                     : 0001 001 LENGTH xxxxxxxxxxxxxxxxx.x   001 #8B<cr><lf>
        '
          mcuSerial.str(string(": 0001 001 LENGTH "))
          case meas_units
                units_MM:
                  lenMM := f.FDiv(lenMM, f.FFloat(convert_mm)) 'Convert length measurement back to CM. Scantrol only outputs CM measurements.
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 19, 1, " "))

                units_CM:
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 19, 1, " "))

                other:
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 19, 1, " "))

          mcuSerial.str(string("   001 #8B"))
          mcuSerial.str(string(13,10))

        elseif comm_FMT == fmt_LMNO                    'If format is Limnoterra, lets output the Limnoterra RS232 data string..

        'Limnoterra Format: Allows fish board to communicate with older versions of FSCS..
        '  Output looks like:
        '                     xxxx.xrr<cr><lf>
        '       Where xxxx.x = decimal value of length in millimeters.
        '       Not sure what "rr".  This is the last output per message from Limnoterra...
        '
        'Note: Modified this section to first round the length measurement value prior to output to PC while in LIMNO mode. Ver 1.20 JMG 10 Dec 2014.

          case meas_units
                units_MM:
                  intTemp := f.FRound(lenMM)                   'Take the decimal length measurement, and round it to the nearest .0 mm value. Ver 1.20 JMG 10 Dec 2014.
                  lenMM := f.FFloat(intTemp)                   'Convert value back into a decimal value for output to PC. Ver 1.20 JMG 10 Dec 2014.
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 6, 1, "0"))

                units_CM:
                  lenMM := f.FMul(lenMM, f.FFloat(convert_mm)) 'Convert length measurement back to MM. Limnoterra only outputs MM measurements.
                  intTemp := f.FRound(lenMM)                   'Take the decimal length measurement, and round it to the nearest .0 mm value. Ver 1.20 JMG 10 Dec 2014.
                  lenMM := f.FFloat(intTemp)                   'Convert value back into a decimal value for output to PC. Ver 1.20 JMG 10 Dec 2014.
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 6, 1, "0"))

                other:
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 6, 1, "0"))

          mcuSerial.str(string("rr"))
        
        else                                           'If format is Icthystick, lets output the Icthystick RS232 data string..
        '
        'Icthystick Format:
        '  Output looks like:
        '                     $IFMByyy,xxxx.x,mm <cr><lf>
        '
          mcuSerial.str(string(36))
          mcuSerial.str(@cSerNum)
          mcuSerial.str(string(","))
          case num_Precision                                  
                one_decimal:                                  'Output number to One Decimal Place...
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 7, 1, "0"))
                no_decimal:                                   'Output number to NO Decimal Place...
                  intTemp := f.FRound(lenMM)                  'Take the decimal length measurement, and round it to the nearest .0 mm value. Ver 1.20 JMG 10 Dec 2014.
                  lenMM := f.FFloat(intTemp)                  'Convert value back into a decimal value for output to PC. Ver 1.20 JMG 10 Dec 2014.
                  mcuSerial.str(fstr.FloatToFormat(lenMM, 7, 0, "0"))

          mcuSerial.str(string(","))
          case meas_units
                units_MM:
                  mcuSerial.str(string("mm"))
                units_CM:
                  mcuSerial.str(string("cm"))

          mcuSerial.str(string(13,10))
 
'        Flash status LED while stylus remains on the board to alert operator...

        chkTHR := sensor.getPosition                         'Check length on sensor again to see if measurement wand is still on board. Ver 1.20 JMG 12/10/2014
        loopCNT := 0                                         'Initialize REPEAT loop count. Ver 1.20 JMG 12/10/2014
        repeat while chkTHR < thr                            'Exit REPEAT loop gracefully if we get stuck. Ver 1.20 JMG 12/10/2014
          outa[LEDOne] := !outa[LEDOne]                      'Flash LED on displays front panel. Ver 1.20 JMG 12/10/2014
          chkTHR := sensor.getPosition                       'Check length on sensor again to see if wand is still there. Ver 1.20 JMG 12/10/2014
          waitcnt(sampRate + cnt)
          loopCNT++                                          'Increment the loop count. Ver 1.20 JMG 12/10/2014

          if loopCNT == maxLoopCNT                           'If the loopCNT == maxLoopCNT, then leave the REPEAT loop. Ver 1.20 JMG 12/10/2014

              thr := f.FMul(f.FFloat(chkTHR), thrp)          'Recalculate the threshold "thr" value. Ver 1.20 JMG 12/10/2014/
              thr := chkTHR - f.FRound(thr)
              quit
 
'        Ensure that status LED is off after stylus is removed...
      outa[LEDOne]~
            
    else

      '  Stylus is not on the board, calculate the calibration product
      stdLen := f.FDiv(f.FFloat(lastRaw), f.FFloat(std))                        'Recalculate the temperature/humidity correction factor...
      
     '  calculate measurement threshold
      thr := f.FMul(f.FFloat(lastRaw), thrp)
      thr := lastRaw - f.FRound(thr)

  return

PUB getCalSample(len) : raw
'' Function to get a raw sensor value at a given position
'' on the sensor.  Handles text display and acquisition of
'' raw value.

  displayRemoveText(1, 2)

  lcd.cls
  lcd.str(string("--> CALIBRATING <---"))
  lcd.newline
  lcd.str(string("Place Stylus at "))
  lcd.str(numbers.decf(len, 2))
  lcd.str(string("cm"))

  waitcnt((3 * clkfreq) + cnt)             

  raw := -1                                             ' Initialize RAW variable.

  repeat while ((raw =< 0) OR (raw => mThresh))             ' Keep trying to get RAW value.

    raw := getRawLength
    raw := f.FRound(raw)
  
  if sound_State == ON                                  ' Output a beep if "sound_State" is active...
    beep(soundtime, sound_pin)

  lcd.cls
  lcd.str(string("--> CALIBRATING <---"))
  lcd.str(string("Raw Value at "))
  lcd.str(numbers.decf(len, 2))
  lcd.str(string("cm: "))
  lcd.newline
  lcd.str(string("   "))
  lcd.str(numbers.decf(raw, 5))       

  waitcnt((2 * clkfreq) + cnt)

  return

PUB getCalOffset : raw | tempRaw
'' Function to get a raw sensor value at the 0 MM location on the Fishboard.
'' This location is at the 'Fish Stop' plate on the board.

  displayRemoveText(1, 2)
  lcd.cls
  lcd.str(string("--> CALIBRATING <---"))
  lcd.newline
  lcd.str(string("Place Stylus at zero"))
  lcd.str(string("on board and measure"))

  waitcnt((3 * clkfreq) + cnt)             

  raw := -1                                             ' Initialize RAW variable.
  repeat while (raw =< 0) OR (tempRaw => mThresh)                 ' Keep trying to get RAW value.

    raw := getRawLength
    tempRaw := f.FRound(raw)
  
  if sound_State == ON                                  ' Output a beep if "sound_State" is active...
    beep(soundtime, sound_pin)

  lcd.cls
  lcd.str(string("--> CALIBRATING <---"))
  lcd.newline
  lcd.str(string("Remove Stylus."))

  waitcnt((3 * clkfreq) + cnt)             

  return

PUB  getRawLength : raw | rawLen, tmpRaw, idx
''  This procedure will capture the RAW length value from Temposonics EP2 Linear-Position Sensor.
'' The RAW length value will be captured "nSamples" times, and the result will be averaged, and returned to
'' the calling function.
'' NOTE:
''    Variable RAW will return with either -1 indicating that the Stylus was NOT on the board, or RAW will
'' return with valid raw length data.
''  
    
    raw := -1
    if raw < 0
    
      tmpRaw := 0
      lastRaw := sensor.getPosition

      '  pause here to let the user settle the stylus onto the board
      waitcnt(initDelay + cnt)

      '  take nSamples readings from sensor
      Repeat nSamples
        
        '  get raw value from sensor
        raw := sensor.getPosition
        
        '  determine if there is excessive stylus movement
        if (||(raw - lastRaw) > sampleDev)
          '  stylus movement exceed allowable deviation - set lenMM to -1 and exit loop
          raw := -1
          quit

        '  accumulate raw values
        tmpRaw += raw
        lastRaw := raw

        '  pause here for just a bit to control sampling speed
        waitcnt(sampDelay + cnt)

        '  Calculate the Average RAW value from the "nSamples".. Version 1.20 - Changed ">=" to "=>".
      if raw => 0
        raw := f.FDiv(f.FFloat(tmpRaw), f.FFloat(nSamples))

  return
  
PUB calcAvgSlope : temp_slope | dx, dy, n, tmp
'  From High School math, slope m = dy/dx.

  temp_slope := f.FFloat(0)

  repeat n from 0 to nCalPositions - 2
    dy := calPositions[n + 1] - calPositions[n]
    dx := rawCalVals[n + 1] - rawCalVals[n]
    tmp := f.FDiv(f.FFloat(dy), f.FFloat(dx))
    temp_slope := f.FAdd(temp_slope,tmp)

  temp_slope := f.FDiv(temp_slope, f.FFloat(nCalPositions - 1))

  return

PUB Display_Menu(menu_num)
'' This procedure will display a menu on the screen depending on what the
'' value of variable "menu_num" is. There are 7 menus that can be displayed.
'' See the DAT section for the menu types..

  LINE0 := (menu_num * 84) + 0                         'Calculate location for first line to be displayed.
  LINE1 := (menu_num * 84) + 21                        'Calculate location for second line to be displayed.
  LINE2 := (menu_num * 84) + 42                        'Calculate location for third line to be displayed.
  LINE3 := (menu_num * 84) + 63                        'Calculate location for fourth line to be displayed.
  LCD.home
  LCD.cls
  LCD.str(@Menu[LINE0])  
  LCD.gotoxy(0, 1)
  LCD.str(@Menu[LINE1])  
  LCD.gotoxy(0, 2)
  LCD.str(@Menu[LINE2])  
  LCD.gotoxy(0, 3)
  LCD.str(@Menu[LINE3])  

  return

PUB readEEPROM(pinSCL, devSel, addrReg, bit_Count) : i2cData
''  This procedure will read a certain number of bytes depending on
'' what the value of "bit_Count" is.
''        bit_Count = 8  -> Read only a byte of data.
''        bit_Count = 16 -> Read a "word" of data.
''        bit_Count = 32 -> Read a "long word" of data.

  case bit_Count
    8:  ' Read a BYTE of data from EEPROM...
      i2cData := base_I2C.ReadByte(pinSCL, devSel, addrReg)
    16: ' Read a WORD of data from EEPROM...
      i2cData := base_I2C.ReadWord(pinSCL, devSel, addrReg)
    32: ' Read a LONG of data from EEPROM...
      i2cData := base_I2C.ReadLong(pinSCL, devSel, addrReg)

  return i2cData

PUB writeEEPROM(pinSCL, devSel, addrReg, bit_Count, i2cData) : write_OK | startTime
''  This procedure will write a certain number of bytes depending on
'' what the value of "bit_Count" is.
''        bit_Count = 8  -> Write only a byte of data.
''        bit_Count = 16 -> Write a "word" of data.
''        bit_Count = 32 -> Write a "long word" of data.
''
'' Local variable "startTime" is used as a delay to allow EEPROM time
'' to finish writing data. If the delay time gets longer than 1/10 second,
'' we will abort the write procedure...

  write_OK := TRUE
  case bit_Count
    8:  ' Read a BYTE of data from EEPROM...
      base_I2C.WriteByte(pinSCL, devSel, addrReg, i2cData)
    16: ' Read a WORD of data from EEPROM...
      base_I2C.WriteWord(pinSCL, devSel, addrReg, i2cData)
    32: ' Read a LONG of data from EEPROM...
      base_I2C.WriteLong(pinSCL, devSel, addrReg, i2cData)

  startTime := cnt 'Get current clock time...
  repeat while base_I2C.WriteWait(pinSCL, devSel, addrReg)
    if cnt - startTime > clkfreq / 10
      write_OK := FALSE  ' Waited more that 1/10 second for write to finish.  Not good!

  return

PUB beep(interval, output_pin)
''  This procedure will trigger the Piezo Electric Buzzer to emit a beeping noise. The Microcontroller will
'' output a HI on "output_pin" for a certain "interval".  This will cause the Buzzer to emit a beep..

  DIRA[output_pin]~~                                   'Set sound pin to an OUTPUT...
  OUTA[output_pin]~                                    'Set sound pin to a LO..
  OUTA[output_pin]~~                                   'Set sound pin to a HI..  This will cause the transducer to emit
                                                       'a sound.
  waitcnt(clkfreq / 1_000 * interval + cnt)            'Delay a bit to allow sound output..
  
  OUTA[sound_pin]~                                     'Turn sound OFF..

  return

PRI printToLCD | n
'  This procedure will print the measurement information to the LCD display. The current length will be displayed
' on Line 4, starting at column 9, (7 characters wide).  The previous length measurement will be displayed on Line 3,
' starting at column 9...
'

  repeat n from 1 to 2
    if lenDisp[n] > 0
      lcd.gotoxy(10, (n + 1))
      case num_Precision                                    
        one_decimal:                                    'Output number to One Decimal Place...
          lcd.str(fstr.FloatToFormat(lenDisp[n], 7, 1, " "))
        no_decimal:                                     'Output number to NO Decimal Place...
          lcd.str(fstr.FloatToFormat(lenDisp[n], 7, 0, " "))




'     lcd.str(fstr.FloatToFormat(lenDisp[n], 7, 2, "0"))

  return

PRI monitor_Button(button) : sw_Level | DelayMS
'  This procedure will monitor the push-buttons on the FMB interface.
'             sw_Level := HI if button is pressed.
'             sw_Level := LO otherwise............
'
'                --- NEFSC Setup...  Joseph Godlewski
'

  DelayMS := 1
  DIRA[ button ]~                                      'Set pin related to "button" on Propeller Chip to INPUT..

' ------------------ Use this code section for new Protype Boards...  --------------------------
  sw_Level := LO                                       'Initialize sw_Level to show that switch was NOT pressed..

  if not INA[ button ]                                 'Check for a pushed button..
    waitcnt(clkfreq / 1_000 * DelayMS + cnt)           'Delay a bit to check for signal anomalies.. (1 ms)..

    if not INA[ button ]                               'Verify the button was pushed. "Debounce switch!"
      sw_Level := HI                                   'Set sw_Level HI to indicate that switch was selected.
      repeat until INA[ button ]                       'Wait till button is released...
        waitcnt(clkfreq / 1_000 * DelayMS + cnt)       'Delay a bit to check for signal anomalies.. (1 ms)..
      
{
' ------------------ Use this code section for old Lab Board...       --------------------------
  sw_Level := LO                                       'Initialize sw_Level to show that switch was NOT pressed..

  if INA[ button ]                                     'Check for a pushed button..
    waitcnt(clkfreq / 1_000 * DelayMS + cnt)           'Delay a bit to check for signal anomalies.. (1 ms)..

    if INA[ button ]                                   'Verify the button was pushed. "Debounce switch!"
      sw_Level := HI                                   'Set sw_Level HI to indicate that switch was selected.
      repeat until not INA[ button ]                   'Wait till button is released...
        waitcnt(clkfreq / 1_000 * DelayMS + cnt)       'Delay a bit to check for signal anomalies.. (1 ms)..
}      

  return

PRI StrToFloat(strptr) : floatnum | intr, exp, sign
'
'  This procedure will convert a string to a floating point number...
'
  intr := exp := sign := 0                              'Initialize variables for interger, decimal, and sign flags...

  repeat strsize(strptr)

    case byte[strptr]
      "-":
        sign~~
        
      ".":
        exp := 1

      "0".."9":
        intr := intr*10 + byte[strptr] -"0"
          if exp
              exp++                                     'Count decimal places...
      other:
        quit
    strptr++                                            'Increment pointer to next character in the string..

  if sign
    intr := -intr
  floatnum := f.FFloat(intr)
  if exp
    repeat exp-1
      floatnum := f.FDiv(floatnum, 10.0)                'Adjust floatingpoint number for decimal place..
      
  return

PRI  displayRemoveText(nBlink, delay)

  '  Simple function to display the "Remove Stylus..." message

  '  just send one remove message to the serial console
  '  mcuSerial.str(string("Remove Stylus From Board", 13, 10))

  '  flash the remove message on the LCD
  repeat nBlink
    lcd.cls
    lcd.str(string("    CALIBRATING"))
    lcd.newline
    lcd.str(string("  Remove Stylus"))
    lcd.newline
    lcd.str(string("        From Board"))
    waitcnt((delay * clkfreq) + cnt)
    lcd.cls
    lcd.str(string("    CALIBRATING"))
    lcd.newline
    lcd.newline
    lcd.str(string("                  "))
    waitcnt((delay * clkfreq) + cnt)

  return

DAT
calPositions  byte    10,20,30,40,50,60,70,80           'Locations (in cm) that cal raw values are sampled

Menu          byte "--->  MEASURING <---", 0            'Main Menu Display, Line 0..           Menu[0..19]
              byte "                    ", 0            'Main Menu Display, Line 1..           Menu[21..40]
              byte "                    ", 0            'Main Menu Display, Line 2..           Menu[42..61]
              byte "Length =  0000.00 mm", 0            'Main Menu Display, Line 3..           Menu[63..82]

              byte "Communication Menu: ", 0            'Communication Menu Display, Line 0..  Menu[84..103]
              byte " Protocol:  RS-232  ", 0            'Communication Menu Display, Line 1..  Menu[105..124]
              byte " BAUD Rate: 9600    ", 0            'Communication Menu Display, Line 2..  Menu[126..145]
              byte " Format:    Icthysk ", 0            'Communication Menu Display, Line 3..  Menu[147..166]

              byte "Display Menu:       ", 0            'Display Menu Display, Line 0..        Menu[168..187]
              byte "                    ", 0            'Display Menu Display, Line 1..        Menu[189..208]
              byte " Backlighting: OFF  ", 0            'Display Menu Display, Line 2..        Menu[210..229]
              byte "                    ", 0            'Display Menu Display, Line 3..        Menu[231..250]

              byte "Sound Menu:         ", 0            'Sound Menu Display, Line 0..          Menu[252..271]
              byte "                    ", 0            'Sound Menu Display, Line 1..          Menu[273..292]
              byte " Sound: OFF         ", 0            'Sound Menu Display, Line 2..          Menu[294..313]
              byte "                    ", 0            'Sound Menu Display, Line 3..          Menu[315..334]

              byte "Measurement Menu:   ", 0            'Measurement Menu Display, Line 0..    Menu[336..355]
              byte "                    ", 0            'Measurement Menu Display, Line 1..    Menu[357..376]
              byte " UNITS: MM          ", 0            'Measurement Menu Display, Line 2..    Menu[378..397]
              byte " DEC:   XXXX.X      ", 0            'Measurement Menu Display, Line 3..    Menu[399..418]

              byte "Calibration Menu:   ", 0            'Calibration Menu Display, Line 0..    Menu[420..439]
              byte "                    ", 0            'Calibration Menu Display, Line 1..    Menu[441..460]
              byte "Press ENT Begin CAL ", 0            'Calibration Menu Display, Line 2..    Menu[462..481]
              byte "Press MNU to Quit   ", 0            'Calibration Menu Display, Line 3..    Menu[483..502]

              byte "Save Config Menu:   ", 0            'Save Menu Display, Line 0..           Menu[504..523]
              byte "                    ", 0            'Save Menu Display, Line 1..           Menu[525..544]
              byte "Press ENT to Save   ", 0            'Save Menu Display, Line 2..           Menu[546..565]
              byte "Press MNU to Quit   ", 0            'Save Menu Display, Line 3..           Menu[567..586]
              