CC = gcc
CFLAGS = -O3 -march=native -msse4.2 -Wall -Wextra
TARGETS = benchmark_scalar benchmark_lut benchmark_avx2

all: $(TARGETS)

benchmark_scalar: src/scalar/sd_chacha8_scalar.c
	$(CC) $(CFLAGS) -o $@ $^

benchmark_lut: src/lut/sd_chacha8_lut.c
	$(CC) $(CFLAGS) -o $@ $^

benchmark_avx2: src/avx2/sd_chacha8_avx2.c
	$(CC) $(CFLAGS) -mavx2 -o $@ $^

clean:
	rm -f $(TARGETS) *.csv *.png *.pdf

benchmark: all
	./benchmark_scalar
	./benchmark_lut
	./benchmark_avx2

.PHONY: all clean benchmark
