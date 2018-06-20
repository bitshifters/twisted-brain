\ ******************************************************************
\ *	Static picture
\ ******************************************************************

smiley_anim = locals_start + 0
smiley_Y = locals_start + 1
smiley_mask = locals_start + 2
smiley_dir = locals_start + 3
smiley_count = locals_start + 4

smiley_line = locals_start + 5
smiley_yoff = locals_start + 6

smiley_vel = locals_start + 7
smiley_visible = locals_start + 8

SMILEY_TOP = 3*8
SMILEY_BOTTOM = 27*8
SMILEY_SPEED = 1

SMILEY_STATUS_ADDR = screen_base_addr + 29 * 640

SMILEY_DEBUG_RASTERS = FALSE
SMILEY_SFX_PAUSE = TRUE

.smiley_start

PAGE_ALIGN
.smiley_pu_data
INCBIN "data/smiley.pu"

.smiley_init
{
	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

	LDX #LO(smiley_pu_data)
	LDY #HI(smiley_pu_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    STZ smiley_anim

    LDA #SMILEY_TOP
    STA smiley_Y

    LDA #&AA
    STA smiley_mask

    LDA #1
    STA smiley_dir
    STA smiley_visible

    STZ smiley_line

    LDA #224
    STA smiley_yoff
    STZ smiley_vel

    \\ Super hack-balls!
    \\ Will only work at the end of the demo :)

    LDX #LO(smiley_music)
    LDY #HI(smiley_music)
    JSR vgm_init_stream

    \\ "Tell" music player not to start until we display first frame
	STZ first_fx
    
    \\ And pause the music player anyway
    IF SMILEY_SFX_PAUSE
    LDA #&FF
    STA vgm_pause
    ENDIF

    RTS
}

.smiley_update
{
    \\ Bounce!

    SEC
    LDA smiley_vel
    SBC #1
    STA smiley_vel

    LDA smiley_vel
    BMI down
    \ Up
    CLC
    LDA smiley_yoff
    ADC smiley_vel
    BCC ok
    BRA bounce

    .down
    CLC
    LDA smiley_yoff
    ADC smiley_vel
    BCS ok

    \\ Bounce
    .bounce
    SEC
    LDA smiley_vel
    EOR #&FF
    SBC #3          ; deaden bounce
    STA smiley_vel

    \\ Trigger SFX on bounce
    IF SMILEY_SFX_PAUSE
    STZ vgm_pause
    ENDIF

    LDA #0
    .ok
    STA smiley_yoff

    \\ Calculate vadj

    LDA smiley_yoff
    AND #&7
    STA smiley_line

    LDA #5:STA &FE00
    LDA #8
    SEC
    SBC smiley_line
    STA &FE01                       ; 8-yoff vadj

    \\ Set address of display cycle buffer

    LDA #13:STA &FE00
    LDA smiley_yoff
    LSR A:LSR A:LSR A:TAX
    LDA smiley_addr_LO, X
    STA &FE01

    LDA #12:STA &FE00
    LDA smiley_addr_HI, X
    STA &FE01

    \\ How many visible rows?

    SEC
    LDA #224
    SBC smiley_yoff
    LSR A:LSR A:LSR A
    BNE vis_ok
    INC A
    .vis_ok
    STA smiley_visible

    \\ Check anim

    LDA smiley_anim
    BEQ return

    \\ Wipe!

    LDA #SMILEY_SPEED
    STA smiley_count
    .loop

    LDX smiley_Y
    LDA smiley_mask
    JSR smiley_wipe_lineX
    JSR smiley_advance_y

    DEC smiley_count
    BNE loop

    .return
    RTS
}

.smiley_advance_y
{
    LDA smiley_mask
    EOR #&FF
    STA smiley_mask

    LDY smiley_Y
    LDA smiley_dir
    BMI up

    \\ down
    INY
    CPY #SMILEY_BOTTOM
    BNE ok

    \\ hit bottom
    DEY
    STY smiley_dir
    BRA ok

    .up
    CPY #SMILEY_TOP
    BNE cont

    STZ smiley_anim

    .cont
    DEY

    .ok
    STY smiley_Y

    .return
    RTS
}

.smiley_set_anim
{
    STA smiley_anim
    RTS
}

; X=line, A=mask
.smiley_wipe_lineX
{
    STA smMASK+1

    JSR screen_calc_addr_lineX

    LDX #80
    LDY #0
    .loop
    LDA (readptr), Y
    .smMASK
    AND #&FF
    STA (readptr), Y

    CLC
    LDA readptr
    ADC #8
    STA readptr
    BCC no_carry
    INC readptr+1
    .no_carry

    DEX
    BNE loop

    RTS
}

.smiley_draw
{
    \\ Wait until scanlne 8
    FOR n,1,8,1
    JSR cycles_wait_128
    NEXT

    \\ First scanline of displayed cycle
    .here_display

    \\ Display screen
	LDA #8:STA &FE00
    LDA #0:STA &FE01

    \\ Configure display cycle

    LDA #4:STA &FE00
    LDA #27:STA &FE01           ; 28 rows

    LDA #6:STA &FE00
    LDA smiley_visible:STA &FE01   ; calc'd visible rows
;    LDA #29:STA &FE01   ; fixed visible rows

    LDA #7:STA &FE00
    LDA #&FF:STA &FE01          ; no vsync

    LDA #5:STA &FE00
    LDA smiley_line:STA &FE01   ; yoff rows of vadj

    \\ Set address of vsync cycle buffer

    LDA #13:STA &FE00
    LDA #LO(SMILEY_STATUS_ADDR/8):STA &FE01

    LDA #12:STA &FE00
    LDA #HI(SMILEY_STATUS_ADDR/8):STA &FE01

    \\ Now wait 28 rows...

    SEC
    LDA #224            ; 29*8
    SBC smiley_line
    TAX
    .loop_display

    CPX smiley_yoff     ; 3c
    BCS path2           ; 
    \ path1             ; 2c
    \\ Turn display off
;	LDA #8:STA &FE00    ; 6c
;	LDA #&30:STA &FE01  ; 6c
    LDA #PAL_black
    STA &FE21
IF SMILEY_DEBUG_RASTERS
    LDA #PAL_red
ELSE
    LDA #PAL_black
ENDIF
    STA &FE21

    BRA cont            ; 3c = 17c

    .path2              ; 3c
    NOP:NOP:NOP         ; 6c
    NOP:NOP:NOP         ; 6c
    NOP                 ; 2c = 17c

    .cont
    FOR n,1,51,1
    NOP
    NEXT
;    BIT 0

    DEX                 ; 2c
    BNE loop_display    ; 3c

    .here_vsync

    \\ Wait at least 8 more scanlines so we're in status portion

IF SMILEY_DEBUG_RASTERS
    LDA #PAL_blue
    STA &FE21
ENDIF

    LDX #8
    .extra_loop
    BEQ extra_done
    JSR cycles_wait_128
    DEX
    BRA extra_loop
    .extra_done

IF SMILEY_DEBUG_RASTERS
    LDA #PAL_green
    STA &FE21
ENDIF

    \\ Configure vsync cycle

    LDA #4: STA &FE00
    LDA #39 - 28 - 1 - 1: STA &FE01     ; 39 rows - 29 we've had

    LDA #7: STA &FE00
    LDA #35 - 29: STA &FE01         ; row 35 - 29 we've had

    LDA #6: STA &FE00
    LDA #3: STA &FE01               ; display 3 rows

IF SMILEY_DEBUG_RASTERS
    LDA #PAL_black
    STA &FE21
ENDIF

    \\ Wait until we're deffo beyond the end of the visible screen

    LDX #32
    .hide_loop
    BEQ hide_done
    JSR cycles_wait_128
    DEX
    BRA hide_loop
    .hide_done

    \\ Turn display off

	LDA #8:STA &FE00
	LDA #&30:STA &FE01

    RTS
}

ALIGN 64
.smiley_addr_LO
FOR n,0,31,1
EQUB LO((screen_base_addr + n * 640)/8)
NEXT

.smiley_addr_HI
FOR n,0,31,1
EQUB HI((screen_base_addr + n * 640)/8)
NEXT

.smiley_end
