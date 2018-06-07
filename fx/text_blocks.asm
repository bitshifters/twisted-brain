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
    EQUW text_block_music       ; textBlock_Music
    EQUW text_block_return      ; textBlock_Return
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
EQUS "@    RELEASED    @"
EQUS "@       AT       @"
EQUS "@    NOVA 2018   @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"
;EQUS "@ TWISTED BRAIN  @"

.text_block_credits
\\ Each text block must be 18 x 14 characters
\\    012345567901234567
EQUS "@@@@ CREDITS  @@@@"
EQUS "@    -------     @"
EQUS "@ CODE & FX      @"
EQUS "@       KIERANHJ @"
EQUS "@                @"
EQUS "@ MUSIC CODE     @"
EQUS "@         HENLEY @"
EQUS "@                @"
EQUS "@ ARTWORK        @"
EQUS "@       DETHMUNK @"
EQUS "@                @"
EQUS "@ FONT    RAZOR# @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

\\ Anyone who helped out along the way
.text_block_thanks
\\ Each text block must be 18 x 14 characters
\\    012345678901234567
EQUS "^^^ THANKS TO ^^^^"
EQUS "^   ---------    ^"
EQUS "^ INVERSE PHASE  ^"
EQUS "^   MATT GODBOLT ^"
EQUS "^ RICH-TW        ^"
EQUS "^         TRICKY ^"
EQUS "^ TOM SEDDON     ^"
EQUS "^   SARAH WALKER ^"
EQUS "^ HORSENBURGER   ^"
EQUS "^         PUPPEH ^"
EQUS "^ RC55           ^"
EQUS "^      PIXELBLIP ^"
EQUS "^ STEW BADGER    ^"
EQUS "^^^^^^^^^^^^^^^^^^"

\\ Specifically people/groups at the party!
\\ Get list from last year's compo results
\\ And the party server!  Alphabetical order.
.text_block_greets
\\ Each text block must be 18 x 14 characters
\\    012345678901234567
EQUS "^^ BITSHIFTERS ^^^"
EQUS "^    GREETZ      ^"
EQUS "^    ------      ^"
EQUS "^ CRTC           ^"
EQUS "^         DESIRE ^"
EQUS "^ LOGICOMA       ^"
EQUS "^     SLIPSTREAM ^"
EQUS "^ VIRGILL        ^"
EQUS "^  UKSCENE ALL@S ^"
EQUS "^                ^"
EQUS "^   STARDOT CREW ^"
EQUS "^ EVERYONE AT    ^"
EQUS "^     THE PARTY! ^"
EQUS "^^^^^^^^^^^^^^^^^^"

.text_block_specs
\\ Each text block must be 18 x 14 characters
\\    012345678901234567
EQUS "@@@ BBC MASTER @@@"
EQUS "@   ----------   @"
EQUS "@ 2MHZ 6502      @"
EQUS "@       128K RAM @"
EQUS "@ 6845 CRTC      @"
EQUS "@        SN76489 @"
EQUS "@                @"
EQUS "@ NO TELETEXT    @"
EQUS "@  JUST RASTERS! @"
EQUS "@                @"
EQUS "@ INSPIRED BY    @"
EQUS "@     ^ REBELS ^ @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

.text_block_music
\\ Each text block must be 18 x 14 characters
\\    012345678901234567
EQUS "@@@@@ MUSIC @@@@@@"
EQUS "@     -----      @"
EQUS "@ THERE ARE MANY @"
EQUS "@ SHEEP IN OUTER @"
EQUS "@ MONGOLIA       @"
EQUS "@     BY MAD MAX @"
EQUS "@                @"
EQUS "@ PORTED FROM    @"
EQUS "@       ATARI ST @"
EQUS "@ YM2149F TO     @"
EQUS "@    BBC SN76489 @"
EQUS "@ BY HENLEY      @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

.text_block_return
\\ Each text block must be 18 x 14 characters
\\    012345678901234567
EQUS "@@@@@@@@@@@@@@@@@@"
EQUS "@                @"
EQUS "@  BITSHIFTERS   @"
EQUS "@      WILL      @"
EQUS "@    RETURN!     @"
EQUS "@                @"
EQUS "@ ^ THANKS FOR ^ @"
EQUS "@  ^ WATCHING ^  @"
EQUS "@                @"
EQUS "@ HTTPS://       @"
EQUS "@ BITSHIFTERS.   @"
EQUS "@      GITHUB.IO @"
EQUS "@                @"
EQUS "@@@@@@@@@@@@@@@@@@"

ASCII_MAPCHAR

.text_blocks_end
