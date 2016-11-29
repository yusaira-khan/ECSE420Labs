#include <stdio.h>
#include <stdlib.h>

__global__ void update(float *d_out, float *d_in) {
	int idx = blockDim.x * blockIdx.x + threadIdx.x;
	float rho = 0.5;
	float eta = 0.0002;
	float G = 0.75;
	int size = 4;
	
	//update center
	if((idx/size != 0) && (idx/size != 3) && (idx%size != 0) && (idx%size != 3)) {
		d_out[idx] = (rho*(d_in[idx-1] + d_in[idx+1] + d_in[idx-size] +d_in[idx+size] - 4*d_in[idx]) + 2*d_in[idx] - (1-eta)*d_in[idx+size*size])/(1+eta);
	}
	
	//update sides
	else if((idx/size == 0) && (idx != 0) && (idx != (size -1))){
		d_out[idx] = G*(rho*(d_in[idx-1+size] + d_in[idx+1+size] + d_in[idx-size+size] +d_in[idx+size+size] - 4*d_in[idx+size]) + 2*d_in[idx+size] - (1-eta)*d_in[idx+size*size+size])/(1+eta);
	}
	else if((idx/size == 3) && (idx != (size-1)*size) && (idx != (size*size - 1))){
		d_out[idx] = G*(rho*(d_in[idx-1-size] + d_in[idx+1-size] + d_in[idx-size-size] +d_in[idx+size-size] - 4*d_in[idx-size]) + 2*d_in[idx-size] - (1-eta)*d_in[idx+size*size-size])/(1+eta);
	}
	
	else if ((idx%size == 0) && (idx != 0) && (idx != (size-1)*size)){
		d_out[idx] = G*(rho*(d_in[idx-1+1] + d_in[idx+1+1] + d_in[idx-size+1] +d_in[idx+size+1] - 4*d_in[idx+1]) + 2*d_in[idx+1] - (1-eta)*d_in[idx+size*size+1])/(1+eta);
	}
	
	else if((idx%size == 3) && (idx != (size -1)) && (idx != (size*size - 1))){
		d_out[idx] = G*(rho*(d_in[idx-1-1] + d_in[idx+1-1] + d_in[idx-size-1] +d_in[idx+size-1] - 4*d_in[idx-1]) + 2*d_in[idx-1] - (1-eta)*d_in[idx+size*size-1])/(1+eta);
	}
	
	//update corners
	else if (idx == 0){
		d_out[idx] = G*G*(rho*(d_in[idx-1+size+1] + d_in[idx+1+size+1] + d_in[idx-size+size+1] +d_in[idx+size+size+1] - 4*d_in[idx+size+1]) + 2*d_in[idx+size+1] - (1-eta)*d_in[idx+size*size+size+1])/(1+eta);
	} else if(idx == (size - 1)){
		d_out[idx] = G*G*(rho*(d_in[idx-1+size-1] + d_in[idx+1+size-1] + d_in[idx-size+size-1] +d_in[idx+size+size-1] - 4*d_in[idx+size-1]) + 2*d_in[idx+size-1] - (1-eta)*d_in[idx+size*size+size-1])/(1+eta);
	} else if (idx == (size-1)*size){
		d_out[idx] = G*G*(rho*(d_in[idx-1-size+1] + d_in[idx+1-size+1] + d_in[idx-size-size+1] +d_in[idx+size-size+1] - 4*d_in[idx-size+1]) + 2*d_in[idx-size+1] - (1-eta)*d_in[idx+size*size-size+1])/(1+eta);
	} else if (idx == (size*size - 1)){
		d_out[idx] = G*G*(rho*(d_in[idx-1-size-1] + d_in[idx+1-size-1] + d_in[idx-size-size-1] +d_in[idx+size-size-1] - 4*d_in[idx-size-1]) + 2*d_in[idx-size-1] - (1-eta)*d_in[idx+size*size-size-1])/(1+eta);
	}
}

int main(int argc, char **argv){
	int iterations = atoi(argv[1]);
	int size = 16;
	int size_bytes = size*sizeof(float);
	float u1_2[2*size];
	float u[size];
	float *d_in, *d_out;

//initialize arrays
	for(int i=0; i<2*size; i++){
		if (i==10)
			u1_2[i] = 1;
		else
			u1_2[i] = 0;
	}
	
	for(int i=0; i<size; i++){
		u[i] = 0;
	}

	cudaMalloc(&d_in, 2*size_bytes);
	cudaMalloc(&d_out, size_bytes);
	
	for(int i=0; i<iterations; i++){
		cudaMemcpy(d_in, u1_2, 2*size_bytes, cudaMemcpyHostToDevice);

		update<<<size, 1>>>(d_out, d_in);

		cudaMemcpy(u, d_out, size_bytes, cudaMemcpyDeviceToHost);	
		
		for(int j=0; j<size; j++){
			u1_2[j+size] = u1_2[j];
		}

		for(int j=0; j<size; j++){
			u1_2[j] = u[j];
		}
		
		printf("%f\n", u[10]);
	}
	
	cudaFree(d_in);
	cudaFree(d_out);
}
