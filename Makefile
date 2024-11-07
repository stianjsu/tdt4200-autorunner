CC=gcc
PARALLEL_CC=nvcc
CFLAGS+= -std=c99 -O2 -Wall -Wextra
LDLIBS+= -lm
SEQUENTIAL_SRC_FILES=wave_2d_sequential.c
PARALLEL_SRC_FILES=wave_2d_parallel.cu
IMAGES=$(shell find data -type f | sed s/\\.dat/.png/g | sed s/data/images/g )
.PHONY: all clean dirs plot movie parallel sequential autocorrect clean_autocorrect
all: dirs sequential
dirs:
	mkdir -p images
sequential: ${SEQUENTIAL_SRC_FILES}
	$(CC) $^ $(CFLAGS) -o $@ $(LDLIBS)
parallel: ${PARALLEL_SRC_FILES}
	$(PARALLEL_CC) $^ -O2 -fmad=false -o $@ $(LDLIBS)
clean:
	-rm -fr sequential parallel data images data_sequential wave.mp4
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

