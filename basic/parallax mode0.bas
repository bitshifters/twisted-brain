10 MODE 0
20 VDU 23,1,0;0;0;0;
40 DIM DITHER(4,4)
50 FOR R%=1 TO 4
60 FOR C%=1 TO 4
70 READ DITHER(R%,C%)
80 NEXT
90 NEXT
20 sw=640
30 N%=5
31 steps=64
40 stepx=sw/N%
41 st = stepx / steps
45 stepy=32 / st
50 bw=64
60 gap=stepx-bw
70 cz=-sw/2
80 FOR cx=0 TO stepx STEP st
81 IF cx = stepx/2 THEN *SAVE screen1 3000 +5000
82 IF cx = stepx/2 THEN CLS
83 IF cx >= stepx/2 THEN y = 1023 - (cx - stepx/2) * stepy ELSE y = 1023 - cx * stepy
90 FOR P%=0 TO 0 STEP -1
100 bz=P% * stepx
105 d=bz-cz
106 M%=N% * d/(sw /2)
110 FOR B%=-M% TO M%
120 bx=B% * stepx
130 x1=(bx - bw/2) - cx
140 x2=(bx + bw/2) - cx
150 sx1=640 + 640 * x1/d
160 sx2=640 + 640 * x2/d
161 IF sx1 > 1280 OR sx2 < 0 THEN GOTO 220
165 centre = (sx1 + sx2)/2
166 radius = (sx2 - sx1)/2
170 REM MOVE sx1, y
171 REM DRAW sx2, y
180 FOR X%=sx1 TO sx2
181 N% = 16*ABS(X% - centre)/radius
190 FOR Y%=0 TO 3
200 IF DITHER((ABS(X%/2)MOD4)+1, (Y% MOD 4)+1) > N% THEN GCOL 0,1 ELSE GCOL 0,0
210 PLOT 69, X%, y-Y%*4
211 NEXT
212 NEXT
220 NEXT
230 NEXT
240 NEXT
250 *SAVE screen2 3000 +5000
260 END
270 DATA 1,9,3,11
280 DATA 13,5,15,7
290 DATA 4,12,2,10
300 DATA 16,8,14,6
