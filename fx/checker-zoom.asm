\ ******************************************************************
\ *	Checkerboard Zoom
\ ******************************************************************

checkzoom_parity = locals_start + 0
checkzoom_xoff = locals_start + 1
checkzoom_yoff = locals_start + 2
checkzoom_XdivN = locals_start + 3
checkzoom_XmodN = locals_start + 5
checkzoom_YdivN = locals_start + 6
checkzoom_YmodN = locals_start + 8
checkzoom_N = locals_start + 9
checkzoom_data = locals_start + 10
checkzoom_dir = locals_start + 11
checkzoom_idx = locals_start + 12
checkzoom_idy = locals_start + 13
checkzoom_delay = locals_start + 14
checkzoom_temp = locals_start + 15

MAX_CHECK_SIZE = 255
CHECKZOOM_DELAY = 1
CHECKER_ZOOM = TRUE

.checkzoom_start

.checkzoom_init
{
    LDA #129
    STA checkzoom_N

    LDA #CHECKZOOM_DELAY
    STA checkzoom_delay

    LDA #&FF
    STA checkzoom_dir

    STZ checkzoom_xoff
    STZ checkzoom_yoff

    STZ checkzoom_idx
    STZ checkzoom_idy

    LDA #ULA_Mode4
    JSR ula_set_mode

    \\ Set MODE 4
    LDA #0: STA &FE00
    LDA #63: STA &FE01

    LDA #1: STA &FE00
    LDA #40: STA &FE01

    LDA #2: STA &FE00
    LDA #49: STA &FE01

    LDA #3: STA &FE00
    LDA #&24: STA &FE01
    
    LDX #LO(checkzoom_pal)
    LDY #HI(checkzoom_pal)
    JMP ula_set_palette
}

.checkzoom_pal
{
	EQUB &00 + (8 EOR 7)
	EQUB &10 + (8 EOR 7)
	EQUB &20 + (8 EOR 7)
	EQUB &30 + (8 EOR 7)
	EQUB &40 + (8 EOR 7)
	EQUB &50 + (8 EOR 7)
	EQUB &60 + (8 EOR 7)
	EQUB &70 + (8 EOR 7)
	EQUB &80 + (15 EOR 7)
	EQUB &90 + (15 EOR 7)
	EQUB &A0 + (15 EOR 7)
	EQUB &B0 + (15 EOR 7)
	EQUB &C0 + (15 EOR 7)
	EQUB &D0 + (15 EOR 7)
	EQUB &E0 + (15 EOR 7)
	EQUB &F0 + (15 EOR 7)
}

.checkzoom_update
{
	\\ X = 40 + sin(iy) / 4
	LDY checkzoom_idx
	LDA fx_particles_table, Y
	ADC #128
	STA checkzoom_xoff

	\\ Y = 37 + cos(iy) / 4
	LDY checkzoom_idy
	LDA fx_particles_table_cos, Y
	ADC #128
	STA checkzoom_yoff

    \\ Update indices
    CLC
    LDA checkzoom_idx
    ADC #2
    STA checkzoom_idx
    CLC
    LDA checkzoom_idy
    ADC #1
    STA checkzoom_idy

IF CHECKER_ZOOM
    {
;        DEC checkzoom_delay
;        BNE not_today

;        LDA #CHECKZOOM_DELAY
;        STA checkzoom_delay

        \\ Update N
        LDA checkzoom_dir
        BMI shrink
        \\ Grow
        CLC
        ADC checkzoom_N
        CMP #MAX_CHECK_SIZE-1
        BCC ok

        LDX #&FF
        STX checkzoom_dir
        BNE ok

        .shrink
        CLC
        ADC checkzoom_N
        CMP #2
        BCS ok

        LDX #1
        STX checkzoom_dir

        .ok
        STA checkzoom_N

        .not_today
    }
ENDIF

	\\ Divide yoff by N
	LDA checkzoom_yoff
	STA checkzoom_YdivN
    STZ checkzoom_YdivN+1

	\\ 16bit/8bit math = 16bit result
    {
        LDX #16
        LDA #0
        .div_loop
        ASL checkzoom_YdivN
        ROL checkzoom_YdivN+1
        ROL A
        CMP checkzoom_N
        BCC no_sub
        SBC checkzoom_N
        INC checkzoom_YdivN
        .no_sub
        DEX
        BNE div_loop
        
        \\ A contains remainder (Y MOD N)
        STA checkzoom_YmodN
    }

	\\ Divide xoff by N
	LDA checkzoom_xoff
	STA checkzoom_XdivN
    STZ checkzoom_XdivN+1

	\\ 16bit/8bit math = 16bit result
    {
        LDX #16
        LDA #0
        .div_loop
        ASL checkzoom_XdivN
        ROL checkzoom_XdivN+1
        ROL A
        CMP checkzoom_N
        BCC no_sub
        SBC checkzoom_N
        INC checkzoom_XdivN
        .no_sub
        DEX
        BNE div_loop
        
        \\ A contains remainder (X MOD N)
        STA checkzoom_XmodN
    }

    \\ Parity of colour flip
    LDA checkzoom_XdivN
    AND #&1
    STA checkzoom_parity
    LDA checkzoom_YdivN
    AND #&1
    EOR checkzoom_parity
    STA checkzoom_parity

    \\ Now draw the checker pattern, at least one line of it

    LDA checkzoom_N
    CMP #8
    BCS draw_long_lines

    \\ Otherwise use lookup table

    ASL A:TAX

    \\ Addresss is checker_table + N*16 + offset*2
    LDA checker_table-2, X
    STA readptr
    LDA checker_table-2+1, X
    STA readptr+1

    \\ (X MOD N) MOD 8 gives which pixel offset table to use
    LDA checkzoom_XmodN
    AND #&7
    ASL A
    TAY

    \\ Finally have address of our data
    LDA (readptr),Y
    STA smRead+1
    INY
    LDA (readptr),Y
    STA smRead+2

    LDA #LO(screen_base_addr)
    STA smWrite+1
    LDA #HI(screen_base_addr)
    STA smWrite+2

    \\ (X MOD N) DIV 8 gives byte offset to start in data
    LDA checkzoom_XmodN
    LSR A:LSR A:LSR A
    TAX

    LDY #40
    .lineloop

    .smRead
    LDA &FFFF, X

    .smWrite
    STA &FFFF

    \\ Increment byte read and wrap around
    INX
    CPX checkzoom_N
    BCC no_wrap

    LDX #0
    .no_wrap

    CLC
    LDA smWrite+1
    ADC #8
    STA smWrite+1
    BCC no_carry
    INC smWrite+2
    .no_carry

    DEY
    BNE lineloop

     .return
    RTS

    .draw_long_lines
    LDA #LO(screen_base_addr)
    STA writeptr
    LDA #HI(screen_base_addr)
    STA writeptr+1

    \\ How many pixels to start with
    SEC
    LDA checkzoom_N
    SBC checkzoom_XmodN
    TAX

    \\ Always start with black
    STZ checkzoom_data
    LDY #40

    .long_line_loop
    CPX #8
    BCS write_whole_byte

    \\ Write partial byte
    LDA checkzoom_data
    AND checker_left_mask, X
    STA checkzoom_temp

    \\ Flip our bits
    LDA checkzoom_data
    EOR #&FF
    STA checkzoom_data

    AND checker_right_mask, X
    ORA checkzoom_temp
    STA (writeptr)

    SEC
    LDA checkzoom_N
    SBC checker_lazy_table, X
    TAX
    BRA next_column
    
    .write_whole_byte
    LDA checkzoom_data
    STA (writeptr)

    SEC
    TXA
    SBC #8
    TAX

    .next_column
    CLC
    LDA writeptr
    ADC #8
    STA writeptr
    BCC no_carry2
    INC writeptr+1
    .no_carry2

    DEY
    BNE long_line_loop

    RTS
}

.checkzoom_draw
{
	\\ We're only ever going to display this one scanline
	LDA #12: STA &FE00
	LDA #HI(screen_base_addr/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(screen_base_addr/8): STA &FE01

	\\ R9=0 - character row = 1 scanline
	LDA #9: STA &FE00
	LDA #0:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=1 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	FOR n,1,14,1
	NOP
	NEXT

	LDX #2			; 2c
    LDY checkzoom_YmodN  ; 3c

    .here

    FOR n,1,45,1    ; 98c
    NOP
    NEXT
    BIT 0

    LDA checkzoom_parity ; 3c
    ORA #ULA_Mode4          ; 2c
    STA &FE20               ; 4c

    INY                     ; 2c
    CPY checkzoom_N      ; 3c

    BCC no_wrap             ; 2c/3c

    LDA checkzoom_parity ; 3c
    EOR #1                  ; 2c
    STA checkzoom_parity ; 3c
    LDY #0                  ; 2c
    BRA next_line           ; 3c
    ; carry path = 15c

    .no_wrap
    NOP:NOP:NOP:NOP:NOP:NOP ; 12c + BCC taken = 15c

    .next_line
	INX				; 2c
	BNE here		; 3c

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #1-1:	STA &FE01		; 1 scanline

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #56-1+1: STA &FE01		; 312 - 256 = 56 scanlines

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #24+1: STA &FE01			; 280 - 256 = 24 scanlines

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01
	
    RTS        
}

.checkzoom_kill
{
	JSR crtc_reset
	JSR ula_pal_reset
	JMP ula_control_reset
}

MACRO CHECKER_DATA N
{
    data_start=P%+16
    .table
    FOR off,0,7,1
        EQUW data_start + off*N
    NEXT
    .data
    FOR off,0,7,1
    PRINT "N=",N,"offset=",off
    FOR bit,0,N*8-1,8
        b7=((off+bit+0) DIV N) MOD 2
        b6=((off+bit+1) DIV N) MOD 2
        b5=((off+bit+2) DIV N) MOD 2
        b4=((off+bit+3) DIV N) MOD 2
        b3=((off+bit+4) DIV N) MOD 2
        b2=((off+bit+5) DIV N) MOD 2
        b1=((off+bit+6) DIV N) MOD 2
        b0=((off+bit+7) DIV N) MOD 2
    ;    PRINT "%",b7,b6,b5,b4,b3,b2,b1,b0
        EQUB (b7<<7)OR(b6<<6)OR(b5<<5)OR(b4<<4)OR(b3<<3)OR(b2<<2)OR(b1<<1)OR(b0<<0)
    NEXT
    NEXT
}
ENDMACRO


\\ checker size N pixels offset off [0-7]
\\ If want to appear to move at linear speed by distance need to divide not SIN
\\ Eg. square of size 256 at distance D fills 256 pixels
\\ Then step away from it in equal increments, D + N*S
\\ Scale factor will be 256 / (D+N*S) where D=128 probably
\\ Still need to figure out variable size table compilation

.checker_1
CHECKER_DATA 1

.checker_2
CHECKER_DATA 2

.checker_3
CHECKER_DATA 3

.checker_4
CHECKER_DATA 4

.checker_5
CHECKER_DATA 5

.checker_6
CHECKER_DATA 6

.checker_7
CHECKER_DATA 7

.checker_table
EQUW checker_1
EQUW checker_2
EQUW checker_3
EQUW checker_4
EQUW checker_5
EQUW checker_6
EQUW checker_7

.checker_left_mask
EQUB %00000000
EQUB %10000000
EQUB %11000000
EQUB %11100000
EQUB %11110000
EQUB %11111000
EQUB %11111100
EQUB %11111110

.checker_right_mask
EQUB %11111111
EQUB %01111111
EQUB %00111111
EQUB %00011111
EQUB %00001111
EQUB %00000111
EQUB %00000011
EQUB %00000001

.checker_lazy_table
EQUB 8,7,6,5,4,3,2,1

.fx_particles_table
FOR n,0,&13F,1
EQUB 127 * SIN(2 * PI * n / 255)	; 255 or 256?
NEXT

fx_particles_table_cos = fx_particles_table + 64

.checkzoom_end
