![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# A Simple, Configurable Clock 

## A small introduction
This was a project for Tiny Tapeout 6- done during the ChipCraft: Art of Chip Design course taught in Febuary of 2024

The code included in this submission is as follows:
- project.v
- makerchip_file.tlv

## Description
This is an implementation of a simple, configurable clock on a 2 7-segment display. 

By default, this clock is set to keep accurate time at 20 MHz ( the clock of the FPGA used during testing was 20 MHz), but can be configured to run at 10, 12, and 14 MHz depending on what input pins are switched on.


- `Input switch 1* = 10 MHz`
- `Input switch 2 = 12 MHz`
- `Input switch 3 = 14 MHz`

*Please note that input pins are 0 indexed, and I do mean input switch 1, even though its technically the 2nd switch in the input array

In the makerchip_file.tlv, this is what the `$frequency` mux essentially selects

## Cool Project. How can I use it?

Feel free to copy this repo and make changes as you see fit! Would love for you to build off of this. You have my blessing. 

I'd suggest downloading and opening up the makerchip_file.tlv in [makerchip IDE](https://makerchip.com/sandbox/) and then editing from there. 



