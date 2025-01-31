{{
  *************************************************
  *      Extended Methods for FullDuplexSerial    *
  *  Functional Equivalents of many BS2 Commands  *
  *                Version 1.1.0                  *
  *             Released: 1/8/2007                *
  *             Revised: 1/27/2007                *
  *         Primary Author: Martin Hebel          *
  *       Electronic Systems Technologies         *
  *   Southern Illinois University Carbondale     *
  *            www.siu.edu/~isat/est              *
  *                                               *
  * Questions? Please post on the Propeller forum *
  *       http://forums.parallax.com/forums/      *
  *************************************************
  *     --- Distribute Freely Unmodified ---      *
  *************************************************
                
  This object extends Chip Gracey's FullDuplexSerial to allow easy reception of
  multiple bytes for decimal values, hex values and strings which end with carriage returns (ASCII 13)
  OR the defined delimiter character ( default is comma - , )

  Use as you would FullDuplex for Rx, Tx, Start, Stop, RxTime, RxCheck, RxFlush, DEC, HEX, BIN Str
****************************************************************************************************
  Adds the following:
  x := Serial.RxDec                  Returns decimal string as value
  x := Serial.RxDecTime(ms)          Returns decimal string as value with timeout
  x := Serial.RxHex                  Returns received hex string value as decimal
  x := Serial.RxHexTime(ms)          Returns received hex string value as decimal with timeout
  Serial.RxStr(@myStr)               Passes received string
  Serial.RxStrTime(ms,@myStr)        Passes received string with timeout
ver 1.1:
  SetDelimiter(char)                 Sets the delimiter character, such as comma or space. it is , by deafult.
                                     CR, or ASCII 13, will also be a delimiter in addition to this.

  x := Serial.IntOfString(@myStr)    Returns the integer (whole) portion of a string
                                     "-123.456" returns -123

  x := Serial.FracOfString(@myStr)   Returns the fractional decimal portion of a string
                                     "-123.456" returns 456      

ver 1.2:
  - Changed "datain" buffer to include 81 characters instead of 16.
  - Modified "RxStr" and "RxStrTime" procedures to allow for capture of 80 characters.
        Joseph Godlewski
        NOAA/NMFS, Northeast Fisheries Science Center
        166 Water Street
        Woods Hole, MA  02543
***************************************************************************************************
  CON
    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000
                       
  OBJ
     Serial  : "Extended_FDSerialNew"     

  Pub Start
    Serial.start(31,30,0,9600)  ' Rx,Tx, Mode, Baud 
}}

VAR
' Byte datain[16]
  Byte datain[81]
  Byte Delimiter

OBJ
   ExtSerial : "FullDuplexSerialNew"

Pub Start (RXpin, TXpin, Mode, Baud)
{{
   Start serial driver - starts a cog
   returns false if no cog available
  
   mode bit 0 = invert rx
   mode bit 1 = invert tx
   mode bit 2 = open-drain/source tx
   mode bit 3 = ignore tx echo on rx

   Serial.Start(31,30,0, 9600)
   
}}
    ExtSerial.Start(RXPin, TXPin, Mode, Baud)
    Delimiter := ","

PUB Stop
    '' See FullDuplex Serial Documentation
    ExtSerial.Stop

PUB RxCheck
    '' See FullDuplex Serial Documentation  
    return (ExtSerial.RxCheck)

PUB RxFlush
    '' See FullDuplex Serial Documentation  
    ExtSerial.RxFlush
    
PUB Tx (data)
    '' See FullDuplex Serial Documentation
    '' Serial.tx(13)   ' Send byte of data
    ExtSerial.tx(data)

Pub Rx
    '' See FullDuplex Serial Documentation
    '' x := Serial.RX   ' receives a byte of data  
    return (ExtSerial.rx)

PUB RxTime(ms)
    '' See FullDuplex Serial Documentation
    '' x:= Serial.RxTime(100)  ' receive byte with 100mS timeout  
    return (ExtSerial.RxTime(ms))
    
PUB str(stringptr)
    '' See FullDuplex Serial Documentation
    '' Serial.str(String("Hello World"))  ' transmit a string     
    ExtSerial.str(stringptr) 

PUB dec(value)
    '' See FullDuplex Serial Documentation
    '' Serial.dec(1234)   ' send decimal value as chracters  
    ExtSerial.dec(value)

PUB hex(value, digits)
    '' See FullDuplex Serial Documentation
    '' Serial.hex(1234,4)  ' send value as hex string for 4 digits  
    ExtSerial.hex(value, digits)

PUB bin(value, digits)
    '' See FullDuplex Serial Documentation  
    '' Serial.bin(32,4)  ' send value as binary string for 8 digits 
    ExtSerial.bin(value, digits)   

Pub SetDelimiter(char)
{{ Sets the delimiter value for string parsing.
   comma by default.
   serial.SetDelimiter(" ") 'change to a space
   Also always delimits using ASCII 13 (CR)
}}  
  Delimiter := char

PUB rxDec : Value | place, ptr, x
{{
   Accepts and returns serial decimal values, such as "1234" as a number.
   String must end in a carriage return (ASCII 13)
   x:= Serial.rxDec     ' accept string of digits for value
}}   
    place := 1                                           
    ptr := 0
    value :=0                                             
    dataIn[ptr] := RX       
    ptr++
    repeat while (DataIn[ptr-1] <> 13) and (DataIn[ptr-1] <> Delimiter)                     
       dataIn[ptr] := RX                             
       ptr++
    if ptr > 2 
      repeat x from (ptr-2) to 1                            
        if (dataIn[x] => ("0")) and (datain[x] =< ("9"))
          value := value + ((DataIn[x]-"0") * place)       
          place := place * 10                               
    if (dataIn[0] => ("0")) and (datain[0] =< ("9")) 
      value := value + (DataIn[0]-48) * place
    elseif dataIn[0] == "-"                                  
         value := value * -1
    elseif dataIn[0] == "+"                               
         value := value 
    
PUB rxDecTime(ms) :Value | place, ptr, x, temp
{{
   Accepts and returns serial decimal values, such as "1234" as a number
   with a timeout value.  No data returns -1
   String must end in a carriage return (ASCII 13)
   x := Serial.rxDecTime(100)   ' accept data with timeout of 100mS
}}  

    place := 1                                             
    ptr := 0
    value :=0                                              
    temp :=  RxTime(ms)        
    if temp == -1
       return -1
       abort       
    dataIn[ptr] := Temp
    ptr++
    repeat while (DataIn[ptr-1] <> 13) and (DataIn[ptr-1] <> Delimiter)                      
      dataIn[ptr] :=  RxTime(ms)                        
      if datain[ptr] == 255
        return -1
        abort 
      ptr++           
    if ptr > 2 
      repeat x from (ptr-2) to 1                            
        if (dataIn[x] => ("0")) and (datain[x] =< ("9"))
          value := value + ((DataIn[x]-"0") * place)         
          place := place * 10                                
    if (dataIn[0] => ("0")) and (datain[0] =< ("9")) 
      value := value + (DataIn[0]-48) * place
    elseif dataIn[0] == "-"                                   
         value := value * -1
    elseif dataIn[0] == "+"                               
         value := value 
    

PUB rxHex :Value | place, ptr, x, temp
{{
   Accepts and returns serial hexadecimal values, such as "A2F4" as a number.
   String must end in a carriage return (ASCII 13)
   x := Serial.rxHex     ' accept string of digits for value
}}   


    place := 1                                            
    ptr := 0
    value :=0                                               
    temp :=  Rx        
    if temp == -1
       return -1
       abort       
    dataIn[ptr] := Temp
    ptr++
    repeat while (DataIn[ptr-1] <> 13) and (DataIn[ptr-1] <> Delimiter)                      
      dataIn[ptr] :=  Rx                               
      if datain[ptr] == 255
        return -1
        abort 
      ptr++           
    if ptr > 1 
      repeat x from (ptr-2) to 0                             
        if (dataIn[x] => ("0")) and (datain[x] =< ("9"))
          value := value + ((DataIn[x]-"0") * place)         
        if (dataIn[x] => ("a")) and (datain[x] =< ("f"))
          value := value + ((DataIn[x]-"a"+10) * place) 
        if (dataIn[x] => ("A")) and (datain[x] =< ("F"))
          value := value + ((DataIn[x]-"A"+10) * place)         
        place := place * 16                                 

 
PUB rxHexTime(ms) :Value | place, ptr, x, temp
{{
   Accepts and returns serial hexadecimal values, such as "A2F4" as a number.
   with a timeout value.  No data returns -1
   String must end in a carriage return (ASCII 13)
   x := Serial.rxHexTime(100)     ' accept string of digits for value with 100mS timeout
}}   
    place := 1                                            
    ptr := 0
    value :=0                                             
    temp :=  RxTime(ms)       
    if temp == -1
       return -1
       abort       
    dataIn[ptr] := Temp
    ptr++
    repeat while (DataIn[ptr-1] <> 13) and (DataIn[ptr-1] <> Delimiter)                      
      dataIn[ptr] :=  RxTime(ms)                       
      if datain[ptr] == 255
        return -1
        abort 
      ptr++           
    if ptr > 1 
      repeat x from (ptr-2) to 0                            
        if (dataIn[x] => ("0")) and (datain[x] =< ("9"))
          value := value + ((DataIn[x]-"0") * place)        
        if (dataIn[x] => ("a")) and (datain[x] =< ("f"))
          value := value + ((DataIn[x]-"a"+10) * place) 
        if (dataIn[x] => ("A")) and (datain[x] =< ("F"))
          value := value + ((DataIn[x]-"A"+10) * place)         
        place := place * 16        

PUB RxStr (stringptr) : Value | ptr
{{
  Accepts a string of characters - up to 80 - to be passed by reference
  String acceptance terminates with a carriage return or the defined delimiter character.
  Will accept up to 80 characters before passing back.
  Serial.Rxstr(@MyStr)        ' accept
  serial.str(@MyStr)          ' transmit
 }} 
    ptr:=0
'   bytefill(@dataIn,0,15)                               
    bytefill(@dataIn,0,80)                               
    dataIn[ptr] :=  Rx        
    if dataIn[ptr] <> -1
      ptr++                                               
'     repeat while ((DataIn[ptr-1] <> 13) and (DataIn[ptr-1] <> Delimiter)) and (ptr < 29)    
      repeat while (DataIn[ptr-1] <> 13) and (ptr < 80)                                       
       dataIn[ptr] :=  Rx    
       ptr++
      dataIn[ptr-1]:=0                                      
      byteMove(stringptr,@dataIn,ptr)

PUB RxStrTime (ms,stringptr) : Value | ptr, temp
{{
  Accepts a string of characters - up to 80 - to be passed by reference
  Allow timeout value.
  String acceptance terminates with a carriage return or defined delimter character.
  Will accept up to 80 characters before passing back.
  Serial.RxstrTime(200,@MyStr)    ' accept
  serial.str(@MyStr)              ' transmit
 }}

    ptr:=0
    bytefill(@dataIn,0,80)

    temp := RxTime(ms)        
    if temp <> -1
      dataIn[ptr] := temp
      ptr++                                                   
'     repeat while (((DataIn[ptr-1] <> 13) and (DataIn[ptr-1] <> Delimiter)) and (ptr < 29))                        
      repeat while (DataIn[ptr-1] <> 13) and (ptr < 80)                                       
          temp :=  RxTime(ms)    
          if temp == -1
             ptr++
             quit    
          dataIn[ptr] := temp
          ptr++
      dataIn[ptr-1]:=0                                        
      byteMove(stringptr,@datain,ptr)                        

PUB IntOfString (stringptr): Value  | negFlag
{{ Returns the integer or whole portion of a string with a decimal point.
   serial.RxString(@myStr))
   x := serial.IntOfString(@myStr)
   "-123.456" will return -123
}}
    repeat strsize(stringptr)
        if  byte[stringptr] == "-"
            negFlag := true
        if (byte[stringptr] => ("0")) and (byte[stringptr] =< ("9"))
            value := value * 10 + (byte[stringptr]-"0")
        if byte[stringptr] == "."
           if NegFlag ==  true
               value := value * -1
               !negFlag
           quit
        stringptr++
    if NegFlag ==  true
       value := value * -1
       !negFlag 

PUB FracOfString (stringptr): Value  | decFlag
{{ Returns the fractional or decimal portion of a string with a decimal point.
   serial.RxString(@myStr))
   x := serial.FracOfString(@myStr)
   "-123.456" will return 456
}}
    repeat strsize(stringptr)
        if  byte[stringptr] == "."
            decFlag := true
        if decFlag == True
           if (byte[stringptr] => ("0")) and (byte[stringptr] =< ("9"))
              value := value * 10 + (byte[stringptr]-"0")
        stringptr++

                