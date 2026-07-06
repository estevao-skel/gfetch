gfetch: gfetch.asm
	nasm -f bin -O3 -o gfetch gfetch.asm
	chmod +x gfetch

clean:
	rm -f gfetch
