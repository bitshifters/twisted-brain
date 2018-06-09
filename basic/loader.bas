10 REM HARDWARE CHECK AND WARNING!
20 A%=0:X%=1:C%=(USR(&FFF4)AND&FF00)DIV256
30 IF C% < 3 OR C% > 5 THEN PRINT"SORRY, BBC MASTER REQUIRED!":END
40 PRINT '"BITSHIFTERS are about to twist"
50 PRINT "your 6845 CRTC video chip..."
60 PRINT '"(We also broke your emulator)"
70 PRINT '"If you experience any bugs or"
80 PRINT "glitches please report them to"
90 PRINT '"https://bitshifters.github.io"
100 PRINT '"0. EMULATOR"
110 PRINT "1. REAL HARDWARE"
120 PRINT '"Please choose: ";
130 REPEAT
140 K=GET
150 UNTIL K>=48 AND K<=49
160 PRINT CHR$(K)
170 ?&70 = K-48
180 PRINT '"TWISTING...";
190 *RUN Brain
