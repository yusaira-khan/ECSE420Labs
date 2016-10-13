/* Example of using lodepng to load, process, save image */
#include "lodepng.h"
#include <stdio.h>
#include <stdlib.h>
/* Example of work sharing using "parallel for" */
#include <omp.h>

 

void processbw(char* input_filename, char* output_filename, int threads)
{
  unsigned error;
  unsigned char *image, *new_image;
  unsigned width, height;
unsigned char value;

  error = lodepng_decode32_file(&image, &width, &height, input_filename);
  if(error) printf("error %u: %s\n", error, lodepng_error_text(error));
  new_image = malloc(width * height * 4 * sizeof(unsigned char));

  // process image
  
  #pragma omp parallel for num_threads(threads) private(value)
  
    
    for (int i = 0; i < height; i++) {
  //for (int i = 0; i < height; i++) {

    for (int j = 0; j < width; j++) { 
int a=4*width*i + 4*j;
     value  = image[4*width*i + 4*j];

      new_image[a + 0] = value; // R
      new_image[a + 1] = value; // G
      new_image[a + 2] = value; // B
      new_image[a + 3] = image[a + 3]; // A
    }
  }
//}
  lodepng_encode32_file(output_filename, new_image, width, height);

  //free(image);
  free(new_image);
}

int main(int argc, char *argv[])
{
  char* input_filename = argv[1];
  char* output_filename = argv[2];
  int threads = atoi(argv[3]);

  processbw(input_filename, output_filename, threads);

  return 0;
}