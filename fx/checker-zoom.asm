\ ******************************************************************
\ *	Checkerboard Zoom
\ ******************************************************************

checker_zoom_parity = locals_start + 0
checker_zoom_xoff = locals_start + 1
checker_zoom_yoff = locals_start + 2
checker_zoom_XdivN = locals_start + 3
checker_zoom_XmodN = locals_start + 5
checker_zoom_YdivN = locals_start + 6
checker_zoom_YmodN = locals_start + 8
checker_zoom_N = locals_start + 9
checker_zoom_dir = locals_start + 10

MAX_CHECK_SIZE=32

.checker_zoom_start

.checker_zoom_init
{
    LDA #1
    STA checker_zoom_N
    STA checker_zoom_dir
    STX checker_zoom_xoff
    STZ checker_zoom_yoff

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
    
    LDX #LO(checker_zoom_pal)
    LDY #HI(checker_zoom_pal)
    JMP ula_set_palette
}

.checker_zoom_pal
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

.checker_zoom_update
{
    \\ Could actually keep track of DIV N and MOD N here rather than
    \\ do long division each time...
    INC checker_zoom_yoff
    INC checker_zoom_xoff

    LDA checker_zoom_dir
    BMI shrink
    \\ Grow
    CLC
    ADC checker_zoom_N
    CMP #MAX_CHECK_SIZE
    BCC ok

    LDX #&FF
    STX checker_zoom_dir
    BNE ok

    .shrink
    CLC
    ADC checker_zoom_N
    CMP #2
    BCS ok

    LDX #1
    STX checker_zoom_dir

    .ok
    STA checker_zoom_N
    

    \\ Addresss is checker_table + N*16 + offset*2
    LDA checker_zoom_N
    ASL A
    TAX
    LDA checker_lookup-2, X
    STA readptr
    LDA checker_lookup-2+1, X
    STA readptr+1

	\\ Divide yoff by N
	LDA checker_zoom_yoff
	STA checker_zoom_YdivN
    STZ checker_zoom_YdivN+1

	\\ 16bit/8bit math = 16bit result
    {
        LDX #16
        LDA #0
        .div_loop
        ASL checker_zoom_YdivN
        ROL checker_zoom_YdivN+1
        ROL A
        CMP checker_zoom_N
        BCC no_sub
        SBC checker_zoom_N
        INC checker_zoom_YdivN
        .no_sub
        DEX
        BNE div_loop
        
        \\ A contains remainder (Y MOD N)
        STA checker_zoom_YmodN
    }

	\\ Divide xoff by N
	LDA checker_zoom_xoff
	STA checker_zoom_XdivN
    STZ checker_zoom_XdivN+1

	\\ 16bit/8bit math = 16bit result
    {
        LDX #16
        LDA #0
        .div_loop
        ASL checker_zoom_XdivN
        ROL checker_zoom_XdivN+1
        ROL A
        CMP checker_zoom_N
        BCC no_sub
        SBC checker_zoom_N
        INC checker_zoom_XdivN
        .no_sub
        DEX
        BNE div_loop
        
        \\ A contains remainder (X MOD N)
        STA checker_zoom_XmodN
    }

    \\ (X MOD N) MOD 8 gives which pixel offset table to use
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
    LDA checker_zoom_XmodN
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
    CPX checker_zoom_N
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

    \\ Parity of colour flip
    LDA checker_zoom_XdivN
    AND #&1
    STA checker_zoom_parity
    LDA checker_zoom_YdivN
    AND #&1
    EOR checker_zoom_parity
    STA checker_zoom_parity

     .return
    RTS
}

.checker_zoom_draw
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
    LDY checker_zoom_YmodN  ; 3c

    .here

    FOR n,1,47,1    ; 98c
    NOP
    NEXT

    LDA checker_zoom_parity ; 3c
    ORA #ULA_Mode4          ; 2c
    STA &FE20               ; 4c

    INY                     ; 2c
    CPY checker_zoom_N      ; 3c

    BCC no_wrap             ; 2c/3c

    LDA checker_zoom_parity ; 3c
    EOR #1                  ; 2c
    STA checker_zoom_parity ; 3c
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

.checker_zoom_kill
{
	JSR crtc_reset
	JSR ula_pal_reset
	JMP ula_control_reset
}

.checker_data
FOR N,1,MAX_CHECK_SIZE,1
\\ checker N offset off

;FOR off,0,(N-1)MOD8,1
FOR off,0,7,1
PRINT "N=",N," offset=",off

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

NEXT

.checker_table
FOR N,1,MAX_CHECK_SIZE,1

\\ Each checker data size = 8*N bytes

\\ 8*(1+2+3+4+5..)
\\ 8*N*(N+1)/2
\\ 4*N*(N+1)

prev=4*(N-1)*N
PRINT "N=",N," prev=", prev

FOR off,0,7,1
EQUW checker_data + prev + off * N
NEXT

NEXT

.checker_lookup
FOR N,1,MAX_CHECK_SIZE,1
EQUW checker_table + (N-1)*16
NEXT

.checker_zoom_end
