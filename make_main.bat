@echo off
del vid-enh-palgen-asm.prg /q
rem c64list vid-enh-palgen.asm -prg:"vid-enh-palgen-asm.prg" -crunch -rem -ovr
64tass -a -o vid-enh-palgen-asm.prg --cbm-prg --line-numbers --tab-size=1 --list=debug.txt vid-enh-palgen.asm 
pause
