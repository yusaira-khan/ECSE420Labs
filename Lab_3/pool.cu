#include <stdio.h>
#include <stdlib.h>
#include "lodepng.h"

__global__ void pool(unsigned char *d_out, unsigned char *d_in){
	int idx = threadIdx.x;
	int block = blockIdx.x;
	int width = blockDim.x;

	int index = 4*(width*block + idx);
	int indexSlice0 = 4*(width*2*block*2 + idx*2);
	int indexSlice1 = 4*(width*2*block*2 + idx*2 + 1);
	int indexSlice2 = 4*(width*2*(block*2 + 1) + idx*2);
	int indexSlice3 = 4*(width*2*(block*2 + 1) + idx*2 + 1);

	
	unsigned char sliceR[4];
	unsigned char sliceG[4];
	unsigned char sliceB[4];
	unsigned char sliceA[4];
	
	sliceR[0] = d_in[indexSlice0];
	sliceR[1] = d_in[indexSlice1];
	sliceR[2] = d_in[indexSlice2];
	sliceR[3] = d_in[indexSlice3];
	
	sliceG[0] = d_in[indexSlice0 + 1];
	sliceG[1] = d_in[indexSlice1 + 1];
	sliceG[2] = d_in[indexSlice2 + 1];
	sliceG[3] = d_in[indexSlice3 + 1];
	
	sliceB[0] = d_in[indexSlice0 + 2];
	sliceB[1] = d_in[indexSlice1 + 2];
	sliceB[2] = d_in[indexSlice2 + 2];
	sliceB[3] = d_in[indexSlice3 + 2];

	unsigned char max = 0;
	for(unsigned j=0; j<4; j++){
		if (sliceR[j] > max)
			max = sliceR[j];
	}
	d_out[index] = max;
	
	max = 0;
	for(unsigned j=0; j<4; j++){
		if (sliceG[j] > max)
			max = sliceG[j];
	}
	d_out[index + 1] = max;
	
	max = 0;
	for(unsigned j=0; j<4; j++){
		if (sliceB[j] > max)
			max = sliceB[j];
	}
	d_out[index + 2] = max;
	
	d_out[index + 3] = d_in[indexSlice0 + 3];;
	
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
	new_img_size = width * height * sizeof(unsigned char);
	new_image = (unsigned char *)malloc(new_img_size);

	numThreads = width/2;
	numBlocks = height/2;

	cudaMalloc(&d_in, img_size);
	cudaMalloc(&d_out, new_img_size);

	cudaMemcpy(d_in, image, img_size, cudaMemcpyHostToDevice);
	
	dim3 dimBlock(numThreads, 1, 1);		
	dim3 dimGrid(numBlocks, 1, 1);

	pool<<<dimGrid, dimBlock>>>(d_out, d_in);

	cudaMemcpy(new_image, d_out, new_img_size, cudaMemcpyDeviceToHost);
	
	lodepng_encode32_file(output_filename, new_image, width/2, height/2);

	cudaFree(d_in);
	cudaFree(d_out);
	free(image);
	free(new_image);
}
