'  mts_ep2d.spin
'
'  propeller code to return magnet position as a function of
'  MCU clock cycles for the Temposonics EP2D linear position
'  sensor.
'
'
'  LIMITATIONS:
'
'  This function returns the position of the first magnet only.
'  (Magnet nearest head of sensor)
'
'  This function assumes the reference magnet is affixed to the
'  end of the sensor.  It will time out (and fail to loop) if
'  there is no magnet on the sensor. THE CODE SHOULD BE CHANGED
'  TO WAIT A FIXED AMOUNT OF TIME THEN LOOP IF NO VALUE IS
'  RETURNED.  In practice this has not been a problem except when
'  running on a breadboard.
'
'
'  Rick Towler
'  IT Specialist
'  Midwater Asessment and Conservation Engineering Group
'  Alaska Fisheries Science Center
'  rick.towler@noaa.gov
'
VAR long pulseWidth


PUB start

'' Start a cog with the measurement routine

  return cognew(@entry,@pulseWidth)


PUB getPosition

'' Return the elapsed time (in clock ticks) between start and stop pulses

   pulseWidth := 0                              ' Use zero to indicate no pulse seen yet
   repeat until pulseWidth                      ' Wait until this changes to non-zero
   return pulseWidth                            ' Return the new value

DAT
entry   org

init    mov       t1,   #1      wz              '  configure start pin as output
        shl       t1,   startPin
        muxz      outa, t1                      '  set it LOW
        muxnz     dira, t1
        mov       t2,   #1      wz              '  configure stop pin as input
        shl       t2,   stopPin
        muxz      dira, t2
        
        mov       sampTime, cnt                 ' Set up delay
        add       sampTime, #9                  ' Add 9 clk cycles - time needed to execute this block
        waitcnt   sampTime, sampDelay
        
loop    mov       t1,   #0      wz,nr    
        mov       startTime,cnt                 ' Save the system clock value
        muxz      outa, t1                      ' Set the startPin high
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                                     '  series of NOP's to send 1.5 us pulse
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        muxnz     outa, t1                      ' Set startPin low
        waitpne   zeroes,#%01                   ' Wait for stopPin to go high
        mov       endTime,cnt                   ' Get the system clock value
        sub       endTime,startTime             ' Calculate elapsed tim
        wrlong    endTime,PAR                   ' Return the elapsed time
        waitcnt   sampTime, sampDelay           ' Pause - sensor sampling freq is ~800Hz [40Hz with "sampDelay"=2_000_000
        jmp       #loop                         ' Loop

zeroes        long      0                      
startPin      long      1                       ' Stop pin is pin 1
stopPin       long      0                       ' Start pin is pin 0
sampDelay     long      2_000_000               ' delay in clock cycles between sensor samples
'sampDelay     long      50_000                  ' delay in clock cycles between sensor samples
trigDelay     long      110
startTime     res       1                       ' Start pulse system clock
endTime       res       1                       ' Stop pulse system clock (and calculated difference)
t1            res       1
t2            res       1
trigTime      res       1
sampTime      res       1