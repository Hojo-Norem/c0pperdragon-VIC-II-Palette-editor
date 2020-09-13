TASS_FLAGS = -a --cbm-prg --line-numbers --tab-size=1 --make-phony -M $(@:.prg=.d)

binaries = uploader.prg vid-enh-palgen-asm.prg
all: $(binaries)

uploader.prg: uploader.asm
	64tass $(TASS_FLAGS) -o $@ --list=uploader_debug.txt $<

vid-enh-palgen-asm.prg: vid-enh-palgen.asm
	64tass $(TASS_FLAGS) -o $@ --list=debug.txt $<

-include $(binaries:.prg=.d)

clean:
	rm -rf $(binaries) uploader_debug.txt debug.txt *.d
