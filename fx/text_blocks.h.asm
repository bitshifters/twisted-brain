\ ******************************************************************
\ *	TEXT DATA
\ ******************************************************************

textPattern_Horizontal = 0
textPattern_Vertical = 1
textPattern_Spiral = 2
textPattern_MAX = 3

textBlock_Title = 0
textBlock_Credits = 1
textBlock_MAX = 2

MACRO TEXT_MAPCHAR
MAPCHAR 'A', 'Z', 0
MAPCHAR 'a', 'z', 0
MAPCHAR '0', '9', 26
MAPCHAR '-', 36
MAPCHAR '.', 37
MAPCHAR '/', 38
MAPCHAR '!', 39
MAPCHAR '"', 40
MAPCHAR '$', 41
MAPCHAR '%', 42
MAPCHAR '&', 43
MAPCHAR ':', 44
MAPCHAR ';', 45
MAPCHAR ''', 46
MAPCHAR '(', 47
MAPCHAR ')', 48
MAPCHAR '=', 49
MAPCHAR '@', 50	; star
MAPCHAR '+', 51
MAPCHAR '?', 52
MAPCHAR ',', 53
MAPCHAR '#', 54	; rzr
MAPCHAR ' ', 59
ENDMACRO
