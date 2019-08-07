@echo off
del vid-enh-palgen-asm-compressed.prg
call "make_uploader.bat"
call "make_main.bat"
pucrunch -m6 vid-enh-palgen-asm.prg vid-enh-palgen-asm-compressed.prg
pause
