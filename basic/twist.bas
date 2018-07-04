10 MODE 1
20 FOR A%=0 TO 255
40 angle=360 * A% / 256
50 x1=40+38*SIN(RAD(angle))
60 x2=40+38*SIN(RAD(angle + 90))
70 x3=40+38*SIN(RAD(angle + 180))
80 x4=40+38*SIN(RAD(angle + 270))
90 IF x1 < x2 THEN PROCline(A%,120+x1,120+x2,0,1)
100 IF x2 < x3 THEN PROCline(A%,120+x2,120+x3,0,2)
110 IF x3 < x4 THEN PROCline(A%,120+x3,120+x4,0,3)
120 IF x4 < x1 THEN PROCline(A%,120+x4,120+x1,32,1)
140 NEXT
150 END
160
170 DEF PROCline(y,xstart,xend,plot,colour)
180 GCOL plot, colour
190 MOVE xstart * 4, 1023 - y * 4
200 DRAW xend * 4, 1023 - y * 4
210 ENDPROC
