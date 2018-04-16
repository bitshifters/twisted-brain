\ ******************************************************************
\ *	Checkerboard Zoom
\ ******************************************************************

checker_zoom_temp = locals_start + 0
checker_zoom_yoff = locals_start + 1
checker_zoom_xoff = locals_start + 2
checker_zoom_c = locals_start + 3
checker_zoom_N = locals_start + 4
checker_zoom_count = locals_start + 5

.checker_zoom_start

.checker_zoom_init
{
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
IF 0
    FOR n,0,39,8
    LDA #0
    STA &3000+n*8
    STA &3008+n*8
    STA &3010+n*8
    STA &3018+n*8
    LDA #&FF
    STA &3020+n*8
    STA &3028+n*8
    STA &3030+n*8
    STA &3038+n*8
    NEXT
ELSE

    STZ checker_zoom_c

    LDA #32
    STA checker_zoom_N

    LDA #40
    STA checker_zoom_count

    LDA checker_zoom_yoff
    AND #&1f
    TAX
;    LDX #0      ; p

    FOR C,0,39,1
    {
        LDA #0

        FOR b,0,7,1
        {
            CLC
            ROL A
            ORA checker_zoom_c
            INX
            CPX checker_zoom_N
            BCC same_bit

            \\ New bit
            STA checker_zoom_temp
            LDA checker_zoom_c
            EOR #1
            STA checker_zoom_c
            LDA checker_zoom_temp
            LDX #0

            .same_bit
        }
        NEXT

        STA &3000 + C*8
    }
    NEXT
ENDIF

    INC checker_zoom_yoff

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

    LDY checker_zoom_yoff

    .here

    FOR n,1,49,1    ; 98c
    NOP
    NEXT

    TYA             ; 2c
    LSR A:LSR A:LSR A:LSR A:LSR A   ; 10c
    AND #&1         ; 2c
    ORA #ULA_Mode4  ; 2c
    STA &FE20       ; 4c
    INY             ; 2c

    BIT 0           ; 3c

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

.checker_zoom_end
