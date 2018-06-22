10 REM HARDWARE CHECK AND WARNING!
20 A%=0:X%=1:C%=(USR(&FFF4)AND&FF00)DIV256
30 IF C% < 3 OR C% > 5 THEN PRINT"SORRY, BBC MASTER REQUIRED!":END
40 PRINT '"BITSHIFTERS are about to twist"
50 PRINT "your 6845 CRTC video chip..."
60 PRINT '"(We also broke your emulator a bit)"
70 PRINT '"If you experience any glitches"
80 PRINT "please report them to us at:"
90 PRINT '"https://bitshifters.github.io"
100 PRINT '"0. EMULATOR (default)"
110 PRINT "1. REAL HARDWARE"
111 T=20
120 PRINT '"Please choose within ";
130 REPEAT
131 PRINT ;T;" seconds: ";
140 K=INKEY(100)
141 VDU 8,8,8,8,8,8,8,8,8,8,8
142 IF T>9 THEN VDU 8
143 T=T-1
150 UNTIL (K>=48 AND K<=49) OR T<0
151 IF T<0 THEN K=48:T=0
160 PRINT ;T;" seconds: ";CHR$(K)
170 ?&70 = K-48
180 PRINT '"TWISTING...";
190 *RUN Brain
