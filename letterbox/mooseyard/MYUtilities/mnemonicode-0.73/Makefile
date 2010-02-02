sample_programs: mnencode mndecode

mnencode: mnencode.o mnemonic.o mn_wordlist.o

mndecode: mndecode.o mnemonic.o mn_wordlist.o

mn_wordlist.o: mn_wordlist.c mnemonic.h

mnemonic.o: mnemonic.c mnemonic.h

clean: 
	rm -f *.o mnencode mndecode *~
