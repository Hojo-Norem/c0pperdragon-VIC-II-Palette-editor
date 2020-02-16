# c0pperdragon-VIC-II-Palette-editor
A C64 based palette editor for c0pperdragon's (https://github.com/c0pperdragon) C64-Video-Enhancement (https://github.com/c0pperdragon/C64-Video-Enhancement) project
		
Palette generator based on the 'colodore' algorithm by pepto
www.pepto.de/projects/colorvic/

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
* Some polishing perhaps, some tweaks to the colourmixing code maybe...

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

Please note:  **uploader.asm** is coded so it's data structures align with those of **vid-enh-palgen.asm** on the 256 byte alignemt.  This is so **vid-enh-palgen.asm** can write **uploader.asm** to storage along with the current palette and settings.
						
		
