@echo off
del uploader.prg /q
64tass -a -o uploader.prg --cbm-prg --line-numbers --tab-size=1 --list=uploader_debug.txt uploader.asm 
pause
