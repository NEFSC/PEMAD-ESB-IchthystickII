'' ********************************
'' *  Parallax Serial LCD Driver  *
'' *  (C) 2006 Parallax, Inc.     *
'' ********************************
''
'' Parallax Serial LCD Switch Settings
''
''   +---------+     +---------+     +---------+
''   ¦   O N   ¦     ¦   O N   ¦     ¦   O N   ¦
''   ¦ +-----+ ¦     ¦ +-----+ ¦     ¦ +-----+ ¦
''   ¦ ¦[]¦  ¦ ¦     ¦ ¦  ¦[]¦ ¦     ¦ ¦[]¦[]¦ ¦
''   ¦ ¦  ¦  ¦ ¦     ¦ ¦  ¦  ¦ ¦     ¦ ¦  ¦  ¦ ¦
''   ¦ ¦  ¦[]¦ ¦     ¦ ¦[]¦  ¦ ¦     ¦ ¦  ¦  ¦ ¦
''   ¦ +-----+ ¦     ¦ +-----+ ¦     ¦ +-----+ ¦
''   ¦  1   2  ¦     ¦  1   2  ¦     ¦  1   2  ¦
''   +---------+     +---------+     +---------+
''      2400            9600            19200


CON

  LcdBkSpc      = $08                                   ' move cursor left
  LcdRt         = $09                                   ' move cursor right
  LcdLF         = $0A                                   ' move cursor down 1 line
  LcdCls        = $0C                                   ' clear LCD (follow with 5 ms delay)
  LcdCR         = $0D                                   ' move pos 0 of next line
  LcdBLon       = $11                                   ' backlight on
  LcdBLoff      = $12                                   ' backlight off
  LcdOff        = $15                                   ' LCD off
  LcdOn1        = $16                                   ' LCD on; cursor off, blink off
  LcdOn2        = $17                                   ' LCD on; cursor off, blink on
  LcdOn3        = $18                                   ' LCD on; cursor on, blink off
  LcdOn4        = $19                                   ' LCD on; cursor on, blink on
  LcdLine0      = $80                                   ' move to line 1, column 0
  LcdLine1      = $94                                   ' move to line 2, column 0
  LcdLine2      = $A8                                   ' move to line 3, column 0
  LcdLine3      = $BC                                   ' move to line 4, column 0

  #$F8, LcdCC0, LcdCC1, LcdCC2, LcdCC3, LcdCC4, LcdCC5, LcdCC6, LcdCC7 


VAR

  word  tx, bitTime, lcdLines, started 


PUB start(pin, baud, lines)

'' Qualifies pin, baud, and lines input
'' -- makes tx pin an output and sets up other values if valid

  started~ 
  if (pin => 0) and (pin < 28)                          ' qualify tx pin
    if lookdown(baud : 2400, 9600, 19200)               ' qualify baud rate setting
      if (lines == 2) or (lines == 4)                   ' qualify lcd size
        tx := pin
        outa[tx]~~
        dira[tx]~~
        bitTime := clkfreq / baud
        lcdLines := lines
        started~~ 

  return started


PUB stop

'' Makes serial pin an input

  if started
    dira[tx]~                                           ' make pin an input
    started~                                            ' set to false


PUB putc(txbyte) | time

'' Transmit byte

  if started
    txbyte := (txbyte | $100) << 2                      ' add stop bit 
    time := cnt                                         ' sync
    repeat 10                                           ' start + eight data bits + stop
      waitcnt(time += bitTime)                          ' wait bit time
      outa[tx] := (txbyte >>= 1) & 1                    ' output bit (true mode)
    

PUB str(str_addr)

'' Transmit string

  if started
    repeat strsize(str_addr)                            ' for each character in string
      putc(byte[str_addr++])                            '   write the character


PUB cls

'' Clears LCD and moves cursor to home (0, 0) position

  if started
    putc(LcdCls)
    waitcnt(clkfreq / 200 + cnt)                        ' 5 ms delay 


PUB home

'' Moves cursor to 0, 0

  if started
    putc(LcdLine0)
  
  
PUB clrln(line)

'' Clears line

  if started
    line := 0 #> line <# 3                              ' qualify line input
    putc(LinePos[line])                                 ' move to that line
    if lcdLines == 2                                    ' check lcd size
      repeat 16
        putc(32)                                        ' clear line with spaces
    else
      repeat 20
        putc(32)
    putc(LinePos[line])                                 ' return to start of line  


PUB newline

'' Moves cursor to next line, column 0; will wrap from line 3 to line 0

  putc(LcdCR)
  

PUB gotoxy(col, line) | pos

'' Moves cursor to col/line

  if started
    line := 0 #> line <# 3                              ' qualify line
    if lcdLines == 2
      col := 0 #> col <# 15                             ' qualify column
    else
      col := 0 #> col <# 19
    putc(LinePos[line] + col)                           ' move to target position


PUB cursor(crsr_type)

'' Selects cursor type
''   0 : cursor off, blink off  
''   1 : cursor off, blink on   
''   2 : cursor on, blink off  
''   3 : cursor on, blink on

  case crsr_type
    0..3  : putc(DispMode[crsr_type])                   ' get mode from table
    other : putc(LcdOn3)                                ' use serial lcd power-up default

      
PUB custom(char, chr_addr)

'' Installs custom character map

  if started
    if (char => 0) and (char =< 7)                      ' make sure char in range
      putc(LcdCC0 + char)                               ' write character code
      repeat 8
        putc(byte[chr_addr++])                          ' write character data


PUB backlight(status)

'' Enable (1) or disable (0) LCD backlight

  if started
    if (status & 1)
      putc(LcdBLon)
    else
      putc(LcdBLoff)
  

DAT

  LinePos     byte      LcdLine0, LcdLine1, LcdLine2, LcdLine3
  DispMode    byte      LcdOn1, LcdOn2, LcdOn3, LcdOn4
  
  