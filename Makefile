CC=gcc
PARALLEL_CC=nvcc
CFLAGS+= -std=c99 -O2 -Wall -Wextra
LDLIBS+= -lm
SEQUENTIAL_SRC_FILES=wave_2d_sequential.c
PARALLEL_SRC_FILES=wave_2d_parallel.cu
IMAGES=$(shell find data -type f | sed s/\\.dat/.png/g | sed s/data/images/g )
.PHONY: all clean dirs plot movie
all: dirs ${TARGETS} parallel sequential
dirs:
	mkdir -p data images
sequential: ${SEQUENTIAL_SRC_FILES}
	$(CC) $^ $(CFLAGS) -o $@ $(LDLIBS)
parallel: ${PARALLEL_SRC_FILES}
	$(PARALLEL_CC) $^ -O2 -fmad=false -o $@ $(LDLIBS)
plot: ${IMAGES}
images/%.png: data/%.dat
	./plot_image.sh $<
movie: ${IMAGES}
	ffmpeg -y -an -i images/%5d.png -vcodec libx264 -pix_fmt yuv420p -profile:v baseline -level 3 -r 12 wave.mp4
check: dirs sequential parallel
	mkdir -p data_sequential
	./sequential
	cp -rf ./data/* ./data_sequential
	./parallel
	./compare.sh
	rm -rf data_sequential
clean:
	-rm -fr sequential parallel data images data_sequential wave.mp4
autocorrect: all
	./autocorrecting.sh
clean_autocorrect:
	rm -rf ./*.res
	rm -rf ./*/*.res
	rm -rf ./*/*/*.res

