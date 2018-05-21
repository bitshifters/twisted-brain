10 MODE 1
20 FOR A%=0 TO 127
40 angle=360 * A% / 128
50 x1=40+38*SIN(RAD(angle))
60 x2=40+38*SIN(RAD(angle + 90))
70 x3=40+38*SIN(RAD(angle + 180))
80 x4=40+38*SIN(RAD(angle + 270))
81 Y% = ((A% DIV 4) * 8)
82 X% = ((A% MOD 4) * 80)
90 IF x1 < x2 THEN PROCline(Y%,X%+x1,X%+x2,0,1)
100 IF x2 < x3 THEN PROCline(Y%,X%+x2,X%+x3,0,2)
110 IF x3 < x4 THEN PROCline(Y%,X%+x3,X%+x4,0,3)
120 IF x4 < x1 THEN PROCline(Y%,X%+x4,X%+x1,32,1)
140 NEXT
145 *SAVE screen 3000 +5000
150 END
160
170 DEF PROCline(y,xstart,xend,plot,colour)
180 GCOL plot, colour
190 MOVE xstart * 4, 1023 - y * 4
200 DRAW xend * 4, 1023 - y * 4
210 ENDPROC
