# Makefile

.SUFFIXES : .f90 

F90MOD = -module

F90FLAGS = $(F90MOD)

OBJ := $(patsubst %.f90,%.o,$(wildcard *.f90) )

all : $(OBJ)

clean :
	rm -f *.o *.mod

%.o: %.f90
	$(FC) $(F90FLAGS) $(OPT) -c $<

Domain.o : Element.o Face.o Sources.o Receivers.o logical_input.o Vertex.o TimeP.o Subdomains.o Edge.o Comm.o PlaneW.o Neumann.o Surface.o 

Sources.o : pi.o 
