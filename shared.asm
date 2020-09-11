;***********************************************
;Shared variables between main code and uploader
;***********************************************
.align $100,255
IOrigin 	.fill 17*5
IBright		.fill 17
IContra		.fill 17
ISatura  	.fill 17

.align $100
ColCOS	.fill 16*5
MainPalL	.fill 16
MainPalH	.fill 16

Origin 		.fill 5
FPTemp1		.fill 5
FPtemp2		.fill 5
FPtemp3		.fill 5	
Fcontra		.fill 5
Fsatura		.fill 5



OutputMode
		.fill 1
Mix_Luma
		.fill 1
Active_Luma
		.fill 1
.align $100
ColSIN	.fill 16*5
.align $100
ColCOSB	.fill 16*5
.align $100
ColSINB	.fill 16*5
.align $100
FullPalOddL	.fill 256
FullPalOddH	.fill 256
FullPalEveL	.fill 256
fullPalEveH	.fill 256