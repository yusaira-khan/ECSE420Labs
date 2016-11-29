#include <stdio.h>
#include <stdlib.h>

__global__ void updateCenter(float *d_out, float *d1_in, float *d2_in) {
	int idx = threadIdx.x;
	float rho = 0.5;
	float eta = 0.0002;
	int size = 4;
	printf("u1: ");
	for(int i=0; i<size*size; i++){
		printf("%f, ", d1_in[i]);
	}
	printf("\nu2: ");
	for(int i=0; i<size*size; i++){
		printf("%f, ", d2_in[i]);
	}
	printf("\n");
	if((idx/size != 0) && (idx/size != 3) && (idx%size != 0) && (idx%size != 3)) {
		d_out[idx] = (rho*(d1_in[idx-1] + d1_in[idx+1] + d1_in[idx-size] +d1_in[idx+size] - 4*d1_in[idx]) + 2*d1_in[idx] - (1-eta)*d2_in[idx])/(1+eta);
	} else {
		d_out[idx] = 0;
	}
	
//	printf("updating center and idx is %d, u[idx] is %f, u1[idx-1] is %f, u1[idx+1] is %f, u1[idx-size] is %f, u1[idx+size] is %f, u1[idx] is %f and u2[idx] is %f\n", idx, d_out[idx], d1_in[idx-1], d1_in[idx+1], d1_in[idx-size], d1_in[idx+size], d1_in[idx], d2_in[idx]);

}

__global__ void updateSides(float *d_out, float *d_in){
	int idx = threadIdx.x;
	int size = 4;
	float G = 0.75;

	if((idx/size == 0) && (idx != 0) && (idx != (size -1))){
		d_out[idx] = G*d_in[idx + size];
	}
	else if((idx/size == 3) && (idx != (size-1)*size) && (idx != (size*size - 1))){
		d_out[idx] = G*d_in[idx - size];
	}
	
	else if ((idx%size == 0) && (idx != 0) && (idx != (size-1)*size)){
		d_out[idx] = G*d_in[idx + 1];
	}
	
	else if((idx%size == 3) && (idx != (size -1)) && (idx != (size*size - 1))){
		d_out[idx] = G*d_in[idx - 1];
	}
	else {
		d_out[idx] = d_in[idx];
	}
	
//	printf("updating sides and idx is %d, and u[idx] is %f\n", idx, d_out[idx]);

}

__global__ void updateCorners(float *d_out, float *d_in){
	int idx = threadIdx.x;
	int size = 4;
	float G = 0.75;

	if ((idx == 0) || (idx == (size - 1))){
		d_out[idx] = G*d_in[idx + size];
	} else if ((idx == (size-1)*size) || (idx == (size*size - 1))){
		d_out[idx] = G*d_in[idx - size];
	} else {
		d_out[idx] = d_in[idx];
	}
	
//	printf("updating corners and idx is %d, and u[idx] is %f\n", idx, d_out[idx]);

}

int main(int argc, char **argv){
	int iterations = atoi(argv[1]);
	int size = 16;
	float u2[size];
	float u1[size];
	float u[size];
	float *d1_in, *d2_in, *d_in, *d_out;
/*	float *center_in, *center_out;
	float *sides_in, *sides_out;
	float *corners_in, *corners_out;
	int center_size = 7;
	int sides_size = 4;
	int corners_size = 4;
*///initialize arrays
	for(int i=0; i<size; i++){
	//	for(int j=0; j<4; j++){
			u2[i] = 0;
			if (i==10)
				u1[i] = 1;
			else
				u1[i] = 0;
	//	}
	}

/*	cudaMalloc(&center_in, 7);
	cudaMalloc(&center_out, 1);
	cudaMalloc(&sides_in, 4);
	cudaMalloc(&sides_out, 8);
	cudaMalloc(&corners_in, 4);
	cudaMalloc(&corners_out, 4);
*/	cudaMalloc(&d1_in, size);
	cudaMalloc(&d2_in, size);
	cudaMalloc(&d_out, size);
	cudaMalloc(&d_in, size);
	
//	for(int i=0; i<iterations; i++){
	cudaMemcpy(d1_in, u1, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d2_in, u2, size, cudaMemcpyHostToDevice);

	updateCenter<<<1, size>>>(d_out, d1_in, d2_in);

	cudaMemcpy(u, d_out, size, cudaMemcpyDeviceToHost);	

	cudaMemcpy(d_in, u, size, cudaMemcpyHostToDevice);

	updateSides<<<1, size>>>(d_out, d_in);

	cudaMemcpy(u, d_out, size, cudaMemcpyDeviceToHost);

	cudaMemcpy(d_in, u, size, cudaMemcpyHostToDevice);

	updateCorners<<<1, size>>>(d_out, d_in);

	cudaMemcpy(u, d_out, size, cudaMemcpyDeviceToHost);
	
	for(int j=0; j<size; j++){
		u2[j] = u1[j];
	}

	for(int j=0; j<size; j++){
		u1[j] = u[j];
	}
	
	for(int j=0; j<size; j++){
		printf("%f, ", u[j]);
	}
	printf("\n");
//	}
}
