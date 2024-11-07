CC=gcc
CFLAGS+= -std=c99 -O2 -Wall -Wextra
LDLIBS+= -lm
SEQUENTIAL_SRC_FILES=wave_2d_sequential.c
.PHONY: all clean dirs plot movie parallel sequential autocorrect clean_autocorrect
all: dirs sequential
dirs:
	mkdir -p images data data_sequential
sequential: ${SEQUENTIAL_SRC_FILES}
	$(CC) $^ $(CFLAGS) -o $@ $(LDLIBS)
clean:
	-rm -fr sequential data data_sequential
autocorrect: all
	./autocorrecting.sh
clean_autocorrect:
	rm -rf ./*.res
	rm -rf ./*/*.res
	rm -rf ./*/*/*.res
	rm -rf ./data
	rm -rf ./*/data
	rm -rf ./*/*/data
	rm -f results.csv 

