.PHONY: build clean run patch

build:
	gcc -O2 -s -fno-asynchronous-unwind-tables -o crackme main.c
	strip --strip-all crackme
	chmod +x crackme

clean:
	rm -f crackme *.bak

run:
	./crackme IUST-CE-1404

patch:
	chmod +x auto_patch.sh
	./auto_patch.sh ./crackme