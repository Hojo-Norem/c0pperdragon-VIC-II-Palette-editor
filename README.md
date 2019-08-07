# c0pperdragon-VIC-II-Palette-editor
A C64 based palette editor for [c0pperdragon's] (https://github.com/c0pperdragon) [C64-Video-Enhancement] (https://github.com/c0pperdragon/C64-Video-Enhancement) project
		
Palette generator based on the 'colodore' algorithm by pepto
www.pepto.de/projects/colorvic/
		
 What's done:
		Default palette generation based on colodore algorithm
		Ability to alter brightness, contrast hue and saturation on a global or per colour basis
		ability to choose between First revision VIC-II lumas (old) and everything else (new)
		PAL colourmixing calculation...  an approximation but works somewhat
		ability to apply old VIC-II lumas to colourmix calaulations for new lumas.  Per colour luma channel is averaged without bias. 
		Upload to device flash
		Built in test image:
			This is just a Koala format bitmap.  I would appreciate something a little better, even if it's only a nice border...
		
 What's to do:
		Save/Load palettes to/from tape/disk
		
## How to obtain

Either download the latest version from the releases section or download the source and compile yourself.  You will need to download the cross assembler **64tass** and place it into the same directory as the source.  For a full build, place a copy of **pucrunch** into the source directory.

'make_full.bat' calls 'make_uploader.bat' and then 'make_main.bat' followed by pucrunch.  If you do not want to bother with the final compression, manually calling 'make_uploader.bat' and then 'make_main.bat' will suffice.  'make_uploader.bat' only needs to be called if you modify uploader.asm.

Please note:  uploader.asm is coded so it's data structures align with those of vid-enh-palgen.asm on the 256 byte alignemt.  This is so vid-enh-palgen.asm can write uploader.asm to storage along with the current palette and settings for retreval at a later date... or at least that's the plan.
						
		
