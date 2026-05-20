// For MPICH

#include "mpi_abi.h"

////////////////////////////////////////////////////////////////////////////////
// Types

typedef int MPI_Fint;

typedef MPI_Status MPI_F08_Status;

////////////////////////////////////////////////////////////////////////////////
// Constants

#define MPI_F_STATUS_IGNORE ((MPI_Fint *)MPI_STATUS_IGNORE)
#define MPI_F_STATUSES_IGNORE ((MPI_Fint *)MPI_STATUSES_IGNORE)
#define MPI_F08_STATUS_IGNORE ((MPI_F08_Status *)MPI_STATUS_IGNORE)
#define MPI_F08_STATUSES_IGNORE ((MPI_F08_Status *)MPI_STATUSES_IGNORE)

////////////////////////////////////////////////////////////////////////////////
// Status functions

__attribute__((visibility("default"))) int
PMPI_Status_f2c(const MPI_Fint *f_status, MPI_Status *c_status) {
  if (f_status == MPI_F_STATUS_IGNORE || f_status == MPI_F_STATUSES_IGNORE ||
      c_status == MPI_STATUS_IGNORE || c_status == MPI_STATUSES_IGNORE)
    return MPI_ERR_ARG;
  *c_status = *(const MPI_Status *)f_status;
  return MPI_SUCCESS;
}

__attribute__((visibility("default"))) int
PMPI_Status_c2f(const MPI_Status *c_status, MPI_Fint *f_status) {
  if (c_status == MPI_STATUS_IGNORE || c_status == MPI_STATUSES_IGNORE ||
      f_status == MPI_F_STATUS_IGNORE || f_status == MPI_F_STATUSES_IGNORE)
    return MPI_ERR_ARG;
  *(MPI_Status *)f_status = *c_status;
  return MPI_SUCCESS;
}

__attribute__((visibility("default"))) int
PMPI_Status_f082c(const MPI_F08_Status *f08_status, MPI_Status *c_status) {
  if (f08_status == MPI_F08_STATUS_IGNORE ||
      f08_status == MPI_F08_STATUSES_IGNORE || c_status == MPI_STATUS_IGNORE ||
      c_status == MPI_STATUSES_IGNORE)
    return MPI_ERR_ARG;
  *c_status = *(const MPI_Status *)f08_status;
  return MPI_SUCCESS;
}

__attribute__((visibility("default"))) int
PMPI_Status_c2f08(const MPI_Status *c_status, MPI_F08_Status *f08_status) {
  if (c_status == MPI_STATUS_IGNORE || c_status == MPI_STATUSES_IGNORE ||
      f08_status == MPI_F08_STATUS_IGNORE ||
      f08_status == MPI_F08_STATUSES_IGNORE)
    return MPI_ERR_ARG;
  *(MPI_Status *)f08_status = *c_status;
  return MPI_SUCCESS;
}

__attribute__((visibility("default"))) int
MPI_Status_f2c(const MPI_Fint *f_status, MPI_Status *c_status) {
  return PMPI_Status_f2c(f_status, c_status);
}

__attribute__((visibility("default"))) int
MPI_Status_c2f(const MPI_Status *c_status, MPI_Fint *f_status) {
  return PMPI_Status_c2f(c_status, f_status);
}

__attribute__((visibility("default"))) int
MPI_Status_f082c(const MPI_F08_Status *f08_status, MPI_Status *c_status) {
  return PMPI_Status_f082c(f08_status, c_status);
}

__attribute__((visibility("default"))) int
MPI_Status_c2f08(const MPI_Status *c_status, MPI_F08_Status *f08_status) {
  return PMPI_Status_c2f08(c_status, f08_status);
}

////////////////////////////////////////////////////////////////////////////////
// Handle functions

__attribute__((visibility("default"))) MPI_Comm PMPI_Comm_f2c(MPI_Fint comm) {
  return MPI_Comm_fromint(comm);
}

__attribute__((visibility("default"))) MPI_Fint PMPI_Comm_c2f(MPI_Comm comm) {
  return MPI_Comm_toint(comm);
}

__attribute__((visibility("default"))) MPI_Errhandler
PMPI_Errhandler_f2c(MPI_Fint errhandler) {
  return MPI_Errhandler_fromint(errhandler);
}

__attribute__((visibility("default"))) MPI_Fint
PMPI_Errhandler_c2f(MPI_Errhandler errhandler) {
  return MPI_Errhandler_toint(errhandler);
}

__attribute__((visibility("default"))) MPI_File PMPI_File_f2c(MPI_Fint file) {
  return MPI_File_fromint(file);
}

__attribute__((visibility("default"))) MPI_Fint PMPI_File_c2f(MPI_File file) {
  return MPI_File_toint(file);
}

__attribute__((visibility("default"))) MPI_Group
PMPI_Group_f2c(MPI_Fint group) {
  return MPI_Group_fromint(group);
}

__attribute__((visibility("default"))) MPI_Fint
PMPI_Group_c2f(MPI_Group group) {
  return MPI_Group_toint(group);
}

__attribute__((visibility("default"))) MPI_Info PMPI_Info_f2c(MPI_Fint info) {
  return MPI_Info_fromint(info);
}

__attribute__((visibility("default"))) MPI_Fint PMPI_Info_c2f(MPI_Info info) {
  return MPI_Info_toint(info);
}

__attribute__((visibility("default"))) MPI_Message
PMPI_Message_f2c(MPI_Fint message) {
  return MPI_Message_fromint(message);
}

__attribute__((visibility("default"))) MPI_Fint
PMPI_Message_c2f(MPI_Message message) {
  return MPI_Message_toint(message);
}

__attribute__((visibility("default"))) MPI_Op PMPI_Op_f2c(MPI_Fint op) {
  return MPI_Op_fromint(op);
}

__attribute__((visibility("default"))) MPI_Fint PMPI_Op_c2f(MPI_Op op) {
  return MPI_Op_toint(op);
}

__attribute__((visibility("default"))) MPI_Request
PMPI_Request_f2c(MPI_Fint request) {
  return MPI_Request_fromint(request);
}

__attribute__((visibility("default"))) MPI_Fint
PMPI_Request_c2f(MPI_Request request) {
  return MPI_Request_toint(request);
}

__attribute__((visibility("default"))) MPI_Session
PMPI_Session_f2c(MPI_Fint session) {
  return MPI_Session_fromint(session);
}

__attribute__((visibility("default"))) MPI_Fint
PMPI_Session_c2f(MPI_Session session) {
  return MPI_Session_toint(session);
}

__attribute__((visibility("default"))) MPI_Datatype
PMPI_Type_f2c(MPI_Fint datatype) {
  return MPI_Type_fromint(datatype);
}

__attribute__((visibility("default"))) MPI_Fint
PMPI_Type_c2f(MPI_Datatype datatype) {
  return MPI_Type_toint(datatype);
}

__attribute__((visibility("default"))) MPI_Win PMPI_Win_f2c(MPI_Fint win) {
  return MPI_Win_fromint(win);
}

__attribute__((visibility("default"))) MPI_Fint PMPI_Win_c2f(MPI_Win win) {
  return MPI_Win_toint(win);
}

__attribute__((visibility("default"))) MPI_Comm MPI_Comm_f2c(MPI_Fint comm) {
  return PMPI_Comm_f2c(comm);
}

__attribute__((visibility("default"))) MPI_Fint MPI_Comm_c2f(MPI_Comm comm) {
  return PMPI_Comm_c2f(comm);
}

__attribute__((visibility("default"))) MPI_Errhandler
MPI_Errhandler_f2c(MPI_Fint errhandler) {
  return PMPI_Errhandler_f2c(errhandler);
}

__attribute__((visibility("default"))) MPI_Fint
MPI_Errhandler_c2f(MPI_Errhandler errhandler) {
  return PMPI_Errhandler_c2f(errhandler);
}

__attribute__((visibility("default"))) MPI_File MPI_File_f2c(MPI_Fint file) {
  return PMPI_File_f2c(file);
}

__attribute__((visibility("default"))) MPI_Fint MPI_File_c2f(MPI_File file) {
  return PMPI_File_c2f(file);
}

__attribute__((visibility("default"))) MPI_Group MPI_Group_f2c(MPI_Fint group) {
  return PMPI_Group_f2c(group);
}

__attribute__((visibility("default"))) MPI_Fint MPI_Group_c2f(MPI_Group group) {
  return PMPI_Group_c2f(group);
}

__attribute__((visibility("default"))) MPI_Info MPI_Info_f2c(MPI_Fint info) {
  return PMPI_Info_f2c(info);
}

__attribute__((visibility("default"))) MPI_Fint MPI_Info_c2f(MPI_Info info) {
  return PMPI_Info_c2f(info);
}

__attribute__((visibility("default"))) MPI_Message
MPI_Message_f2c(MPI_Fint message) {
  return PMPI_Message_f2c(message);
}

__attribute__((visibility("default"))) MPI_Fint
MPI_Message_c2f(MPI_Message message) {
  return PMPI_Message_c2f(message);
}

__attribute__((visibility("default"))) MPI_Op MPI_Op_f2c(MPI_Fint op) {
  return PMPI_Op_f2c(op);
}

__attribute__((visibility("default"))) MPI_Fint MPI_Op_c2f(MPI_Op op) {
  return PMPI_Op_c2f(op);
}

__attribute__((visibility("default"))) MPI_Request
MPI_Request_f2c(MPI_Fint request) {
  return PMPI_Request_f2c(request);
}

__attribute__((visibility("default"))) MPI_Fint
MPI_Request_c2f(MPI_Request request) {
  return PMPI_Request_c2f(request);
}

__attribute__((visibility("default"))) MPI_Session
MPI_Session_f2c(MPI_Fint session) {
  return PMPI_Session_f2c(session);
}

__attribute__((visibility("default"))) MPI_Fint
MPI_Session_c2f(MPI_Session session) {
  return PMPI_Session_c2f(session);
}

__attribute__((visibility("default"))) MPI_Datatype
MPI_Type_f2c(MPI_Fint datatype) {
  return PMPI_Type_f2c(datatype);
}

__attribute__((visibility("default"))) MPI_Fint
MPI_Type_c2f(MPI_Datatype datatype) {
  return PMPI_Type_c2f(datatype);
}

__attribute__((visibility("default"))) MPI_Win MPI_Win_f2c(MPI_Fint win) {
  return PMPI_Win_f2c(win);
}

__attribute__((visibility("default"))) MPI_Fint MPI_Win_c2f(MPI_Win win) {
  return PMPI_Win_c2f(win);
}
