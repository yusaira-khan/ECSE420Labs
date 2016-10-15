
all: clean q1 q2 q3

q3:
	gcc -std=c11 -fopenmp -lm q3.c lodepng.c -o convolve
	

q1:
	gcc -std=c11 -fopenmp  q1.c lodepng.c -o rectify


q2:
	gcc -std=c11 -fopenmp q2.c lodepng.c -o pool


clean:
	rm -rf convolve rectify pool 