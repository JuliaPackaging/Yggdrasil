
CFLAGS = -std=c++14 -Wall -fopenmp -w -O3
LDFLAGS = -shared
# CHANGE TO directory where FEA and LSM include folders are
# parent directory for FEA files
# parent directory for FEA files

FEA_DIR = .
#LSM_DIR = ./M2DO_LSM/

# CHANGE TO the directory where you want your .o files stored
M2DO_FEA_OBJ_DIR = $(FEA_DIR)/bin

# Include directories
FEA_INCL = $(FEA_DIR)/include
#LSM_INCL = $(LSM_DIR)/include
INCLUDES = -I$(FEA_INCL) #-I$(LSM_INCL)

SRC_DIR = $(FEA_DIR)/src
# List of .o files
# Comment out uncessary object files (if needed)
M2DO_OBJ = $(M2DO_FEA_OBJ_DIR)/quadrature.o \
$(M2DO_FEA_OBJ_DIR)/linear_shape.o \
$(M2DO_FEA_OBJ_DIR)/node.o \
$(M2DO_FEA_OBJ_DIR)/solid_element.o \
$(M2DO_FEA_OBJ_DIR)/solid_material.o \
$(M2DO_FEA_OBJ_DIR)/mesh.o \
$(M2DO_FEA_OBJ_DIR)/boundary_conditions.o \
$(M2DO_FEA_OBJ_DIR)/stationary_study.o \
$(M2DO_FEA_OBJ_DIR)/sensitivity.o \
# Compile all the M2DO FEA object files
all: $(M2DO_OBJ)
# Make commands for each individual object file
$(M2DO_FEA_OBJ_DIR)/quadrature.o: $(SRC_DIR)/quadrature.cpp $(FEA_INCL)/quadrature.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/quadrature.o $(SRC_DIR)/quadrature.cpp
$(M2DO_FEA_OBJ_DIR)/linear_shape.o: $(SRC_DIR)/linear_shape_function.cpp $(FEA_INCL)/linear_shape_function.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/linear_shape.o $(SRC_DIR)/linear_shape_function.cpp
$(M2DO_FEA_OBJ_DIR)/node.o: $(SRC_DIR)/node.cpp $(FEA_INCL)/node.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/node.o $(SRC_DIR)/node.cpp
$(M2DO_FEA_OBJ_DIR)/solid_element.o: $(SRC_DIR)/solid_element.cpp $(FEA_INCL)/solid_element.h $(FEA_INCL)/quadrature.h $(FEA_INCL)/linear_shape_function.h $(FEA_INCL)/mesh.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/solid_element.o $(SRC_DIR)/solid_element.cpp
$(M2DO_FEA_OBJ_DIR)/solid_material.o: $(SRC_DIR)/solid_material.cpp $(FEA_INCL)/solid_material.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/solid_material.o $(SRC_DIR)/solid_material.cpp
$(M2DO_FEA_OBJ_DIR)/mesh.o: $(SRC_DIR)/mesh.cpp $(FEA_INCL)/mesh.h $(FEA_INCL)/quadrature.h $(FEA_INCL)/linear_shape_function.h $(FEA_INCL)/node.h $(FEA_INCL)/solid_element.h $(FEA_INCL)/solid_material.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/mesh.o $(SRC_DIR)/mesh.cpp
$(M2DO_FEA_OBJ_DIR)/boundary_conditions.o: $(SRC_DIR)/boundary_conditions.cpp $(FEA_INCL)/boundary_conditions.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/boundary_conditions.o $(SRC_DIR)/boundary_conditions.cpp
$(M2DO_FEA_OBJ_DIR)/sensitivity.o: $(SRC_DIR)/sensitivity.cpp $(FEA_INCL)/sensitivity.h $(FEA_INCL)/stationary_study.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/sensitivity.o $(SRC_DIR)/sensitivity.cpp
$(M2DO_FEA_OBJ_DIR)/stationary_study.o: $(SRC_DIR)/stationary_study.cpp $(FEA_INCL)/stationary_study.h $(FEA_INCL)/mesh.h $(FEA_INCL)/boundary_conditions.h #$(FEA_INCL)/ma57_solver.h
	$(CXX) $(CFLAGS) $(INCLUDES) -fPIC -c -o $(M2DO_FEA_OBJ_DIR)/stationary_study.o $(SRC_DIR)/stationary_study.cpp
###############################################################################
# Add your own makes here
###############################################################################
# List of targets for executables you write

m2do_fea.so: $(M2DO_OBJ)
	$(CXX) $(LDFLAGS) $(INCLUDES) -o $@ $(M2DO_OBJ)
.PHONY: clean install all

all: m2do_fea.so

install: m2do_fea.so
	install -d $(libdir)
	install -m 644 m2do_fea.so $(libdir)
	install -d $(includedir)
	install -m 644 include/M2DO_FEA.h $(includedir)
clean:
	rm -f M2DO_FEA ${M2DO_OBJ}