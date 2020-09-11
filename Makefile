TASS_FLAGS = -a --cbm-prg --line-numbers --tab-size=1

all: uploader.prg vid-enh-palgen-asm.prg

uploader.prg: uploader.asm
	64tass $(TASS_FLAGS) -o $@ --list=uploader_debug.txt $<

vid-enh-palgen-asm.prg: vid-enh-palgen.asm
	64tass $(TASS_FLAGS) -o $@ --list=debug.txt $<

clean:
	rm uploader.prg vid-enh-palgen-asm.prg uploader_debug.txt debug.txt
