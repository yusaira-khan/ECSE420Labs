#include <stdio.h>
#include <stdlib.h>
#include "lodepng.h"

__global__ void convolve(unsigned char * d_output_image, unsigned char * d_input_image){

    float w[3][3] =
    {
        {1,2,-1},
        {2,0.25,-2},
        {1,-2,-1}
        
    };
    int new_width = blockDim.x;
	int width = new_width + 2;
    int new_i = blockIdx.x;
    int new_j = threadIdx.x;
    unsigned int new_index = (4 * new_width  * new_i) + (4 * new_j);
    unsigned int old_index = (4 * (width ) * new_i) + (4 * new_j);

    
    unsigned char clamped;
    float unclamped = 0;
    for (int c = 0; c < 3; c++) {
        unclamped = 0;
        for (int ii = 0; ii < 3; ii++) {
            for (int jj = 0; jj < 3; jj++) {
                unclamped += d_input_image[old_index + (4 * width * ii) + (4 * jj) + c] * w[ii][jj];
            }
        }
        if (unclamped < 0) clamped = 0;
        else if (unclamped > 255) clamped = 255;
        else clamped = (unsigned char) unclamped;

        d_output_image[new_index + c] = clamped; // R  
    }
    d_output_image[new_index + 3] = d_input_image[old_index + (4 * (width)) + 4  + 3]; // A

}

int main(int argc, char **argv){
	char *input_filename = argv[1];
	char *output_filename = argv[2];
	unsigned error;
	unsigned char *image, *new_image;
	unsigned width, height;
	unsigned char *d_in;
	unsigned char *d_out;
	int img_size, new_img_size;
//	const int MAX_THREADS = 1024;
	int numThreads, numBlocks;
	error = lodepng_decode32_file(&image, &width, &height, input_filename);
	if(error)
		printf("error %u: %s\n", error, lodepng_error_text(error));
	img_size = width * height * sizeof(unsigned char) * 4;
	new_img_size = (width-2) * (height-2) * sizeof(unsigned char) * 4;
	new_image = (unsigned char *)malloc(new_img_size);

	numThreads = (width-2);
	numBlocks = (height-2);

	cudaMalloc(&d_in, img_size);
	cudaMalloc(&d_out, new_img_size);

	cudaMemcpy(d_in, image, img_size, cudaMemcpyHostToDevice);
	
	dim3 dimBlock(numThreads, 1, 1);		
	dim3 dimGrid(numBlocks, 1, 1);

	convolve<<<dimGrid, dimBlock>>>(d_out, d_in);

	cudaMemcpy(new_image, d_out, new_img_size, cudaMemcpyDeviceToHost);
	
	lodepng_encode32_file(output_filename, new_image, width-2, height-2);

	cudaFree(d_in);
	cudaFree(d_out);
	free(image);
	free(new_image);
}
