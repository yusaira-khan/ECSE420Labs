#include <stdio.h>
#include <stdlib.h>
#include "lodepng.h"

__global__ void rectify(unsigned char *d_out, unsigned char *d_in){
	
	int idx = threadIdx.x;
	int block = blockIdx.x;
	int width = blockDim.x;
	int index = 4*(block*width + idx);
	d_out[index + 0] = d_in[index + 0] < 127 ? 127 : d_in[index + 0];
	d_out[index + 1] = d_in[index + 1] < 127 ? 127 : d_in[index + 1];
	d_out[index + 2] = d_in[index + 2] < 127 ? 127 : d_in[index + 2];
	d_out[index + 3] = 255;
}

int main(int argc, char ** argv){
	char *input_filename = argv[1];
	char *output_filename = argv[2];

	unsigned error;
	unsigned char *image, *new_image;
	unsigned char *d_in, *d_out;
	unsigned width, height;
	int img_size, img_bytes;
	int MAX_THREADS = 1024;

	error = lodepng_decode32_file(&image, &width, &height, input_filename);
	if(error)
		printf("error %u: %s\n", error, lodepng_error_text(error));
	img_size = width * height;
	img_bytes = img_size*4;
	new_image = (unsigned char *)malloc(img_bytes *sizeof(unsigned char));
	cudaMalloc(&d_in, img_bytes);
	cudaMalloc(&d_out, img_bytes);

	cudaMemcpy(d_in, image, img_bytes, cudaMemcpyHostToDevice);

//	dim3 dimBlock();
//	dim3 dimGrid();

	rectify<<<img_size/MAX_THREADS, MAX_THREADS>>>(d_out, d_in);
//	rectify<<<MAX_THREADS, img_size/MAX_THREADS>>>(d_out, d_in);

	int remainder = img_size%MAX_THREADS;

	cudaMemcpy(new_image, d_out, img_bytes, cudaMemcpyDeviceToHost);

	for(int idx = img_size - remainder; idx< img_size; idx++){
		new_image[4*idx+0] = image[4*idx+0] < 127 ? 127 : image[4*idx+0];
		new_image[4*idx+1] = image[4*idx+1] < 127 ? 127 : image[4*idx+1];
		new_image[4*idx+2] = image[4*idx+2] < 127 ? 127 : image[4*idx+2];
		new_image[4*idx+3] = 255;
	}
	
	lodepng_encode32_file(output_filename, new_image, width, height);
	free(image);
	free(new_image);
}
