# c0pperdragon-VIC-II-Palette-editor
This editor allows one to load, save and edit custom palettes for c0pperdragon's (https://github.com/c0pperdragon) C64-Video-Enhancement (https://github.com/c0pperdragon/C64-Video-Enhancement) FPGA mod for the Commodore 64.  The editor also handles the uploading and flashing of the palette to the FPGA's memory.  The editor has a decoded version of the FPGA firmware's default palette in the event that you ever want to revert back to it.

The editor is a single load and so should be compatible with practically every way of getting software onto your C64.  The load and save routines are compatible with tape and any CBM compatible device on number 8, 9 ,10 or 11.  Only KERNAL routines are used, so any device that pretends to be CBM compatible should work but is neither guaranteed nor supported.  It is up to your devive vendor to ensure CBM compatibility.

The editor has it's own default palette, based on the 'colodore' algorithm by pepto (www.pepto.de/projects/colorvic/).  This palette is a very close approximation of 'the' average PAL C64.  Using familiar controls, one can adjust this default with a great amount of flexibility.  All colours can be adjusted simultaneously as if you were adjusting a television, or individual colours can be tweaked.

All modes can be switched between component (YPbPr), RGB with sync-on-green (RGsB) and RGB without sync (RGBns).  RGBns requires sync to be sourced from elsewhere.  The luma output at the C64's A/V socket is probably the best and most compatible.

Thanks to c0pperdragon's receptiveness during the mod's development, functionality in the firmware exists to simulate delay line 'luma' mixing that PAL users have been able to enjoy.  This side effect of the PAL decoding scheme allows clever graphicians the means to squeeze a few extra colours out of the VIC-II.  The editor does the needed calculations to generate the colours that will be displayed when colour mixing is used.  These calculations are performed by the editor in all modes and for the default palettes.  An added bonus is that NTSC users will be able to see one of the things that they have been missing out on...

The smaller number of luma levels produced by the very early VIC-IIs is also taken into account and the editor will adjust the colour mixing appropriately.  When using the new VIC-II luma levels, the editor provides the option to override the colour mixing tables with that of the old VIC-II lumas.  This will produce more colour mix combinations at the cost of a ever-so-slight reduction in 'authenticity'. 

## What's done in v1.18
* Hopefully fixed a bug for NTSC users where one could not proceed past the luma selection screen.  I don't have a NTSC machine, so I had to do my testing in VICE.
* Partly for my own amusement and partly to lay the foundation for a more fateful representation of 8565 VIC-II delay line mixing, there is now a 'Mix them ALL!' luma mixing mode.  Interesting effects can be seen in some demos...

## What's done in v1.17
* Re-worked the firmware default palette section.

Now colour mixing is now applied to the firmware default palette.
* Added a built-in instruction manual.

As user controls are already clearly marked on screen, this manual more explains the quirks of the editor and the FPGA mod in general.
* Dropped pucrunch from the main build.

Unless you want to load the editor from tape or disk without a fastloader then there isn't really a need for it in 2020... 

## What's done in v1.16
* Small fix / tweak to the colourmix calculations.  Some improvements to accuracy.

It is worth noting that the default palette settings are not perfect by far. (EDIT: That's the editor's default.)  After using them for a while I found that boosting the brightness on Yellow and Lt.Green a visible notch, shifting the hue of yellow and brown a notch and taking brown's saturation down a notch not only made for a more faithful colour reproduction to my eyes (done by quickly flicking between component and S-Video using a Extron DVS 204) but coupled with the above tweaks to the mixing algo the resulting colourmixes seem more faithful.  An example of such a palette will be included with the sources and binary releases.
## What's done in v1.15
* Setting a default palette also sets the corresponding video mode if the palette editor is chosen afterward.
* Added RGB GUI palette.  Switched appropriately on video mode change.
* I broke the colour mixing routine in the previous version.  Fixed.

## What's done in v1.1
* Added RGBns (no sync) videomode.  In this mode the FPGA will not output sync on Y/green in SDTV mode and will have to be sourced from the A/V port.

## What's done in v1.01
* YUV needs to be scaled to YPbPr for accurate results.  Problem was that for the mixed colours this scaling was being applied __before__ they were being mixed.  This version fixes that and improves the accuracy of the resulting mixed colours.

## What's done in v1.00
* RGsB (sync-on-green) output - The editor works in the YUV space internally and is converted to RGB as needed.  **Not tested for effectiveness due to lack of RGsB supporting equipment!  Please report back with results!**
* Improved colour mixing - Implemented hanover bar generation based on the colodore.com sourcecode.  Hanover bars are only used for the mixed colours.
* Added firmware default palette from FPGA firmware source.  Also added RGsB conversion of default palette.  Neither palette is editable.
* Code borrowed from codebase64 and other minor optimisations have made the editor a little more responsive while altering settings.
* Split sourcecode into modules.

## What's done in v0.91:
* Improved loading menu - The load menu now automatically recognises when a palette has been DMA loaded.

## What's done in v0.9:
* Default palette generation based on colodore algorithm.
* Ability to alter brightness, contrast hue and saturation on a global or per colour basis
* Ability to choose between First revision VIC-II lumas (old) and everything else (new)
* PAL colour mixing calculation...  an approximation but works somewhat.
* Ability to apply old VIC-II lumas to colourmix calculations for new lumas.  Per colour luma channel is averaged without bias. 
* Upload to device flash.
* Built in test image: This is just a Koala format bitmap.  I would appreciate something a little better, even if it's only a nice border...
* Proper YUV -> YPbPr output, recommended by pepto.  Has improved accuracy of default palette. (To my eye)
* Loading and saving from tape and disk, with a built in directory viewer for disk.  See below for more detail.

## What's to do:
* More polishing perhaps, some tweaks to the colourmixing code maybe.  If I was any good at GFX then I'd do a better test image...

## Notes on it's use:
Through the use of raster interrupts, while you use the editor the palette is being constantly updated so the text is always visible regardless of the palette settings.  That means if you hit your reset button, you may be left with improperly generated colours.  The only safe place to reset your C64 without saving your palette to FLASH first is on the test image screen.

Secondly, I recommend that you power cycle your C64 after saving a palette to FLASH in order to reset the unlock bit and remove the possibility of other software accidentally writing to the palette registers.  AFAIK, I have not come across any software that does this, *yet*. 

## Saving and Loading:
The editor can save and load palettes to tape and CBM compatible disk drives and storage devices.  Only KERNAL routines are used, so devices that pretend to be CBM compatible (like the SD2IEC) should also work.  When loading from disk, a filtered directory listing will show.  A load operation that gets interrupted by an error or the RUN/STOP key will not corrupt the palette currently in memory.  Use of the counter is strongly recommended when using tape...

Saved palettes are fully stand-alone, and can be loaded without the editor.  They contain their own palette upload code and on screen prompts.  Please ensure that you do not use the ",1" parameter while loading (eg, LOAD"MY PALETTE  .PAL",8,1).

If you have hardware that allows for DMA loading that respects the standard load address header, like the 1541 Ultimate II, then palettes can be instantly loaded into the editor.  To achieve this please use your device's DMA load function from inside the editor's load menu. 
		
## How to obtain:

Either download the latest version from the releases section or download the source and compile yourself.  You will need to download the cross assembler **64tass** and place it into the same directory as the source.  For a full build, place a copy of **pucrunch** into the source directory.

**'make_full.bat'** calls **'make_uploader.bat'** and then **'make_main.bat'** followed by **pucrunch**.  If you do not want to bother with the final compression, manually calling **'make_uploader.bat'** and then **'make_main.bat'** will suffice.  **'make_uploader.bat'** only needs to be called one time and only again if you modify **uploader.asm**.

Please note:  **uploader.asm** is coded so it's data structures align with those of **vid-enh-palgen.asm** on the 256 byte alignment.  This is so **vid-enh-palgen.asm** can write **uploader.asm** to storage along with the current palette and settings.
						
		
