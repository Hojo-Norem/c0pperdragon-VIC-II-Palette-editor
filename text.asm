;**************
;Text goes here
;**************

alltxt	.text "All",0
		
top1 	.text c_clear,c_white,176
		.fill 37,96
		.text 174,13,125,"        ",c_lt_green,"C64 Video Enhancement       ",c_white," ",125,13,173
		.fill 37,96
		.text 189,13,0
		
Title1	.text c_lt_green,"       Palette adjustment utility",13,13
		.text c_yellow,"      Hardware and firmware design",13
		.text "          *2019*  c0pperdragon",13
		.text c_grey2,"        github.com/c0pperdragon",13,13
		.text c_yellow,"           COLODORE algorithm",13
		.text "              *2017* pepto",13,0
Title2	.text c_grey2,"    www.pepto.de/projects/colorvic/",13,13
		.text c_yellow,"             Utility coding",13
		.text "           *2019*  Hojo Norem",13
		.text c_grey2,"         github.com/Hojo-Norem",13,0
Title3	.text c_black,"           john moore",13,13,13	
		.text c_white," PLEASE TOGGLE YOUR OUTPUT MODE SWITCH",13
		.text "  AND THEN PRESS  ANY KEY TO CONTINUE",0

ChLuma1	.text 13,c_grey3,"Press a key for ",c_red,"N",c_grey3,"ew or ",c_red,"O",c_grey3,"ld luma groups.",13
		.text "Groupings determine luma distribution",13
		.text "and colour mixing ability.",13,13,13
	
		.text c_white,"   NEW LUMAS:",13,c_blue,0
ChLuma2	.text "      ",c_revs_on,172,162,187,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",c_revs_on,188,c_revs_off,162,c_revs_on,190,c_revs_on,c_blue,"   ",c_grey1,"   ",c_purple,"   ",c_grey2,"   ",c_lt_red,"   ",c_grey3,"   ",c_yellow,"   ",c_white,"   ",c_revs_off,13,13,0

ChLuma3	.text 13,c_white,"   OLD LUMAS:",13,c_blue
		.text "      ",c_revs_on,172,162,187,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",161," ",c_revs_on,161,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,c_blue,13
		.text "      ",c_revs_on,188,c_revs_off,162,c_revs_on,190,c_blue,"   ","   ",c_green,"   ","   ","   ",c_yellow,"   ","   ",c_white,"   ",c_revs_off,13,0

MPal1	.text c_white,c_revs_on,172,162,162,187,c_revs_off," ",c_revs_on,"    ",c_revs_off," ",c_red,c_revs_on,"    ",c_revs_off," ",c_cyan,c_revs_on,"    ",c_revs_off," ",c_purple,c_revs_on,"    ",c_revs_off," ",c_green,c_revs_on,"    ",c_revs_off," ",c_blue,c_revs_on,"    ",c_revs_off," ",c_yellow,c_revs_on,"    ",c_revs_off,13
		.text c_white,161,"00",c_revs_on,161,c_revs_off," ",c_revs_on," 01 ",c_revs_off," ",c_red,c_revs_on," 02 ",c_revs_off," ",c_cyan,c_revs_on," 03 ",c_revs_off," ",c_purple,c_revs_on," 04 ",c_revs_off," ",c_green,c_revs_on," 05 ",c_revs_off," ",c_blue,c_revs_on," 06 ",c_revs_off," ",c_yellow,c_revs_on," 07 ",c_revs_off,13,0
MPal2	.text c_white,c_revs_on,188,c_revs_off,162,162,c_revs_on,190,c_revs_off," ",c_revs_on,"    ",c_revs_off," ",c_red,c_revs_on,"    ",c_revs_off," ",c_cyan,c_revs_on,"    ",c_revs_off," ",c_purple,c_revs_on,"    ",c_revs_off," ",c_green,c_revs_on,"    ",c_revs_off," ",c_blue,c_revs_on,"    ",c_revs_off," ",c_yellow,c_revs_on,"    ",c_revs_off,13,13

		.text c_orange,c_revs_on,"    ",c_revs_off," ",c_brown,c_revs_on,"    ",c_revs_off," ",c_lt_red,c_revs_on,"    ",c_revs_off," ",c_grey1,c_revs_on,"    ",c_revs_off," ",c_grey2,c_revs_on,"    ",c_revs_off," ",c_lt_green,c_revs_on,"    ",c_revs_off," ",c_lt_blue,c_revs_on,"    ",c_revs_off," ",c_grey3,c_revs_on,"    ",c_revs_off,13,0
MPal3	.text c_orange,c_revs_on," 08 ",c_revs_off," ",c_brown,c_revs_on," 09 ",c_revs_off," ",c_lt_red,c_revs_on," 10 ",c_revs_off," ",c_grey1,c_revs_on," 11 ",c_revs_off," ",c_grey2,c_revs_on," 12 ",c_revs_off," ",c_lt_green,c_revs_on," 13 ",c_revs_off," ",c_lt_blue,c_revs_on," 14 ",c_revs_off," ",c_grey3,c_revs_on," 15 ",c_revs_off,13
		.text c_orange,c_revs_on,"    ",c_revs_off," ",c_brown,c_revs_on,"    ",c_revs_off," ",c_lt_red,c_revs_on,"    ",c_revs_off," ",c_grey1,c_revs_on,"    ",c_revs_off," ",c_grey2,c_revs_on,"    ",c_revs_off," ",c_lt_green,c_revs_on,"    ",c_revs_off," ",c_lt_blue,c_revs_on,"    ",c_revs_off," ",c_grey3,c_revs_on,"    ",c_revs_off,13,13,0		

menu	.text 13,c_grey3,"   Please select from the following:",13,13
		.text "             ",c_red,"P",c_grey3,"alette editor",13,13
		.text " Apply firmware ",c_red,"d",c_grey3,"efault palette (",c_lt_green,"Y",c_lt_blue,"Pb",c_lt_red,"Pr",c_grey3,")",13,13
		.text " Apply firmware d",c_red,"e",c_grey3,"fault palette (",c_lt_red,"R",c_lt_green,"G",c_white,"s",c_lt_blue,"B",c_grey3,")",13,13,0
menu2	.text " Apply firmware de",c_red,"f",c_grey3,"ault palette (",c_lt_red,"R",c_lt_green,"G",c_lt_blue,"B",c_grey1,"ns",c_grey3,")",13
		.text c_grey2,"  (SDTV mode only, sync signal needed)",13,13,0

		
stf		.text "      Save palette to flash? (",c_red,"Y",c_grey3,"/",c_red,"N",c_grey3,")",13,0
		
PreClk	.text c_grey2," Pre-calculating and applying defaults",13,c_up,0

maincon	.text "   ",c_red,"B",c_grey3,"rightness   ",c_red,"C",c_grey3,"ontrast   ",c_red,"S",c_grey3,"aturation ",13,13
		;.text c_white,"       50          100         50",13,13
		.text 13,13
		.text "      ",c_red,"H",c_grey3,"ue origin   S",c_red,"e",c_grey3,"lected colour",13,13
		;.text c_white,"         11.25           All",13,0
		.text 13,0
maincon2
		.text 13,13,13,13,13
		.text "  Palette: ",c_red,"T",c_grey3,"est - S",c_red,"a",c_grey3,"ve - L",c_red,"o",c_grey3,"ad - ",c_red,"F",c_grey3,"lash",13,13,0
		;.text "Palette:  ",c_red,"T",c_grey3,"est - ",c_red,"U",c_grey3,"pload",13,13,13,0
footer	.text c_grey3," "
		.fill 37,96
		.text 13,c_grey3,"     Highlighted character selects.",13,13,"         Use ",c_red,"+",c_grey3," and ",c_red,"-",c_grey3," to adjust.",0

lumamodenew
		.text c_grey3,"     ",c_red,"L",c_grey3,"uma mixing table:  ",c_lt_green,"New",c_white," lumas",0
lumamodemix
		.text c_grey3,"     ",c_red,"L",c_grey3,"uma mixing table:  ",c_lt_green,"Old",c_white," lumas",0
		
YPbPr	.text c_red,"V",c_grey3,"ideo output mode:  ",c_lt_green,"Y",c_lt_blue,"Pb",c_red,"Pr",0
RGsB	.text c_red,"V",c_grey3,"ideo output mode:  ",c_red,"R",c_lt_green,"G",c_white,"s",c_lt_blue,"B",0
RGBns	.text c_red,"V",c_grey3,"ideo output mode:  ",c_red,"R",c_lt_green,"G",c_lt_blue,"B",c_orange,"ns",0	    

locktxt	.text c_white,"Your palette is now stored. Press any",13
		.text "key to return to the editor or power-",13
		.text "cycle your C64 to re-lock the palette.",13,0  
		
devtxt	.text c_grey3,"Please select ",c_red,"t",c_grey3,"ape, ",c_red,"d",c_grey3,"isk or ",c_red,"c",c_grey3,"ancel.",13,13,0
			;  0123456789012345678901234567890123456789
dmatxt	.text c_grey3,"You can use a cartridge with DMA load",13
		.text "ability here.",13,13,0; Use DMA to load a palette and",13
		;.text "then select any option to return.",13,13,0
devnot	.text c_grey3,"Which drive? (",c_red,"8",c_grey3,",",c_red,"9",c_grey3,",1",c_red,"0",c_grey3,",1",c_red,"1",c_grey3,")",13,13,0
FNtxt	.text c_grey3,"Enter Filename: ",c_white,0
DErtxt	.text c_white,"Disk Error!!",0
DLoad	.text 13,c_grey3,"Loading...",13,0
DSave	.text 13,c_grey3,"Saving...",13,0
			
Tapetxt .text 13,c_grey3,"Please wind cassette to required",13
		.text "position and then press any key to",13
		.text "continue.",13,13,0
nofiles .text c_grey3,"No palette files found.",13,13,0
found1	.text c_grey3,"Found ",0
found2	.text "palette files.",13,13,0

paktxt	.text c_grey3,"Press any key to return.",13,0

ErrDRV	.text 13,13,c_white,"Device ",0		
ErrDNP	.text ": Drive not present!",13,13,0
ErrFNF	.text ": File not found!",13,13,0
ErrLE	.text ": Load error!",13,13,0
ErrBrk	.text ": RUN/STOP!",13,13,0
ErrDef	.text ": Error number ",0