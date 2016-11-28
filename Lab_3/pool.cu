#include <stdio.h>
#include <stdlib.h>
#include "lodepng.h"

//2) how many threads do you need? #pixels/4 -> as many threads as size of d_out
//3) #blocks = #threads/512
//4) d_in is the whole array so need to figure out how to extract indices
// or maybe pass the indices to pool method?
//5) d_out is N/4 while d_in is N size
//6) need 3D blocks? i, j for pixel grid and k for color?
//7) how do you define size of block? want # of idx equal to width, # of idy equal to height and # of idz equal to 4: dim3
//8) how do you pass the width to the gpu since you need that to compute the d_in and d_out indices
//9) have to consider number of blocks if img size>512


__global__ void pool(unsigned char *d_out, unsigned char *d_in){
	int idx = threadIdx.x;
	int idy = threadIdx.y;
	int idz = threadIdx.z;
	int width = blockDim.x;
	int height = blockDim.y;
	int block = blockIdx.x;
	int size = sizeof(d_out)/sizeof(d_out[0]);
	int index = block*width*height*4 + 4*(idx + width*idy) + idz;
	printf("size is %d and index is %d\n", size, index);
//	printf("blockDim.x is %d, blockDim.y is %d, blockDim.z is %d, x is %d, y is %d, z is %d\n", blockDim.x, blockDim.y, blockDim.z, idx, idy, idz);
/*	if ((idx%2 !=0) || (idy%2 != 0)){

	} 
	else*/
	if(index < size) { 
	if(idz < 3){
		unsigned char slice[4];
		slice[0] = d_in[block*width*2*height*2 + 4*(idx*2 + width*2*idy*2) + idz];
		slice[1] = d_in[block*width*2*height*2 + 4*(idx*2 + width*2*(idy*2 +1)) + idz];
		slice[2] = d_in[block*width*2*height*2 + 4*(idx*2 + 1 + width*2*idy*2) + idz];
		slice[3] = d_in[block*width*2*height*2 + 4*(idx*2 + 1 + width*2*(idy*2 + 1)) + idz];
//		printf("x is %d, y is %d, z is %d and slice is %d, %d, %d, %d\n", idx, idy, idz, slice[0], slice[1], slice[2], slice[3]);
/*		for(unsigned i=0; i<4; i++){
			slice[i] = i;
		}	
*/		unsigned char max = 0;
		for(unsigned i=0; i<4; i++){
			if (slice[i] > max)
				max = slice[i];
		}
		d_out[index] = max;
//		printf("x is %d, y is %d, z is %d, slice is %d, %d, %d, %d and d_out is %d\n", idx, idy, idz, slice[0], slice[1], slice[2], slice[3], d_out[idx/2 + blockDim.x*idy/4 +idz]);
	}
	else {
		d_out[index] = d_in[block*width*2*height*2 + 4*(idx*2 + width*2*idy*2) + 3];
//		printf("x is %d, y is %d, z is %d, and d_out is %d\n", idx, idy, idz, d_out[idx/2 + blockDim.x*idy/4 +idz]);
	}
	}
}

int main(int argc, char **argv){
//	char *input_filename = argv[1];
//	char *output_filename = argv[2];
//	unsigned error;
	unsigned char *image, *new_image;
	unsigned width, height;
	unsigned char *d_in;
	unsigned char *d_out;
	int img_size, new_img_size;
	const int MAX_THREADS = 60;
	int blockW, blockH, numBlocks;
/*	error = lodepng_decode32_file(&image, &width, &height, input_filename);
	if(error)
		printf("error %u: %s\n", error, lodepng_error_text(error));
	img_size = width * height * sizeof(unsigned char) * 4;
	new_img_size = width * height * sizeof(unsigned char)
	new_image = malloc(new_img_size);
*/
	img_size = 64*4;
	new_img_size = img_size/4;
	image = (unsigned char *)malloc(img_size*sizeof(unsigned char));
	new_image = (unsigned char *)malloc(new_img_size*sizeof(unsigned char));
	width = 8;
	height = 8;

	if(new_img_size > MAX_THREADS){
		if (width < MAX_THREADS/2){
			blockW = width/2;
			blockH = MAX_THREADS/(blockW * 4);
			
		} else {
			blockW = MAX_THREADS/4;
			blockH = 1;
		}
		numBlocks = (new_img_size/(blockW * blockH * 4));
		if ( new_img_size%(blockW * blockH * 4) != 0) {	
			numBlocks++;
		}	
	} else {
		blockW = width/2;
		blockH = height/2;
		numBlocks = 1;
	}

	for(unsigned i=0; i<img_size; i++){
		image[i] = i;
	}
	cudaMalloc(&d_in, img_size);
	cudaMalloc(&d_out, new_img_size);

	cudaMemcpy(d_in, image, img_size, cudaMemcpyHostToDevice);
	
	dim3 dimBlock(blockW, blockH, 4);		
	dim3 dimGrid(numBlocks, 1, 1);
	
	pool<<<dimGrid, dimBlock>>>(d_out, d_in);

	cudaMemcpy(new_image, d_out, new_img_size, cudaMemcpyDeviceToHost);
	
	for(int i=0; i<img_size; i++){
		printf("%u; ", image[i]);
	}
	for(int i=0; i<16; i++){
		printf("\ni is %d and new image is %u\n", i, new_image[i]);
	}

	free(image);
	free(new_image);
}
