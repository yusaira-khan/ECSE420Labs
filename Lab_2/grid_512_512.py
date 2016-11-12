from mpi4py import MPI
import sys

#define constants
iterations = int(sys.argv[1])
size = 512 
rho = 0.5
eta = 0.0002
G = 0.75

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
num_processes = comm.Get_size()
rows_per_process = size/num_processes
#initialize arrays
u = [0 for i in range(size*size)]
u1 = [0 for i in range(size*size)]
u2 = [0 for i in range(size*size)]
u1[size*size/2 + size/2] = 1



for iteration in range(iterations):

	#sides send their data to center elements and once center has updated, sides receive that value and then update

	#center elements send and receive data then update then send updated value to sides

	for row in range(1, rows_per_process - 1 ):
		row_index= rank * rows_per_process + row
		for col in range(1, size - 1 ):
			elem = row_index * size + col
			u1_t = u1[(elem - size)]
			u1_r = u1[(elem - 1)]
			u1_l = u1[(elem + 1)]
			u1_b = u1[(elem + size)]
			u[elem] = (rho * (u1_t + u1_r + u1_l + u1_b - 4 * u1[elem]) + 2 * u1[elem] - (1 - eta) * u2[elem]) / (1 + eta)
			u2[elem] = u1[elem]
			u1[elem] = u[elem]
		elem = row_index * size + 0 #right side
		u_center =  u[elem + 1] 
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
			
		elem += size - 1 #left side
		u_center =  u[elem - 1] 
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
	
	if (rank == 0 ): #topmost row
		row_index = 0
		for col in range(1,size-1 ):
			elem = row_index * size + col
			u_center =  G * u1[elem + size]
			u[elem] = G * u_center
			
			u2[elem] = u1[elem]
			u1[elem] = u[elem]
		elem =  0 #top right corner
		u_center =  u1[elem + size]
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
			
		elem += size - 1 #top left corner
		u_center =  u1[elem + size]
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]

	if (rank == num_processes - 1 ):#bottommost row
		
		row_index = size-1
		for col in range(1, size - 1 ):
			elem = row_index * size + col
			u_center =  G * u1[elem - size]
			u[elem] = G * u_center
				
			u2[elem] = u1[elem]
			u1[elem] = u[elem]
		elem = row_index * size + 0 # bottom right corner
		u_center =  u[elem - size] 
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
			
		elem += size - 1 #left side
		u_center =  u[elem - size] #bottom left corner
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]

	if (rank != 0 ): #top row of middle block of rows
		row_index = rank * rows_per_process + 0
		#sending topmost row
		comm.send(u1[(row_index * size) : (row_index + 1) * size], dest=(rank - 1))
		recvd = comm.recv(source=( rank  - 1))
		for col in range(1,size-1 ):
			elem = row_index * size + col
			u1_t = recvd[col] 
			u1_r = u1[(elem-1)]
			u1_l = u1[(elem+1)]
			u1_b = u1[(elem+size)]
			u[elem] = (rho * (u1_t + u1_r + u1_l + u1_b - 4*u1[elem]) + 2*u1[elem] - (1-eta)*u2[elem])/(1+eta)
			
			u2[elem] = u1[elem]
			u1[elem] = u[elem]
		elem = row_index * size + 0 #right side
		u_center =  u1[elem + 1]
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
			
		elem += size - 1 #left side
		u_center =  u1[elem - 1]
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
	
	if (rank != num_processes-1): #bottom row of middle block of rows

		row_index = (rank + 1) * rows_per_process - 1
		#sending bottommost row		
		recvd = comm.recv(source=( rank  + 1))
		comm.send(u1[(row_index * size) : (row_index + 1) * size], dest=(rank + 1))
		for col in range(1, size - 1 ):
			elem = row_index * size + col
			u1_t =  u1[(elem - size)]
			u1_r = u1[(elem - 1)]
			u1_l = u1[(elem + 1)]
			u1_b =  recvd[col]
			u[elem] = (rho * (u1_t + u1_r + u1_l + u1_b - 4*u1[elem]) + 2*u1[elem] - (1-eta)*u2[elem])/(1+eta)
			
			u2[elem] = u1[elem]
			u1[elem] = u[elem]
		elem = row_index * size + 0 #right side
		u_center =  u[elem + 1] 
		u[elem] = G * u_center
		u2[elem] = u1[elem]
		u1[elem] = u[elem]
			
		elem += size - 1 #left side
		u_center =  u[elem - 1] 
		u[elem] = G * u_center
		u2[elem] = u1[elem]
	
	
	
			
	

