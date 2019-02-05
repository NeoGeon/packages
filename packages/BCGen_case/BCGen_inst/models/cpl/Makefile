SRC=baseCpl.F90
include ../Makefile.conf
OBJS_ALL = ./*.o
BASE_DEPS = $(LIBDIR)/*.o
ESMF_DEPS=$(ESMF_LIB)/libesmf.a
DEPS=-lmct -lnetcdf -lnetcdff -lmpeu -lpio -lesmf -lpio -lgptl -lpnetcdf
ESMF_DEPS = -lesmf -lrt -lstdc++ -ldl
FLAGS=-pthread
EXE= main
MAIN=main.F90

EXE:
	$(FC) -c -I$(INCLDIR) -I$(ESMF_MOD) -L$(LIBDIR) baseCpl.F90
	echo 'finish mod'
	$(FC) -o $(EXE) $(MAIN) $(OBJS_ALL) $(BASE_DEPS) $(FLAGS) -I$(INCLDIR) -L$(LIBDIR) \
	$(DEPS) $(ESMF_DEPS)
	#mv $(EXE) $(BINDIR)
