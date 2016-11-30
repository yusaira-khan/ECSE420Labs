#include <stdio.h>

__global__ void update(float * d_u, float * d_u1, float * d_u2){
	int idx = blockDim.x * blockIdx.x + threadIdx.x;
	float rho = 0.5;
	float eta = 0.0002;
	float g = 0.75;
	int size = 512;
	
	//Internal
	if(idx % size != 0 && idx % size != (size-1) && idx > size-1 && idx < size*size - size) { 
		d_u[idx] = (rho * (d_u1[idx - size] + d_u1[idx + size] + d_u1[idx - 1] + d_u1[idx + 1] - 4 * d_u1[idx]) + 2 * d_u1[idx] - (1 - eta) * d_u2[idx]) / (1 + eta);
	} 
	//Edges
	else if(idx % size == 0 && idx != 0 && idx != size * size - size) {
		d_u[idx] = g * ((rho * (d_u1[idx + 1 - size] + d_u1[idx + 1 + size] + d_u1[idx] + d_u1[idx + 2] - 4 * d_u1[idx + 1]) + 2 * d_u1[idx + 1] - (1 - eta) * d_u2[idx + 1]) / (1 + eta));
	} else if(idx % size == size-1 && idx != size - 1 && idx != size * size - 1 ) { 
		d_u[idx] = g * ((rho * (d_u1[idx - 1 - size] + d_u1[idx - 1 + size] + d_u1[idx - 2] + d_u1[idx] - 4 * d_u1[idx - 1]) + 2 * d_u1[idx - 1] - (1 - eta) * d_u2[idx - 1]) / (1 + eta));
	} else if(idx < size - 1 && idx > 0) { //edge
		d_u[idx] = g * ((rho * (d_u1[idx] + d_u1[idx + 2 * size] + d_u1[idx + size - 1] + d_u1[idx + size + 1] - 4 * d_u1[idx + size]) + 2 * d_u1[idx + size] - (1 - eta) * d_u2[idx + size]) / (1 + eta));
	} else if(idx < size * size - 1 && idx > size*size - size) { 
		d_u[idx] = g * ((rho * (d_u1[idx -  2 * size] + d_u1[idx] + d_u1[idx - size - 1] + d_u1[idx - size + 1] - 4 * d_u1[idx - size]) + 2 * d_u1[idx - size] - (1 - eta) * d_u2[idx - size]) / (1 + eta));
	} 

	//Corners
	else if(idx == 0) { 
		d_u[idx] = g * g * ((rho * (d_u1[idx + 1] + d_u1[idx + 2 * size + 1 ] + d_u1[idx + size] + d_u1[idx + size + 2] - 4 * d_u1[idx + size + 1]) + 2 * d_u1[idx + size + 1] - (1 - eta) * d_u2[idx + size + 1]) / (1 + eta));
	} else if ( idx == size - 1) {
		d_u[idx] = g * g * ((rho * (d_u1[idx  - 1] + d_u1[idx + 2 * size - 1] + d_u1[idx + size - 2] + d_u1[idx + size] - 4 * d_u1[idx + size - 1]) + 2 * d_u1[idx + size - 1] - (1 - eta) * d_u2[idx + size - 1]) / (1 + eta));
	} else if ( idx == size * size - 1 ) { 
		d_u[idx] = g * g * ((rho * (d_u1[idx - 2 * size - 1] + d_u1[idx - 1] + d_u1[idx - size - 2] + d_u1[idx - size] - 4 * d_u1[idx - size - 1]) + 2 * d_u1[idx - size - 1] - (1 - eta) * d_u2[idx - size - 1]) / (1 + eta));
	} else if ( idx == size * size - size ) { 
		d_u[idx] = g * g * ((rho * (d_u1[idx - 2 * size + 1] + d_u1[idx  + 1] + d_u1[idx - size] + d_u1[idx - size + 2] - 4 * d_u1[idx - size + 1]) + 2 * d_u1[idx - size + 1] - (1 - eta) * d_u2[idx - size + 1]) / (1 + eta));
	}
	
	if(idx == (size*size/2 + size/2)) {
		printf("%f, \n", d_u[idx]);
	}
}



int main(int argc, char ** argv) {
	int iterations = atoi(argv[1]);
	const int size = 512 * 512;
	
	float *h_u = (float *)malloc(size * sizeof(float));
	float *h_u1 = (float *)malloc(size * sizeof(float));
	float *h_u2 = (float *)malloc(size * sizeof(float));
	for (int j = 0; j < size; j++) {
		h_u[j] = 0;
		h_u1[j] = 0;
		h_u2[j] = 0;
	}

	h_u1[size / 2 + 256] = 1.0;
	float *d_u;
	float *d_u1;
	float *d_u2;

	cudaMalloc(&d_u, size * sizeof(float));
	cudaMalloc(&d_u1, size * sizeof(float));
	cudaMalloc(&d_u2, size * sizeof(float));

	cudaMemcpy(d_u, h_u, size * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_u1, h_u1, size * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_u2, h_u2, size * sizeof(float), cudaMemcpyHostToDevice);

	free(h_u);
	free(h_u1);
	free(h_u2);

	for (int i = 0; i < iterations; i++) {
		update<<<512, 512>>>(d_u, d_u1, d_u2);
		float* temp = d_u2;
    	d_u2 = d_u1;
    	d_u1 = d_u;
  		d_u = temp;
	}

	cudaFree(d_u);
	cudaFree(d_u1);
	cudaFree(d_u2);

	return 0;
}

