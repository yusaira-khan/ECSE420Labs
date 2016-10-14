/* Example of using lodepng to load, process, save image */
#include "lodepng.h"
#include <stdio.h>
#include <stdlib.h>
#include "wm.h"

#define w_side_size 3
#define COLOR_CHANNELS 3


void process(char* input_filename, char* output_filename, int threads)
{
  unsigned error;
  unsigned char *image, *new_image;
  unsigned width, height,index,new_index;


  error = lodepng_decode32_file(&image, &width, &height, input_filename);
  if(error) printf("error %u: %s\n", error, lodepng_error_text(error));
  new_image = malloc((width-2) * (height-2) * 4 * sizeof(unsigned char));

  // process image
  
  //float (**nim)[4]=(float (**)[4])new_image;
  //float (**im)[4]=(float (**)[4])image;

  #pragma omp parallel for num_threads(threads) schedule(dynamic, 1)
  for (int i = 1; i < height-1; i++) {
  for (int j = 1; j < width-1; j++) {  
    index=4*width*(i-1) + 4*(j-1);
    new_index = 4*(width-2) * (i-1) + 4 * (j-1);

    for (int c =0; c< COLOR_CHANNELS; c++){
	#pragma omp critical
	{
  	unsigned char clamped;
  	float unclamped = 0;

        for (int ii = 0; ii< w_side_size;ii++){
        for (int jj = 0; jj<w_side_size;jj++){
          //printf("%d %d %d %d %d %d\n",i,j,ii,jj,c,image[4*width*(i+ii-1) + 4*(j+jj-1) + c] );
          unclamped += w[ii][jj] *  image[index + 4*width*(ii) + 4*(jj) + c];
          //unclamped=0;
        }
        }
        if (unclamped<=0) clamped = 0;
        else if (unclamped>=255) clamped=255;
        else clamped = (unsigned char) unclamped;

        new_image[new_index+ c] = clamped; // R  
        //nim[i-1][j-i][c]=clamped;
	}
    }
  new_image[new_index + 3]=image[index + 3];
  //nim[i-1][j-1][3]=im[i-1][j-1][3];
  }
  }

  lodepng_encode32_file(output_filename, new_image, width-2, height-2);

  //free(image);
  free(new_image);
}

int main(int argc, char *argv[])
{
  char* input_filename = argv[1];
  char* output_filename = argv[2];
  int threads = atoi(argv[3]);

  process(input_filename, output_filename, threads);

  return 0;
}
