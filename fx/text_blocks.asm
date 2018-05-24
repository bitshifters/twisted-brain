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
    EQUW text_block_thanks      ; textBlock_Thanks
    EQUW text_block_greets      ; textBlock_Greets
    EQUW text_block_specs       ; textBlock_Specs
}

TEXT_MAPCHAR

.text_block_title
\\ Each text block must be 18 x 14 characters
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
EQUS "@      AT        @"
EQUS "@   NOVA 2018    @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

.text_block_credits
\\ Each text block must be 18 x 14 characters
\\    012345567901234567
EQUS "@@@@@@@@@@@@@@@@@@"
EQUS "@                @"
EQUS "@ CODE & FX BY   @"
EQUS "@       KIERANHJ @"
EQUS "@                @"
EQUS "@ MUSIC CODE     @"
EQUS "@      BY HENLEY @"
EQUS "@                @"
EQUS "@ ARTWORK BY     @"
EQUS "@       DETHMUNK @"
EQUS "@                @"
EQUS "@ MUSIC BY       @"
EQUS "@        MAD MAX @"
EQUS "@@@@@@@@@@@@@@@@@@"

\\ Anyone who helped out along the way
.text_block_thanks
\\ Each text block must be 18 x 14 characters
\\    012345567901234567
EQUS "@@@ THANKS TO @@@@"
EQUS "@   ---------    @"
EQUS "@ INVERSE PHASE  @"
EQUS "@   MATT GODBOLT @"
EQUS "@ RICH-TW        @"
EQUS "@         TRICKY @"
EQUS "@ TOM SEDDON     @"
EQUS "@   SARAH WALKER @"
EQUS "@ HORSENBURGER   @"
EQUS "@         PUPPEH @"
EQUS "@ RAWLES         @"
EQUS "@   STARDOT CREW @"
EQUS "@ REBELS       # @"
EQUS "@@@@@@@@@@@@@@@@@@"

\\ Specifically people/groups at the party!
\\ Get list from last year's compo results
\\ And the party server!  Alphabetical order.
.text_block_greets
\\ Each text block must be 18 x 14 characters
\\    012345567901234567
EQUS "@@ BITSHIFTERS @@@"
EQUS "@    GREETZ      @"
EQUS "@    ------      @"
EQUS "@ CRTC           @"
EQUS "@         DESIRE @"
EQUS "@ LOGICOMA       @"
EQUS "@     SLIPSTREAM @"
EQUS "@                @"
EQUS "@                @"
EQUS "@                @"
EQUS "@                @"
EQUS "@                @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

.text_block_specs
\\ Each text block must be 18 x 14 characters
\\    012345567901234567
EQUS "@@@ BBC MASTER @@@"
EQUS "@                @"
EQUS "@ 2MHZ 6502      @"
EQUS "@       128K RAM @"
EQUS "@ 6845 CRTC      @"
EQUS "@        SN76489 @"
EQUS "@                @"
EQUS "@ THIS MAY BREAK @"
EQUS "@ YOUR EMULATOR! @"
EQUS "@                @"
EQUS "@ BITSHIFTERS.   @"
EQUS "@      GITHUB.IO @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

ASCII_MAPCHAR

.text_blocks_end
