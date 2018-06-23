**TWiSTeD bRaIn**

aka **#noteletext #justrasters**

A new demo for the BBC Master by ~ BITSHIFTERS COLLECTIVE ~

Presented at the NOVA 2018 demoparty on 23rd June 2018 in Budleigh Salterton, Devon. 
This demo will twist the 6845 CRTC video chip in your BBC Master computer. 
If you experience any glitches or have compatibility problems please report them to us as a GitHub issue. Otherwise, just enjoy the show & let us know what you think!

(We also broke your favourite emulator a little bit, sorry about that! ;)

**CREDITS**
* Code & FX by kieranhj
* Atari ST music by Mad Max
* Music code & Atari ST port by Henley
* Artwork by Dethmunk
* Bitshifters logo by @Horsenburger
* Font by Razor

**CONTACT**
* Visit our BBC Retro Coding webpage
https://bitshifters.github.io
* Find us on Facebook
https://www.facebook.com/bitshiftrs/
* Say hello on Twitter
https://twitter.com/khconnell
* Join the Acorn community at Stardot
http://stardot.org.uk/forums/

**INVERSE PHASE**
is creating authentic chiptunes
please offer your support by visiting
www.inversephase.com

**TOOLS USED**

BeebAsm, b-em emulator, jsbeeb emulator
Exomizer, Pucrunch, Visual Studio Code
GitHub & more

**TECHNICAL SUPPORT**

This demo requires a standard issue
BBC Master 128K computer. Only MOS 3.20
has been tested, other MOS versions may
be supported. Let us know!

All 4x sideways RAM banks 4 - 7 must be
available for use. If you have ROMs
installed internally these may be
occupying sideways RAM banks. You will
need to remove them and check links
LK18 and LK19 are set correcly as per
the Master Reference manual.

PAGE must be &1900 or lower. Type
"P.~PAGE" in BASIC to check your value.
If this is higher than &E00 then you
may have a ROM installed that is
claiming precious RAM! Try unplugging
any non-essential ROMS with *UNPLUG.

Coprocessors and the Tube must be
disabled. Type *CONF.NOTUBE and reset.

This demo has been tested on real
floppy disc hardware, Retroclinic
DataCentre and MAMMFS for MMC devices.
