\ ******************************************************************
\ *	Static picture
\ ******************************************************************

smiley_anim = locals_start + 0
smiley_Y = locals_start + 1
smiley_mask = locals_start + 2
smiley_dir = locals_start + 3
smiley_count = locals_start + 4

SMILEY_TOP = 3*8
SMILEY_BOTTOM = 27*8
SMILEY_SPEED = 9

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

    RTS
}

.smiley_update
{
    LDA smiley_anim
    BEQ return

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

    STY smiley_anim

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

.smiley_end
