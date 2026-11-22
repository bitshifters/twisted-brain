# just-rasters (Twisted Brain): start here

TWiSTeD bRaIn (#noteletext #justrasters), a Bitshifters BBC Master demo that twists the 6845 CRTC; shown at NOVA 2018. 6502, beebasm.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/twisted-brain (public; local folder is still called just-rasters) |
| Local path | D:\beeb\mine\just-rasters (moved from OneDrive\BEEB\Repos\just-rasters on 2026-11-22) |
| Branch | wip/claude-counts-cycles (checked out); master, stable-raster, stardot-debug, test-rasters, twister-manual, fx-horizontal-twister, fx-logo-rotate, fx-plasma-shelf, fx-texture-rot |
| Last commit | 2026-07-03: Ran Claude RVI skill over the FX files (master: 2018-07-04, release merge) |

## What's in here
- `just-rasters.asm`: main file; includes the effects in `fx/` (twister, vblinds, smiley, plasma, kefrens, copper, logo, parallax, checker-zoom...).
- `lib/`: shared code (exomiser, vgm player, script system).
- `audio/`, `data/`: music and graphics; `compress_assets.bat` packs them.
- `just-font/`: font converter (Visual Studio project).
- `template.ssd`: the disc template the build adds to; `twisted.ssd`: the built disc (committed).
- `reference/`, `stardot/`, `basic/`: notes, forum debug material, BASIC experiments.

## Build and run
- `make`: runs `make.bat`, which assembles `just-rasters.asm` with `..\..\Bin\beebasm.exe` into `twisted.ssd` (listing in `compile.txt`, ignored). `make help` lists targets.
- Tools: beebasm in D:\beeb\Bin (reached as `..\..\Bin`).
- Output: `twisted.ssd` (tracked, so a rebuild shows as modified if the bytes change). `run.bat` opens it in `..\..\bin\B-em\B-em.exe`.

## Local changes
- Checked out on `wip/claude-counts-cycles` (also on origin): one commit on top of `stable-raster` (2018-10-21) that rewrites cycle counts/comments in fx/smiley, twister, vblinds etc. after a Claude RVI cycle-check pass. Not merged to master.
- No uncommitted edits at the time of the 2026-11 tidy.
- The RVI cycle-check configs live in D:\beeb\third-party\fdload_dfs\.claude\skills\rvi-cycle-check\config (they still point at the old OneDrive path).

## Status and next steps
- Released 2018; `stable-raster` (2018-10-21) makes it run with a stable raster; master was not updated after that.
- Decide whether `stable-raster` and the RVI-annotated branch should go back to master.

## See also
- `readme.md` (credits, party info), https://bitshifters.github.io
