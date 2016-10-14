#include "lodepng.h"
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>


//slice is a 2x2 pixel array
unsigned char max_pool(unsigned char *slice){
	unsigned char max = 0;
	for (unsigned i=0; i<4; i++){
		if (slice[i] > max)
			max = slice[i];
	}
	return max;	
}

void process(char* input_filename, char* output_filename,int threads)
{
  unsigned error;
  unsigned char *image, *new_image;
  unsigned width, height;

  error = lodepng_decode32_file(&image, &width, &height, input_filename);
  if(error) printf("error %u: %s\n", error, lodepng_error_text(error));
  new_image = malloc(width/2 * height/2 * 4 * sizeof(unsigned char));

  // process image
  
  #pragma omp parallel for num_threads(threads) schedule(dynamic,1) 
	for (unsigned i=0; i<width; i=i+2){
		for (unsigned j=0; j<height; j=j+2){
			for (unsigned color=0; color<4; color++){
				#pragma omp critical
				{
  				unsigned char slice[4];
  				unsigned char pixel;
				slice[0] = image[i*width*4 + j*4 + color];
				slice[1] = image[i*width*4 + (j+1)*4 + color];
				slice[2] = image[(i+1)*width*4 + j*4 + color];
				slice[3] = image[(i+1)*width*4 + (j+1)*4 + color];
				pixel = max_pool(slice);
				new_image[i*width + j*2 + color] = pixel;
				}
			}			

		}
	}

  lodepng_encode32_file(output_filename, new_image, width/2, height/2);

  //free(image);
  free(new_image);

}

int main(int argc, char *argv[])
{
  char* input_filename = argv[1];
  char* output_filename = argv[2];
   int threads = atoi(argv[3]);

  process(input_filename, output_filename,threads);
  return 0;
}
