#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
  MPI_Init(&argc, &argv);

  int size;
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  if (rank == 0) {
    char library_version[MPI_MAX_LIBRARY_VERSION_STRING];
    int resultlen;
    MPI_Get_library_version(library_version, &resultlen);
    printf("This is\n%s\n", library_version);

    int version, subversion;
    MPI_Get_version(&version, &subversion);
    printf("This implements the MPI standard version %d.%d (found at build time)\n", MPI_VERSION, MPI_SUBVERSION);
    printf("This implements the MPI standard version %d.%d (found at run time)\n", version, subversion);

#if defined MPI_ABI_VERSION
    printf("This implements the MPI ABI version %d.%d\n", MPI_ABI_VERSION, MPI_ABI_SUBVERSION);
#endif
  }

  for (int proc = 0; proc < size; ++ proc) {
    if (rank == proc) {
      char name[MPI_MAX_PROCESSOR_NAME];
      int resultlen;
      MPI_Get_processor_name(name, &resultlen);
      printf("This is process %d of %d running on %s\n", rank, size, name);
    }
    MPI_Barrier(MPI_COMM_WORLD);
  }

  MPI_Finalize();

  return 0;
}
