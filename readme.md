Experiments in Stable Raster Timing

(Started as an attempt to change the pallete entries every scanline, hence "palline".)

Our goal is to be able to execute code at a specific time during the raster loop.  To reduce the number of possible things running in the system we turn CPU interupts off for the entire process.

At the highest level the approach is:
1. Synchronise "exactly" to vsync
2. Set a timer to tell us when we hit the very first scanline after vblank completes
3. Do some useful work during the vblank period
4. Execute our desired code on first scanline taking exactly 128 cycles
5. Repeat for all 256 visible scanlines
6. Loop back to #3

Step 1 - Synchronise to vsync.

Credit for this approach should be given to Tom Seddon & Richard Broadhurst as discussed on the retrosoftware forum:

- Sit in a tight loop waiting for the vsync interupt to be signalled (note that CPU interupts are turned off so no code is triggered.)  We do this by waiting for bit 1 (CA1) to be set in register 13 (interrupt flag register - IFR) in the System VIA, i.e. at &FE4D.

- Because of the loop latency this only gets us within 10 cycles of vsync having hit.

- We know that one PAL frame takes exactly 39936 cycles (= 312 scanlines * 128 cycles per line) so we wait a bit less than this with an artifical delay loop of ~39932 cycles before testing for vsync again.

- If the vsync flag is set then we know we're already late so we repeat the loop until we don't have vsync.  This means that vsync is imminent in the next instruction.

Step 2 - Set timer to first scanline

We set the System VIA Timer 1 to count down for our desired duration of the vblank and trigger on the first scanline:

vblank = 40 * 64 (40 scanline * 64 us per scanline)
vsync = -2 * 64 (vsync interrupt comes 2 scanlines after vsync occurs!)
latch load = -2 (2 us taken to load the value into the latch)
hsync = -28 (we often want to start executing code in the hsync period so changes are not visible on screen)

