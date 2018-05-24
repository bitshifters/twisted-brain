\ ******************************************************************
\ *	Actual text strings
\ ******************************************************************

TEXT_BLOCK_WIDTH = 18
TEXT_BLOCK_HEIGHT = 14
TEXT_BLOCK_SIZE = TEXT_BLOCK_WIDTH * TEXT_BLOCK_HEIGHT

.text_blocks_start

.text_block_table
{
    EQUW text_block_title       ; textBlock_Title
    EQUW text_block_credits     ; textBlock_Credits
}

TEXT_MAPCHAR

.text_block_title
\\ Each text block must be 18 x 16 characters
\\    012345567901234567
EQUS "@@@@@@@@@@@@@@@@@@"
EQUS "@                @"
EQUS "@  BITSHIFTERS   @"
EQUS "@   PRESENTS     @"
EQUS "@                @"
EQUS "@   A NEW DEMO   @"
EQUS "@    FOR THE     @"
EQUS "@   BBC MASTER   @"
EQUS "@                @"
EQUS "@ TWISTED BRAIN  @"
EQUS "@                @"
EQUS "@   NOVA 2018    @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

.text_block_credits
\\ Each text block must be 18 x 16 characters
\\    012345567901234567
EQUS "@@@@@@@@@@@@@@@@@@"
EQUS "@                @"
EQUS "@  CODE & FX BY  @"
EQUS "@    KIERANHJ    @"
EQUS "@                @"
EQUS "@  MUSIC CODE    @"
EQUS "@   BY HENLEY    @"
EQUS "@                @"
EQUS "@  ARTWORK BY    @"
EQUS "@   DETHMUNK     @"
EQUS "@                @"
EQUS "@   FONT BY #    @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

ASCII_MAPCHAR

.text_blocks_end
