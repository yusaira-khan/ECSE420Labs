from mpi4py import MPI
import sys

#define constants
iterations = int(sys.argv[1])
size = 4
rho = 0.5
eta = 0.0002
G = 0.75

#initialize arrays
u = [0 for i in range(size*size)]
u1 = [0 for i in range(size*size)]
u2 = [0 for i in range(size*size)]
u1[size*size/2 + size/2] = 1

#keep track of which elements of the grid are in the corner, on the sides or in the center
corners = []
sides_top = []
sides_right = []
sides_left = []
sides_bottom = []
center = []

for elem in range(size*size):
	if (elem == 0) or (elem == (size-1)) or (elem == (size*(size-1))) or (elem == (size*size-1)):
		corners.append(elem)
	elif (elem/size == 0):
		sides_top.append(elem)
	elif (elem/size == (size-1)):
		sides_bottom.append(elem)
	elif (elem%size == 0):
		sides_right.append(elem)
	elif (elem%size == (size-1)):
		sides_left.append(elem)
	else:
		center.append(elem)

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

for iteration in range(iterations):

	#sides send their data to center elements and once center has updated, sides receive that value and then update
	for elem in sides_top:
		if (rank == elem):
			comm.send(u1[elem], dest=(elem+size))
			u_center = comm.recv(source=(elem+size))
			u[elem] = G*u_center
			u2[elem] = u1[elem]
			u1[elem] = u[elem]

	for elem in sides_right:
		if (rank == elem):
			comm.send(u1[elem], dest=(elem+1))
			u_center = comm.recv(source=(elem+1))
			u[elem] = G*u_center
			if (elem == size):
				comm.send(u[elem], dest=(elem-size))
			if (elem == (size-2)*size):
				comm.send(u[elem], dest=(elem+size))
			u2[elem] = u1[elem]
			u1[elem] = u[elem]

	for elem in sides_left:
		if (rank == elem):
			comm.send(u1[elem], dest=(elem-1))
			u_center = comm.recv(source=(elem-1))
			u[elem] = G*u_center
			if (elem == (2*size-1)):
				comm.send(u[elem], dest=(elem-size))
			if (elem == ((size-1)*size - 1)):
				comm.send(u[elem], dest=(elem+size))
			u2[elem] = u1[elem]
			u1[elem] = u[elem]

	for elem in sides_bottom:
		if (rank == elem):
			comm.send(u1[elem], dest=(elem-size))
			u_center = comm.recv(source=(elem-size))
			u[elem] = G*u_center
			u2[elem] = u1[elem]
			u1[elem] = u[elem]

	#center elements send and receive data then update then send updated value to sides
	for elem in center:
		if (rank == elem):
			#for bigger grid need more checks here since only check for corner center elements which send their data to 2 other elements
			if (elem == (size + 1)) or (elem == (size*2-2)):
				comm.send(u1[elem], dest=(elem + size))
			if (elem == (size*(size-2) + 1)) or (elem == (size*(size-1)-2)):
				comm.send(u1[elem], dest=(elem - size))
			if (elem == (size + 1)) or (elem == (size*(size-2)+1)):
				comm.send(u1[elem], dest=(elem + 1))
			if (elem == (size*2-2)) or (elem == (size*(size-1)-2)):
				comm.send(u1[elem], dest=(elem - 1)) 
			u1_t = comm.recv(source=(elem-size))
			u1_r = comm.recv(source=(elem-1))
			u1_l = comm.recv(source=(elem+1))
			u1_b = comm.recv(source=(elem+size))
			u[elem] = (rho * (u1_t + u1_r + u1_l + u1_b - 4*u1[elem]) + 2*u1[elem] - (1-eta)*u2[elem])/(1+eta)
			if (elem == (size/2*size + 2)):
				print u[elem]
			if (elem == (size + 1)) or (elem == (size*2-2)):
				comm.send(u[elem], dest=(elem - size))
			if (elem == (size*(size-2) + 1)) or (elem == (size*(size-1)-2)):
				comm.send(u[elem], dest=(elem + size))
			if (elem == (size + 1)) or (elem == (size*(size-2)+1)):
				comm.send(u[elem], dest=(elem - 1))
			if (elem == (size*2-2)) or (elem == (size*(size-1)-2)):
				comm.send(u[elem], dest=(elem + 1)) 
			
			u2[elem] = u1[elem]
			u1[elem] = u[elem]

	#once sides have updated, corners receive sides values and update
	for elem in corners:
		if (rank == elem):
			if (elem/size == 0):
				u_sides = comm.recv(source=elem+size)
				u[elem] = G*u_sides
			else:
				u_sides = comm.recv(source=elem-size)
				u[elem] = G*u_sides
			u2[elem] = u1[elem]
			u1[elem] = u[elem]
	
#	print rank, u
#	print rank, u2, u1

