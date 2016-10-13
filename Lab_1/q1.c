/* Example of using lodepng to load, process, save image */
#include "lodepng.h"
#include <stdio.h>
#include <stdlib.h>
/* Example of work sharing using "parallel for" */
#include <omp.h>



unsigned char rectify_byte(unsigned char byte){
  if (byte<127){
    byte=127;
  }
  return byte;
}


void process(char* input_filename, char* output_filename,int threads)
{
  unsigned error;
  unsigned char *image, *new_image;
  unsigned width, height,cell;

  error = lodepng_decode32_file(&image, &width, &height, input_filename);
  if(error) printf("error %u: %s\n", error, lodepng_error_text(error));
  new_image = malloc(width * height * 4 * sizeof(unsigned char));

  // process image
  
  #pragma omp parallel for num_threads(threads) private(cell) schedule(dynamic,1)
  
    
    for (unsigned i = 0; i < height; i++) {
  //for (int i = 0; i < height; i++) {

    for (unsigned j = 0; j < width; j++) { 
      cell = 4*width*i + 4*j;
      
      new_image[cell + 0] = rectify_byte(image[cell + 0]); // R
      new_image[cell + 1] = rectify_byte(image[cell + 1]); // G
      new_image[cell + 2] = rectify_byte(image[cell + 2]); // B
      new_image[cell + 3] = rectify_byte(image[cell + 3]); // A
    }
  }

  lodepng_encode32_file(output_filename, new_image, width, height);

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