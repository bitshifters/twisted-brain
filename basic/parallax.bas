10 MODE 1
20 sw=320
30 N%=5
40 stepx=sw/N%
45 stepy=4
50 bw=24
60 gap=stepx-bw
70 cz=-sw/2
80 FOR cx=0 TO stepx
85 y=1023 - cx * stepy
90 FOR P%=5 TO 0 STEP -1
95 GCOL 0, (P% MOD 3)+1
100 bz=P% * stepx
105 d=bz-cz
106 M%=N% * d/(sw /2)
110 FOR B%=-M% TO M%
120 bx=B% * stepx
130 x1=(bx - bw/2) - cx
140 x2=(bx + bw/2) - cx
150 sx1=640 + 640 * x1/d
160 sx2=640 + 640 * x2/d
170 MOVE sx1, y
175 DRAW sx2, y
180 REM MOVE sx2, y
190 REM PLOT 85, sx2, y+stepy
200 REM MOVE sx1, y+stepy
210 REM PLOT 85, sx1, y
220 NEXT
230 NEXT
240 NEXT
250 *SAVE screen 3000 +1400
