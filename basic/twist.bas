10 MODE 5
20 FOR Y%=0 TO 127
40 angle=360 * Y% / 128
50 x1=40+38*SIN(RAD(angle))
60 x2=40+38*SIN(RAD(angle + 90))
70 x3=40+38*SIN(RAD(angle + 180))
80 x4=40+38*SIN(RAD(angle + 270))
90 IF x1 < x2 THEN PROCline(Y%,x1,x2,0,1)
100 IF x2 < x3 THEN PROCline(Y%,x2,x3,0,2)
110 IF x3 < x4 THEN PROCline(Y%,x3,x4,0,3)
120 IF x4 < x1 THEN PROCline(Y%,x4,x1,32,1)
140 NEXT
145 *SAVE screen 5800 +1400
150 END
160
170 DEF PROCline(y,xstart,xend,plot,colour)
180 GCOL plot, colour
190 MOVE xstart * 8, 1024 - y * 4
200 DRAW xend * 8, 1024 - y * 4
210 ENDPROC
