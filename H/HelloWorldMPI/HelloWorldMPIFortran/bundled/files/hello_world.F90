program hello_world
  use mpi
  implicit none

  character*(MPI_MAX_LIBRARY_VERSION_STRING) library_version
  character*(MPI_MAX_PROCESSOR_NAME) processor_name
  integer version, subversion
  integer size, rank

  integer proc
  integer resultlen
  integer ierror

  call MPI_Init(ierror)

  call MPI_Comm_size(MPI_COMM_WORLD, size, ierror)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierror)
  if (rank == 0) then
     call MPI_Get_library_version(library_version, resultlen, ierror)
     print '("This is")'
     print '(a)', trim(library_version)
     call MPI_Get_version(version, subversion, ierror)
     print '("This implements the MPI standard version ",i0,".",i0," (found at build time)")', MPI_VERSION, MPI_SUBVERSION
     print '("This implements the MPI standard version ",i0,".",i0," (found at run time)")', version, subversion
! #if defined MPI_ABI_VERSION
!     printf("This implements the MPI ABI version %d.%d\n", MPI_ABI_VERSION, MPI_ABI_SUBVERSION);
! #endif
  end if

  do proc = 0, size - 1
     if (rank == proc) then
        call MPI_Get_processor_name(processor_name, resultlen, ierror)
        print '("This is process ",i0," of ",i0," running on ",a)', rank, size, processor_name
     end if
     call MPI_Barrier(MPI_COMM_WORLD, ierror)
  end do

  call MPI_Finalize(ierror)
end program hello_world
