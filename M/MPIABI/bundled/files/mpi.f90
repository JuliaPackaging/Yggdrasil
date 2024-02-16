! gfortran -fcray-pointer -c hello_mpif.f90
! gfortran -o hello_mpif hello_mpif.o
module mpi
  implicit none
  public

  private ::MPI_DUMMY_VAR
  private :: MPI_BOTTOM_PTR
  private :: MPI_IN_PLACE_PTR
  private :: MPI_BUFFER_AUTOMATIC_PTR
  private :: MPI_ARGV_NULL_PTR
  private :: MPI_ARGVS_NULL_PTR
  private :: MPI_ERRCODES_IGNORE_PTR
  private :: MPI_STATUS_IGNORE_PTR
  private :: MPI_STATUSES_IGNORE_PTR
  private :: MPI_UNWEIGHTED_PTR
  private :: MPI_WEIGHTS_EMPTY_PTR

  include "mpif.h"
end module mpi
