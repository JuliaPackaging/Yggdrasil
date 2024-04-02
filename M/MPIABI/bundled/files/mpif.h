!     Fortran MPI definitions

      integer, parameter :: MPI_VERSION = 4
      integer, parameter :: MPI_SUBVERSION = 2

      integer :: MPI_DUMMY_VAR
      integer, parameter :: MPI_ADDRESS_KIND = kind(loc(MPI_DUMMY_VAR))
      integer, parameter :: MPI_OFFSET_KIND = 8
      integer, parameter :: MPI_COUNT_KIND = 8
      integer, parameter :: MPI_INTEGER_KIND = 4

      integer, parameter :: MPI_STATUS_SIZE = 8
      integer, parameter :: MPI_SOURCE = 1
      integer, parameter :: MPI_TAG = 2
      integer, parameter :: MPI_ERROR = 3

      integer, parameter :: MPI_OP_NULL = int(z'00000020')
      integer, parameter :: MPI_SUM     = int(z'00000021')
      integer, parameter :: MPI_MIN     = int(z'00000022')
      integer, parameter :: MPI_MAX     = int(z'00000023')
      integer, parameter :: MPI_PROD    = int(z'00000024')
      integer, parameter :: MPI_BAND    = int(z'00000028')
      integer, parameter :: MPI_BOR     = int(z'00000029')
      integer, parameter :: MPI_BXOR    = int(z'0000002a')
      integer, parameter :: MPI_LAND    = int(z'00000030')
      integer, parameter :: MPI_LOR     = int(z'00000031')
      integer, parameter :: MPI_LXOR    = int(z'00000032')
      integer, parameter :: MPI_MINLOC  = int(z'00000038')
      integer, parameter :: MPI_MAXLOC  = int(z'00000039')
      integer, parameter :: MPI_REPLACE = int(z'0000003c')
      integer, parameter :: MPI_NO_OP   = int(z'0000003d')

      integer, parameter :: MPI_COMM_NULL  = int(z'00000100')
      integer, parameter :: MPI_COMM_WORLD = int(z'00000101')
      integer, parameter :: MPI_COMM_SELF  = int(z'00000102')

      integer, parameter :: MPI_GROUP_NULL  = int(z'00000108')
      integer, parameter :: MPI_GROUP_EMPTY = int(z'00000109')

      integer, parameter :: MPI_WIN_NULL = int(z'00000110')

      integer, parameter :: MPI_FILE_NULL = int(z'00000118')

      integer, parameter :: MPI_SESSION_NULL = int(z'00000120')

      integer, parameter :: MPI_MESSAGE_NULL    = int(z'00000128')
      integer, parameter :: MPI_MESSAGE_NO_PROC = int(z'00000129')

      integer, parameter :: MPI_INFO_NULL = int(z'00000130')
      integer, parameter :: MPI_INFO_ENV  = int(z'00000131')

      integer, parameter :: MPI_ERRHANDLER_NULL  = int(z'00000140')
      integer, parameter :: MPI_ERRORS_ARE_FATAL = int(z'00000141')
      integer, parameter :: MPI_ERRORS_RETURN    = int(z'00000142')
      integer, parameter :: MPI_ERRORS_ABORT     = int(z'00000143')

      integer, parameter :: MPI_REQUEST_NULL = int(z'00000180')

      integer, parameter :: MPI_DATATYPE_NULL      = int(z'00000200')
      integer, parameter :: MPI_AINT               = int(z'00000201')
      integer, parameter :: MPI_COUNT              = int(z'00000202')
      integer, parameter :: MPI_OFFSET             = int(z'00000203')
      integer, parameter :: MPI_PACKED             = int(z'00000207')
      integer, parameter :: MPI_SHORT              = int(z'00000208')
      integer, parameter :: MPI_INT                = int(z'00000209')
      integer, parameter :: MPI_LONG               = int(z'0000020a')
      integer, parameter :: MPI_LONG_LONG          = int(z'0000020b')
      integer, parameter :: MPI_LONG_LONG_INT      = MPI_LONG_LONG
      integer, parameter :: MPI_UNSIGNED_SHORT     = int(z'0000020c')
      integer, parameter :: MPI_UNSIGNED           = int(z'0000020d')
      integer, parameter :: MPI_UNSIGNED_LONG      = int(z'0000020e')
      integer, parameter :: MPI_UNSIGNED_LONG_LONG = int(z'0000020f')
      integer, parameter :: MPI_FLOAT              = int(z'00000210')
      integer, parameter :: MPI_C_FLOAT_COMPLEX    = int(z'00000212')
      integer, parameter :: MPI_C_COMPLEX          = MPI_C_FLOAT_COMPLEX
      integer, parameter :: MPI_CXX_FLOAT_COMPLEX  = int(z'00000213')
      integer, parameter :: MPI_DOUBLE             = int(z'00000214')
      integer, parameter :: MPI_C_DOUBLE_COMPLEX   = int(z'00000216')
      integer, parameter :: MPI_CXX_DOUBLE_COMPLEX = int(z'00000217')
      integer, parameter :: MPI_LOGICAL            = int(z'00000218')
      integer, parameter :: MPI_INTEGER            = int(z'00000219')
      integer, parameter :: MPI_REAL               = int(z'0000021a')
      integer, parameter :: MPI_COMPLEX            = int(z'0000021b')
      integer, parameter :: MPI_DOUBLE_PRECISION   = int(z'0000021c')
      integer, parameter :: MPI_DOUBLE_COMPLEX     = int(z'0000021d')
      integer, parameter :: MPI_LONG_DOUBLE        = int(z'00000220')
      integer, parameter :: MPI_C_LONG_DOUBLE_COMPLEX                   &
     &     = int(z'00000224')
      integer, parameter :: MPI_CXX_LONG_DOUBLE_COMPLEX                 &
     &     = int(z'00000225')
      integer, parameter :: MPI_FLOAT_INT          = int(z'00000228')
      integer, parameter :: MPI_DOUBLE_INT         = int(z'00000229')
      integer, parameter :: MPI_LONG_INT           = int(z'0000022a')
      integer, parameter :: MPI_2INT               = int(z'0000022b')
      integer, parameter :: MPI_SHORT_INT          = int(z'0000022c')
      integer, parameter :: MPI_LONG_DOUBLE_INT    = int(z'0000022d')
      integer, parameter :: MPI_2REAL              = int(z'00000230')
      integer, parameter :: MPI_2DOUBLE_PRECISION  = int(z'00000231')
      integer, parameter :: MPI_2INTEGER           = int(z'00000232')
      integer, parameter :: MPI_C_BOOL             = int(z'00000238')
      integer, parameter :: MPI_CXX_BOOL           = int(z'00000239')
      integer, parameter :: MPI_WCHAR              = int(z'0000023c')
      integer, parameter :: MPI_INT8_T             = int(z'00000240')
      integer, parameter :: MPI_UINT8_T            = int(z'00000241')
      integer, parameter :: MPI_CHAR               = int(z'00000243')
      integer, parameter :: MPI_SIGNED_CHAR        = int(z'00000244')
      integer, parameter :: MPI_UNSIGNED_CHAR      = int(z'00000245')
      integer, parameter :: MPI_BYTE               = int(z'00000247')
      integer, parameter :: MPI_INT16_T            = int(z'00000248')
      integer, parameter :: MPI_UINT16_T           = int(z'00000249')
      integer, parameter :: MPI_INT32_T            = int(z'00000250')
      integer, parameter :: MPI_UINT32_T           = int(z'00000251')
      integer, parameter :: MPI_INT64_T            = int(z'00000258')
      integer, parameter :: MPI_UINT64_T           = int(z'00000259')
      integer, parameter :: MPIX_LOGICAL1          = int(z'000002c0')
      integer, parameter :: MPI_INTEGER1           = int(z'000002c1')
      integer, parameter :: MPIX_REAL1             = int(z'000002c2')
      integer, parameter :: MPI_CHARACTER          = int(z'000002c3')
      integer, parameter :: MPIX_LOGICAL2          = int(z'000002c8')
      integer, parameter :: MPI_INTEGER2           = int(z'000002c9')
      integer, parameter :: MPI_REAL2              = int(z'000002ca')
      integer, parameter :: MPIX_LOGICAL4          = int(z'000002d0')
      integer, parameter :: MPI_INTEGER4           = int(z'000002d1')
      integer, parameter :: MPI_REAL4              = int(z'000002d2')
      integer, parameter :: MPI_COMPLEX4           = int(z'000002d3')
      integer, parameter :: MPIX_LOGICAL8          = int(z'000002d8')
      integer, parameter :: MPI_INTEGER8           = int(z'000002d9')
      integer, parameter :: MPI_REAL8              = int(z'000002da')
      integer, parameter :: MPI_COMPLEX8           = int(z'000002db')
      integer, parameter :: MPIX_LOGICAL16         = int(z'000002e0')
      integer, parameter :: MPI_INTEGER16          = int(z'000002e1')
      integer, parameter :: MPI_REAL16             = int(z'000002e2')
      integer, parameter :: MPI_COMPLEX16          = int(z'000002e3')
      integer, parameter :: MPI_COMPLEX32          = int(z'000002eb')

!     Error classes
      integer, parameter :: MPI_SUCCESS                         = 0
      integer, parameter :: MPI_ERR_BUFFER                      = 1
      integer, parameter :: MPI_ERR_COUNT                       = 2
      integer, parameter :: MPI_ERR_TYPE                        = 3
      integer, parameter :: MPI_ERR_TAG                         = 4
      integer, parameter :: MPI_ERR_COMM                        = 5
      integer, parameter :: MPI_ERR_RANK                        = 6
      integer, parameter :: MPI_ERR_REQUEST                     = 7
      integer, parameter :: MPI_ERR_ROOT                        = 8
      integer, parameter :: MPI_ERR_GROUP                       = 9
      integer, parameter :: MPI_ERR_OP                          = 10
      integer, parameter :: MPI_ERR_TOPOLOGY                    = 11
      integer, parameter :: MPI_ERR_DIMS                        = 12
      integer, parameter :: MPI_ERR_ARG                         = 13
      integer, parameter :: MPI_ERR_UNKNOWN                     = 14
      integer, parameter :: MPI_ERR_TRUNCATE                    = 15
      integer, parameter :: MPI_ERR_OTHER                       = 16
      integer, parameter :: MPI_ERR_INTERN                      = 17
      integer, parameter :: MPI_ERR_PENDING                     = 18
      integer, parameter :: MPI_ERR_IN_STATUS                   = 19
      integer, parameter :: MPI_ERR_ACCESS                      = 20
      integer, parameter :: MPI_ERR_AMODE                       = 21
      integer, parameter :: MPI_ERR_ASSERT                      = 22
      integer, parameter :: MPI_ERR_BAD_FILE                    = 23
      integer, parameter :: MPI_ERR_BASE                        = 24
      integer, parameter :: MPI_ERR_CONVERSION                  = 25
      integer, parameter :: MPI_ERR_DISP                        = 26
      integer, parameter :: MPI_ERR_DUP_DATAREP                 = 27
      integer, parameter :: MPI_ERR_FILE_EXISTS                 = 28
      integer, parameter :: MPI_ERR_FILE_IN_USE                 = 29
      integer, parameter :: MPI_ERR_FILE                        = 30
      integer, parameter :: MPI_ERR_INFO_KEY                    = 31
      integer, parameter :: MPI_ERR_INFO_NOKEY                  = 32
      integer, parameter :: MPI_ERR_INFO_VALUE                  = 33
      integer, parameter :: MPI_ERR_INFO                        = 34
      integer, parameter :: MPI_ERR_IO                          = 35
      integer, parameter :: MPI_ERR_KEYVAL                      = 36
      integer, parameter :: MPI_ERR_LOCKTYPE                    = 37
      integer, parameter :: MPI_ERR_NAME                        = 38
      integer, parameter :: MPI_ERR_NO_MEM                      = 39
      integer, parameter :: MPI_ERR_NOT_SAME                    = 40
      integer, parameter :: MPI_ERR_NO_SPACE                    = 41
      integer, parameter :: MPI_ERR_NO_SUCH_FILE                = 42
      integer, parameter :: MPI_ERR_PORT                        = 43
      integer, parameter :: MPI_ERR_PROC_ABORTED                = 44
      integer, parameter :: MPI_ERR_QUOTA                       = 45
      integer, parameter :: MPI_ERR_READ_ONLY                   = 46
      integer, parameter :: MPI_ERR_RMA_ATTACH                  = 47
      integer, parameter :: MPI_ERR_RMA_CONFLICT                = 48
      integer, parameter :: MPI_ERR_RMA_RANGE                   = 49
      integer, parameter :: MPI_ERR_RMA_SHARED                  = 50
      integer, parameter :: MPI_ERR_RMA_SYNC                    = 51
      integer, parameter :: MPI_ERR_RMA_FLAVOR                  = 52
      integer, parameter :: MPI_ERR_SERVICE                     = 53
      integer, parameter :: MPI_ERR_SESSION                     = 54
      integer, parameter :: MPI_ERR_SIZE                        = 55
      integer, parameter :: MPI_ERR_SPAWN                       = 56
      integer, parameter :: MPI_ERR_UNSUPPORTED_DATAREP         = 57
      integer, parameter :: MPI_ERR_UNSUPPORTED_OPERATION       = 58
      integer, parameter :: MPI_ERR_VALUE_TOO_LARGE             = 59
      integer, parameter :: MPI_ERR_WIN                         = 60
      integer, parameter :: MPI_ERR_ERRHANDLER                  = 61
      integer, parameter :: MPI_T_ERR_CANNOT_INIT               = 1000
      integer, parameter :: MPI_T_ERR_NOT_ACCESSIBLE            = 1001
      integer, parameter :: MPI_T_ERR_NOT_INITIALIZED           = 1002
      integer, parameter :: MPI_T_ERR_NOT_SUPPORTED             = 1003
      integer, parameter :: MPI_T_ERR_MEMORY                    = 1004
      integer, parameter :: MPI_T_ERR_INVALID                   = 1005
      integer, parameter :: MPI_T_ERR_INVALID_INDEX             = 1006
      integer, parameter :: MPI_T_ERR_INVALID_ITEM              = 1007
      integer, parameter :: MPI_T_ERR_INVALID_SESSION           = 1008
      integer, parameter :: MPI_T_ERR_INVALID_HANDLE            = 1009
      integer, parameter :: MPI_T_ERR_INVALID_NAME              = 1010
      integer, parameter :: MPI_T_ERR_OUT_OF_HANDLES            = 1011
      integer, parameter :: MPI_T_ERR_OUT_OF_SESSIONS           = 1012
      integer, parameter :: MPI_T_ERR_CVAR_SET_NOT_NOW          = 1013
      integer, parameter :: MPI_T_ERR_CVAR_SET_NEVER            = 1014
      integer, parameter :: MPI_T_ERR_PVAR_NO_WRITE             = 1015
      integer, parameter :: MPI_T_ERR_PVAR_NO_STARTSTOP         = 1016
      integer, parameter :: MPI_T_ERR_PVAR_NO_ATOMIC            = 1017
      integer, parameter :: MPI_ERR_LASTCODE              = int(z'3fff')

!     Buffer Address Constants
      integer :: MPI_BOTTOM
      common /MPI_BOTTOM/ MPI_BOTTOM
      save /MPI_BOTTOM/

      integer :: MPI_IN_PLACE
      common /MPI_IN_PLACE/ MPI_IN_PLACE
      save /MPI_IN_PLACE/

      integer :: MPI_BUFFER_AUTOMATIC(1)
      common /MPI_BUFFER_AUTOMATIC/ MPI_BUFFER_AUTOMATIC
      save /MPI_BUFFER_AUTOMATIC/

!     Constants Specifying Empty or Ignored Input
      character*1 :: MPI_ARGV_NULL(1)
      common /MPI_ARGV_NULL/ MPI_ARGV_NULL
      save /MPI_ARGV_NULL/

      character*1 :: MPI_ARGVS_NULL(1, 1)
      common /MPI_ARGVS_NULL/ MPI_ARGVS_NULL
      save /MPI_ARGVS_NULL/

      integer :: MPI_ERRCODES_IGNORE(1)
      common /MPI_ERRCODES_IGNORE/ MPI_ERRCODES_IGNORE
      save /MPI_ERRCODES_IGNORE/

      integer :: MPI_STATUS_IGNORE(MPI_STATUS_SIZE)
      common /MPI_STATUS_IGNORE/ MPI_STATUS_IGNORE
      save /MPI_STATUS_IGNORE/

      integer :: MPI_STATUSES_IGNORE(MPI_STATUS_SIZE, 1)
      common /MPI_STATUSES_IGNORE/ MPI_STATUSES_IGNORE
      save /MPI_STATUSES_IGNORE/

      integer :: MPI_UNWEIGHTED(1)
      common /MPI_UNWEIGHTED/ MPI_UNWEIGHTED
      save /MPI_UNWEIGHTED/

      integer :: MPI_WEIGHTS_EMPTY(1)
      common /MPI_WEIGHTS_EMPTY/ MPI_WEIGHTS_EMPTY
      save /MPI_WEIGHTS_EMPTY/

!     Other constants
      integer, parameter :: MPI_BSEND_OVERHEAD = 512

!     String size constants
      integer, parameter :: MPI_MAX_DATAREP_STRING         =  128 - 1
      integer, parameter :: MPI_MAX_ERROR_STRING           =  512 - 1
      integer, parameter :: MPI_MAX_INFO_KEY               =  256 - 1
      integer, parameter :: MPI_MAX_INFO_VAL               = 1024 - 1
      integer, parameter :: MPI_MAX_LIBRARY_VERSION_STRING = 8192 - 1
      integer, parameter :: MPI_MAX_OBJECT_NAME            =  128 - 1
      integer, parameter :: MPI_MAX_PORT_NAME              = 1024 - 1
      integer, parameter :: MPI_MAX_PROCESSOR_NAME         =  256 - 1
      integer, parameter :: MPI_MAX_STRINGTAG_LEN          = 1024 - 1
      integer, parameter :: MPI_MAX_PSET_NAME_LEN          =  512 - 1

!     Mode Constants
!     Files
      integer, parameter :: MPI_MODE_APPEND          = 1
      integer, parameter :: MPI_MODE_CREATE          = 2
      integer, parameter :: MPI_MODE_DELETE_ON_CLOSE = 4
      integer, parameter :: MPI_MODE_EXCL            = 8
      integer, parameter :: MPI_MODE_RDONLY          = 16
      integer, parameter :: MPI_MODE_RDWR            = 32
      integer, parameter :: MPI_MODE_SEQUENTIAL      = 64
      integer, parameter :: MPI_MODE_UNIQUE_OPEN     = 128
      integer, parameter :: MPI_MODE_WRONLY          = 256
!     Windows
      integer, parameter :: MPI_MODE_NOCHECK         = 1024
      integer, parameter :: MPI_MODE_NOPRECEDE       = 2048
      integer, parameter :: MPI_MODE_NOPUT           = 4096
      integer, parameter :: MPI_MODE_NOSTORE         = 8192
      integer, parameter :: MPI_MODE_NOSUCCEED       = 16384

!     rank sentinels - must be negative
      integer, parameter :: MPI_ANY_SOURCE = -1
      integer, parameter :: MPI_PROC_NULL  = -2
      integer, parameter :: MPI_ROOT       = -3

!     tag sentinels - should be negative
      integer, parameter :: MPI_ANY_TAG = -31

!     attribute constant - should be negative
      integer, parameter :: MPI_KEYVAL_INVALID = -127

!     special displacement for sequential access file - should be negative
      integer, parameter :: MPI_DISPLACEMENT_CURRENT = -255

!     multi-purpose sentinel - must be negative
      integer, parameter :: MPI_UNDEFINED = -32766


!     Environmental inquiry keys and Predefined Attribute Keys
!     Threads Constants
!     These values are monotonic; i.e., SINGLE < FUNNELED < SERIALIZED < MULTIPLE.
      integer, parameter :: MPI_THREAD_SINGLE     = 0
      integer, parameter :: MPI_THREAD_FUNNELED   = 1
      integer, parameter :: MPI_THREAD_SERIALIZED = 2
      integer, parameter :: MPI_THREAD_MULTIPLE   = 7

!     Array Datatype Order
      integer, parameter :: MPI_ORDER_C       = int(z'C')
      integer, parameter :: MPI_ORDER_FORTRAN = int(z'F')

!     Array Datatype Distribution
      integer, parameter :: MPI_DISTRIBUTE_NONE      = 16
      integer, parameter :: MPI_DISTRIBUTE_BLOCK     = 17
      integer, parameter :: MPI_DISTRIBUTE_CYCLIC    = 18
      integer, parameter :: MPI_DISTRIBUTE_DFLT_DARG = 19

!     RMA Lock Constants - arbitrary values
      integer, parameter :: MPI_LOCK_SHARED    = 21
      integer, parameter :: MPI_LOCK_EXCLUSIVE = 22

!     MPI Window Models
      integer, parameter :: MPI_WIN_UNIFIED  = 31
      integer, parameter :: MPI_WIN_SEPARATE = 32

!     MPI Window Create Flavors
      integer, parameter :: MPI_WIN_FLAVOR_ALLOCATE = 41
      integer, parameter :: MPI_WIN_FLAVOR_CREATE   = 42
      integer, parameter :: MPI_WIN_FLAVOR_DYNAMIC  = 43
      integer, parameter :: MPI_WIN_FLAVOR_SHARED   = 44

!     Results of communicator and group comparisons
      integer, parameter :: MPI_IDENT     = 101
      integer, parameter :: MPI_CONGRUENT = 102
      integer, parameter :: MPI_SIMILAR   = 103
      integer, parameter :: MPI_UNEQUAL   = 104

!     MPI_Topo_test
      integer, parameter :: MPI_GRAPH      = 201
      integer, parameter :: MPI_DIST_GRAPH = 202
      integer, parameter :: MPI_CART       = 203

!     Datatype Decoding Constants
      integer, parameter :: MPI_COMBINER_NAMED          = 301
      integer, parameter :: MPI_COMBINER_DUP            = 302
      integer, parameter :: MPI_COMBINER_CONTIGUOUS     = 303
      integer, parameter :: MPI_COMBINER_VECTOR         = 304
      integer, parameter :: MPI_COMBINER_HVECTOR        = 305
      integer, parameter :: MPI_COMBINER_INDEXED        = 306
      integer, parameter :: MPI_COMBINER_HINDEXED       = 307
      integer, parameter :: MPI_COMBINER_INDEXED_BLOCK  = 308
      integer, parameter :: MPI_COMBINER_HINDEXED_BLOCK = 309
      integer, parameter :: MPI_COMBINER_STRUCT         = 310
      integer, parameter :: MPI_COMBINER_SUBARRAY       = 311
      integer, parameter :: MPI_COMBINER_DARRAY         = 312
      integer, parameter :: MPI_COMBINER_F90_REAL       = 313
      integer, parameter :: MPI_COMBINER_F90_COMPLEX    = 314
      integer, parameter :: MPI_COMBINER_F90_INTEGER    = 315
      integer, parameter :: MPI_COMBINER_RESIZED        = 316
      integer, parameter :: MPI_COMBINER_VALUE_INDEX    = 317

!     File Position Constants
      integer, parameter :: MPI_SEEK_CUR = 601
      integer, parameter :: MPI_SEEK_END = 602
      integer, parameter :: MPI_SEEK_SET = 603

!     Fortran Datatype Matching Constants
      integer, parameter :: MPIX_TYPECLASS_LOGICAL = 801
      integer, parameter :: MPI_TYPECLASS_INTEGER  = 802
      integer, parameter :: MPI_TYPECLASS_REAL     = 803
      integer, parameter :: MPI_TYPECLASS_COMPLEX  = 804

!     Communicator split type constants - arbitrary values
      integer, parameter :: MPI_COMM_TYPE_SHARED          = 1001
      integer, parameter :: MPI_COMM_TYPE_HW_UNGUIDED     = 1002
      integer, parameter :: MPI_COMM_TYPE_HW_GUIDED       = 1003
      integer, parameter :: MPI_COMM_TYPE_RESOURCE_GUIDED = 1004

!     These apply to MPI_COMM_WORLD
      integer, parameter :: MPI_TAG_UB          = 10001
      integer, parameter :: MPI_IO              = 10002
      integer, parameter :: MPI_HOST            = 10003
      integer, parameter :: MPI_WTIME_IS_GLOBAL = 10004
      integer, parameter :: MPI_APPNUM          = 10005
      integer, parameter :: MPI_LASTUSEDCODE    = 10006
      integer, parameter :: MPI_UNIVERSE_SIZE   = 10007

!     Predefined Attribute Keys
!     These apply to Windows
      integer, parameter :: MPI_WIN_BASE          = 20001
      integer, parameter :: MPI_WIN_DISP_UNIT     = 20002
      integer, parameter :: MPI_WIN_SIZE          = 20003
      integer, parameter :: MPI_WIN_CREATE_FLAVOR = 20004
      integer, parameter :: MPI_WIN_MODEL         = 20005

! typedef int (MPI_Copy_function)(MPI_Comm, int, void *, void *, void *, int *);
! typedef int (MPI_Delete_function)(MPI_Comm, int, void *, void *);
! 
! typedef void (MPI_User_function)(void *, void *, int *, MPI_Datatype *);
! typedef void (MPI_User_function_c)(void *, void *, MPI_Count *, MPI_Datatype *);
! 
! typedef int (MPI_Grequest_cancel_function)(void *, int);
! typedef int (MPI_Grequest_free_function)(void *);
! typedef int (MPI_Grequest_query_function)(void *, MPI_Status *);
! 
! typedef int (MPI_Datarep_conversion_function)(void *, MPI_Datatype, int, void *, MPI_Offset, void *);
! typedef int (MPI_Datarep_extent_function)(MPI_Datatype datatype, MPI_Aint *, void *);
! typedef int (MPI_Datarep_conversion_function_c)(void *, MPI_Datatype, MPI_Count, void *, MPI_Offset, void *);
! 
! typedef int (MPI_Comm_copy_attr_function)(MPI_Comm, int, void *, void *, void *, int *);
! typedef int (MPI_Comm_delete_attr_function)(MPI_Comm, int, void *, void *);
! typedef int (MPI_Type_copy_attr_function)(MPI_Datatype, int, void *, void *, void *, int *);
! typedef int (MPI_Type_delete_attr_function)(MPI_Datatype, int, void *, void *);
! typedef int (MPI_Win_copy_attr_function)(MPI_Win, int, void *, void *, void *, int *);
! typedef int (MPI_Win_delete_attr_function)(MPI_Win, int, void *, void *);
! 
! typedef void (MPI_Comm_errhandler_function)(MPI_Comm *, int *, ...);
! typedef void (MPI_File_errhandler_function)(MPI_File *, int *, ...);
! typedef void (MPI_Win_errhandler_function)(MPI_Win *, int *, ...);
! typedef void (MPI_Session_errhandler_function)(MPI_Session *, int *, ...);
! 
! typedef MPI_Comm_errhandler_function MPI_Comm_errhandler_fn;
! typedef MPI_File_errhandler_function MPI_File_errhandler_fn;
! typedef MPI_Win_errhandler_function MPI_Win_errhandler_fn;
! typedef MPI_Session_errhandler_function MPI_Session_errhandler_fn;

! #define MPI_NULL_COPY_FN         ((MPI_Copy_function*)0x0)
! #define MPI_DUP_FN               ((MPI_Copy_function*)0x1)
! #define MPI_NULL_DELETE_FN       ((MPI_Delete_function*)0x0)
! #define MPI_COMM_NULL_COPY_FN    ((MPI_Comm_copy_attr_function*)0x0)
! #define MPI_COMM_DUP_FN          ((MPI_Comm_copy_attr_function*)0x1)
! #define MPI_COMM_NULL_DELETE_FN  ((MPI_Comm_delete_attr_function*)0x0)
! #define MPI_TYPE_NULL_COPY_FN    ((MPI_Type_copy_attr_function*)0x0)
! #define MPI_TYPE_DUP_FN          ((MPI_Type_copy_attr_function*)0x1)
! #define MPI_TYPE_NULL_DELETE_FN  ((MPI_Type_delete_attr_function*)0x0)
! #define MPI_WIN_NULL_COPY_FN     ((MPI_Win_copy_attr_function*)0x0)
! #define MPI_WIN_DUP_FN           ((MPI_Win_copy_attr_function*)0x1)
! #define MPI_WIN_NULL_DELETE_FN   ((MPI_Win_delete_attr_function*)0x0)
! #define MPI_CONVERSION_FN_NULL   ((MPI_Datarep_conversion_function*)0x0)
! #define MPI_CONVERSION_FN_NULL_C ((MPI_Datarep_conversion_function_c*)0x0)

! /* MPI global variables */
! extern MPI_Fint * MPI_F_STATUS_IGNORE;
! extern MPI_Fint * MPI_F_STATUSES_IGNORE;

!     MPI functions
      external MPI_Abort
      external MPI_Accumulate
      external MPI_Accumulate_c
      external MPI_Add_error_class
      external MPI_Add_error_code
      external MPI_Add_error_string
      external MPI_Allgather
      external MPI_Allgather_c
      external MPI_Allgather_init
      external MPI_Allgather_init_c
      external MPI_Allgatherv
      external MPI_Allgatherv_c
      external MPI_Allgatherv_init
      external MPI_Allgatherv_init_c
      external MPI_Alloc_mem
      external MPI_Allreduce
      external MPI_Allreduce_c
      external MPI_Allreduce_init
      external MPI_Allreduce_init_c
      external MPI_Alltoall
      external MPI_Alltoall_c
      external MPI_Alltoall_init
      external MPI_Alltoall_init_c
      external MPI_Alltoallv
      external MPI_Alltoallv_c
      external MPI_Alltoallv_init
      external MPI_Alltoallv_init_c
      external MPI_Alltoallw
      external MPI_Alltoallw_c
      external MPI_Alltoallw_init
      external MPI_Alltoallw_init_c
      external MPI_Attr_delete
      external MPI_Attr_get
      external MPI_Attr_put
      external MPI_Barrier
      external MPI_Barrier_init
      external MPI_Bcast
      external MPI_Bcast_c
      external MPI_Bcast_init
      external MPI_Bcast_init_c
      external MPI_Bsend
      external MPI_Bsend_c
      external MPI_Bsend_init
      external MPI_Bsend_init_c
      external MPI_Buffer_attach
      external MPI_Buffer_attach_c
      external MPI_Buffer_detach
      external MPI_Buffer_detach_c
      external MPI_Buffer_flush
      external MPI_Buffer_iflush
      external MPI_Cancel
      external MPI_Cart_coords
      external MPI_Cart_create
      external MPI_Cart_get
      external MPI_Cart_map
      external MPI_Cart_rank
      external MPI_Cart_shift
      external MPI_Cart_sub
      external MPI_Cartdim_get
      external MPI_Close_port
      external MPI_Comm_accept
      external MPI_Comm_attach_buffer
      external MPI_Comm_attach_buffer_c
      external MPI_Comm_call_errhandler
      external MPI_Comm_compare
      external MPI_Comm_connect
      external MPI_Comm_create
      external MPI_Comm_create_errhandler
      external MPI_Comm_create_from_group
      external MPI_Comm_create_group
      external MPI_Comm_create_keyval
      external MPI_Comm_delete_attr
      external MPI_Comm_detach_buffer
      external MPI_Comm_detach_buffer_c
      external MPI_Comm_disconnect
      external MPI_Comm_dup
      external MPI_Comm_dup_with_info
      external MPI_Comm_flush_buffer
      external MPI_Comm_free
      external MPI_Comm_free_keyval
      external MPI_Comm_get_attr
      external MPI_Comm_get_errhandler
      external MPI_Comm_get_info
      external MPI_Comm_get_name
      external MPI_Comm_get_parent
      external MPI_Comm_group
      external MPI_Comm_idup
      external MPI_Comm_idup_with_info
      external MPI_Comm_iflush_buffer
      external MPI_Comm_join
      external MPI_Comm_rank
      external MPI_Comm_remote_group
      external MPI_Comm_remote_size
      external MPI_Comm_set_attr
      external MPI_Comm_set_errhandler
      external MPI_Comm_set_info
      external MPI_Comm_set_name
      external MPI_Comm_size
      external MPI_Comm_spawn
      external MPI_Comm_spawn_multiple
      external MPI_Comm_split
      external MPI_Comm_split_type
      external MPI_Comm_test_inter
      external MPI_Compare_and_swap
      external MPI_Dims_create
      external MPI_Dist_graph_create
      external MPI_Dist_graph_create_adjacent
      external MPI_Dist_graph_neighbors
      external MPI_Dist_graph_neighbors_count
      external MPI_Errhandler_free
      external MPI_Error_class
      external MPI_Error_string
      external MPI_Exscan
      external MPI_Exscan_c
      external MPI_Exscan_init
      external MPI_Exscan_init_c
      external MPI_Fetch_and_op
      external MPI_File_call_errhandler
      external MPI_File_close
      external MPI_File_create_errhandler
      external MPI_File_delete
      external MPI_File_get_amode
      external MPI_File_get_atomicity
      external MPI_File_get_byte_offset
      external MPI_File_get_errhandler
      external MPI_File_get_group
      external MPI_File_get_info
      external MPI_File_get_position
      external MPI_File_get_position_shared
      external MPI_File_get_size
      external MPI_File_get_type_extent
      external MPI_File_get_type_extent_c
      external MPI_File_get_view
      external MPI_File_iread
      external MPI_File_iread_c
      external MPI_File_iread_all
      external MPI_File_iread_all_c
      external MPI_File_iread_at
      external MPI_File_iread_at_c
      external MPI_File_iread_at_all
      external MPI_File_iread_at_all_c
      external MPI_File_iread_shared
      external MPI_File_iread_shared_c
      external MPI_File_iwrite
      external MPI_File_iwrite_c
      external MPI_File_iwrite_all
      external MPI_File_iwrite_all_c
      external MPI_File_iwrite_at
      external MPI_File_iwrite_at_c
      external MPI_File_iwrite_at_all
      external MPI_File_iwrite_at_all_c
      external MPI_File_iwrite_shared
      external MPI_File_iwrite_shared_c
      external MPI_File_open
      external MPI_File_preallocate
      external MPI_File_read
      external MPI_File_read_c
      external MPI_File_read_all
      external MPI_File_read_all_c
      external MPI_File_read_all_begin
      external MPI_File_read_all_begin_c
      external MPI_File_read_all_end
      external MPI_File_read_at
      external MPI_File_read_at_c
      external MPI_File_read_at_all
      external MPI_File_read_at_all_c
      external MPI_File_read_at_all_begin
      external MPI_File_read_at_all_begin_c
      external MPI_File_read_at_all_end
      external MPI_File_read_ordered
      external MPI_File_read_ordered_c
      external MPI_File_read_ordered_begin
      external MPI_File_read_ordered_begin_c
      external MPI_File_read_ordered_end
      external MPI_File_read_shared
      external MPI_File_read_shared_c
      external MPI_File_seek
      external MPI_File_seek_shared
      external MPI_File_set_atomicity
      external MPI_File_set_errhandler
      external MPI_File_set_info
      external MPI_File_set_size
      external MPI_File_set_view
      external MPI_File_sync
      external MPI_File_write
      external MPI_File_write_c
      external MPI_File_write_all
      external MPI_File_write_all_c
      external MPI_File_write_all_begin
      external MPI_File_write_all_begin_c
      external MPI_File_write_all_end
      external MPI_File_write_at
      external MPI_File_write_at_c
      external MPI_File_write_at_all
      external MPI_File_write_at_all_c
      external MPI_File_write_at_all_begin
      external MPI_File_write_at_all_begin_c
      external MPI_File_write_at_all_end
      external MPI_File_write_ordered
      external MPI_File_write_ordered_c
      external MPI_File_write_ordered_begin
      external MPI_File_write_ordered_begin_c
      external MPI_File_write_ordered_end
      external MPI_File_write_shared
      external MPI_File_write_shared_c
      external MPI_Finalize
      external MPI_Finalized
      external MPI_Free_mem
      external MPI_Gather
      external MPI_Gather_c
      external MPI_Gather_init
      external MPI_Gather_init_c
      external MPI_Gatherv
      external MPI_Gatherv_c
      external MPI_Gatherv_init
      external MPI_Gatherv_init_c
      external MPI_Get
      external MPI_Get_c
      external MPI_Get_accumulate
      external MPI_Get_accumulate_c
      external MPI_Get_address
      external MPI_Get_count
      external MPI_Get_count_c
      external MPI_Get_elements
      external MPI_Get_elements_c
      external MPI_Get_elements_x
      external MPI_Get_hw_resource_info
      external MPI_Get_library_version
      external MPI_Get_processor_name
      external MPI_Get_version
      external MPI_Graph_create
      external MPI_Graph_get
      external MPI_Graph_map
      external MPI_Graph_neighbors
      external MPI_Graph_neighbors_count
      external MPI_Graphdims_get
      external MPI_Grequest_complete
      external MPI_Grequest_start
      external MPI_Group_compare
      external MPI_Group_difference
      external MPI_Group_excl
      external MPI_Group_free
      external MPI_Group_from_session_pset
      external MPI_Group_incl
      external MPI_Group_intersection
      external MPI_Group_range_excl
      external MPI_Group_range_incl
      external MPI_Group_rank
      external MPI_Group_size
      external MPI_Group_translate_ranks
      external MPI_Group_union
      external MPI_Iallgather
      external MPI_Iallgather_c
      external MPI_Iallgatherv
      external MPI_Iallgatherv_c
      external MPI_Iallreduce
      external MPI_Iallreduce_c
      external MPI_Ialltoall
      external MPI_Ialltoall_c
      external MPI_Ialltoallv
      external MPI_Ialltoallv_c
      external MPI_Ialltoallw
      external MPI_Ialltoallw_c
      external MPI_Ibarrier
      external MPI_Ibcast
      external MPI_Ibcast_c
      external MPI_Ibsend
      external MPI_Ibsend_c
      external MPI_Iexscan
      external MPI_Iexscan_c
      external MPI_Igather
      external MPI_Igather_c
      external MPI_Igatherv
      external MPI_Igatherv_c
      external MPI_Improbe
      external MPI_Imrecv
      external MPI_Imrecv_c
      external MPI_Ineighbor_allgather
      external MPI_Ineighbor_allgather_c
      external MPI_Ineighbor_allgatherv
      external MPI_Ineighbor_allgatherv_c
      external MPI_Ineighbor_alltoall
      external MPI_Ineighbor_alltoall_c
      external MPI_Ineighbor_alltoallv
      external MPI_Ineighbor_alltoallv_c
      external MPI_Ineighbor_alltoallw
      external MPI_Ineighbor_alltoallw_c
      external MPI_Info_create
      external MPI_Info_create_env
      external MPI_Info_delete
      external MPI_Info_dup
      external MPI_Info_free
      external MPI_Info_get
      external MPI_Info_get_nkeys
      external MPI_Info_get_nthkey
      external MPI_Info_get_string
      external MPI_Info_get_valuelen
      external MPI_Info_set
      external MPI_Init
      external MPI_Init_thread
      external MPI_Initialized
      external MPI_Intercomm_create
      external MPI_Intercomm_create_from_groups
      external MPI_Intercomm_merge
      external MPI_Iprobe
      external MPI_Irecv
      external MPI_Irecv_c
      external MPI_Ireduce
      external MPI_Ireduce_c
      external MPI_Ireduce_scatter
      external MPI_Ireduce_scatter_c
      external MPI_Ireduce_scatter_block
      external MPI_Ireduce_scatter_block_c
      external MPI_Irsend
      external MPI_Irsend_c
      external MPI_Is_thread_main
      external MPI_Iscan
      external MPI_Iscan_c
      external MPI_Iscatter
      external MPI_Iscatter_c
      external MPI_Iscatterv
      external MPI_Iscatterv_c
      external MPI_Isend
      external MPI_Isend_c
      external MPI_Isendrecv
      external MPI_Isendrecv_c
      external MPI_Isendrecv_replace
      external MPI_Isendrecv_replace_c
      external MPI_Issend
      external MPI_Issend_c
      external MPI_Keyval_create
      external MPI_Keyval_free
      external MPI_Lookup_name
      external MPI_Mprobe
      external MPI_Mrecv
      external MPI_Mrecv_c
      external MPI_Neighbor_allgather
      external MPI_Neighbor_allgather_c
      external MPI_Neighbor_allgather_init
      external MPI_Neighbor_allgather_init_c
      external MPI_Neighbor_allgatherv
      external MPI_Neighbor_allgatherv_c
      external MPI_Neighbor_allgatherv_init
      external MPI_Neighbor_allgatherv_init_c
      external MPI_Neighbor_alltoall
      external MPI_Neighbor_alltoall_c
      external MPI_Neighbor_alltoall_init
      external MPI_Neighbor_alltoall_init_c
      external MPI_Neighbor_alltoallv
      external MPI_Neighbor_alltoallv_c
      external MPI_Neighbor_alltoallv_init
      external MPI_Neighbor_alltoallv_init_c
      external MPI_Neighbor_alltoallw
      external MPI_Neighbor_alltoallw_c
      external MPI_Neighbor_alltoallw_init
      external MPI_Neighbor_alltoallw_init_c
      external MPI_Op_commutative
      external MPI_Op_create
      external MPI_Op_create_c
      external MPI_Op_free
      external MPI_Open_port
      external MPI_Pack
      external MPI_Pack_c
      external MPI_Pack_external
      external MPI_Pack_external_c
      external MPI_Pack_external_size
      external MPI_Pack_external_size_c
      external MPI_Pack_size
      external MPI_Pack_size_c
      external MPI_Parrived
      external MPI_Pcontrol
      external MPI_Pready
      external MPI_Pready_list
      external MPI_Pready_range
      external MPI_Precv_init
      external MPI_Probe
      external MPI_Psend_init
      external MPI_Publish_name
      external MPI_Put
      external MPI_Put_c
      external MPI_Query_thread
      external MPI_Raccumulate
      external MPI_Raccumulate_c
      external MPI_Recv
      external MPI_Recv_c
      external MPI_Recv_init
      external MPI_Recv_init_c
      external MPI_Reduce
      external MPI_Reduce_c
      external MPI_Reduce_init
      external MPI_Reduce_init_c
      external MPI_Reduce_local
      external MPI_Reduce_local_c
      external MPI_Reduce_scatter
      external MPI_Reduce_scatter_c
      external MPI_Reduce_scatter_block
      external MPI_Reduce_scatter_block_c
      external MPI_Reduce_scatter_block_init
      external MPI_Reduce_scatter_block_init_c
      external MPI_Reduce_scatter_init
      external MPI_Reduce_scatter_init_c
      external MPI_Register_datarep
      external MPI_Register_datarep_c
      external MPI_Remove_error_class
      external MPI_Remove_error_code
      external MPI_Remove_error_string
      external MPI_Request_free
      external MPI_Request_get_status
      external MPI_Request_get_status_all
      external MPI_Request_get_status_any
      external MPI_Request_get_status_some
      external MPI_Rget
      external MPI_Rget_c
      external MPI_Rget_accumulate
      external MPI_Rget_accumulate_c
      external MPI_Rput
      external MPI_Rput_c
      external MPI_Rsend
      external MPI_Rsend_c
      external MPI_Rsend_init
      external MPI_Rsend_init_c
      external MPI_Scan
      external MPI_Scan_c
      external MPI_Scan_init
      external MPI_Scan_init_c
      external MPI_Scatter
      external MPI_Scatter_c
      external MPI_Scatter_init
      external MPI_Scatter_init_c
      external MPI_Scatterv
      external MPI_Scatterv_c
      external MPI_Scatterv_init
      external MPI_Scatterv_init_c
      external MPI_Send
      external MPI_Send_c
      external MPI_Send_init
      external MPI_Send_init_c
      external MPI_Sendrecv
      external MPI_Sendrecv_c
      external MPI_Sendrecv_replace
      external MPI_Sendrecv_replace_c
      external MPI_Session_attach_buffer
      external MPI_Session_attach_buffer_c
      external MPI_Session_call_errhandler
      external MPI_Session_create_errhandler
      external MPI_Session_detach_buffer
      external MPI_Session_detach_buffer_c
      external MPI_Session_finalize
      external MPI_Session_flush_buffer
      external MPI_Session_get_errhandler
      external MPI_Session_get_info
      external MPI_Session_get_nth_pset
      external MPI_Session_get_num_psets
      external MPI_Session_get_pset_info
      external MPI_Session_iflush_buffer
      external MPI_Session_init
      external MPI_Session_set_errhandler
      external MPI_Ssend
      external MPI_Ssend_c
      external MPI_Ssend_init
      external MPI_Ssend_init_c
      external MPI_Start
      external MPI_Startall
      external MPI_Status_get_error
      external MPI_Status_get_source
      external MPI_Status_get_tag
      external MPI_Status_set_cancelled
      external MPI_Status_set_elements
      external MPI_Status_set_elements_c
      external MPI_Status_set_elements_x
      external MPI_Status_set_error
      external MPI_Status_set_source
      external MPI_Status_set_tag
      external MPI_Test
      external MPI_Test_cancelled
      external MPI_Testall
      external MPI_Testany
      external MPI_Testsome
      external MPI_Topo_test
      external MPI_Type_commit
      external MPI_Type_contiguous
      external MPI_Type_contiguous_c
      external MPI_Type_create_darray
      external MPI_Type_create_darray_c
      external MPI_Type_create_f90_complex
      external MPI_Type_create_f90_integer
      external MPI_Type_create_f90_real
      external MPI_Type_create_hindexed
      external MPI_Type_create_hindexed_c
      external MPI_Type_create_hindexed_block
      external MPI_Type_create_hindexed_block_c
      external MPI_Type_create_hvector
      external MPI_Type_create_hvector_c
      external MPI_Type_create_indexed_block
      external MPI_Type_create_indexed_block_c
      external MPI_Type_create_keyval
      external MPI_Type_create_resized
      external MPI_Type_create_resized_c
      external MPI_Type_create_struct
      external MPI_Type_create_struct_c
      external MPI_Type_create_subarray
      external MPI_Type_create_subarray_c
      external MPI_Type_delete_attr
      external MPI_Type_dup
      external MPI_Type_free
      external MPI_Type_free_keyval
      external MPI_Type_get_attr
      external MPI_Type_get_contents
      external MPI_Type_get_contents_c
      external MPI_Type_get_envelope
      external MPI_Type_get_envelope_c
      external MPI_Type_get_extent
      external MPI_Type_get_extent_c
      external MPI_Type_get_extent_x
      external MPI_Type_get_name
      external MPI_Type_get_true_extent
      external MPI_Type_get_true_extent_c
      external MPI_Type_get_true_extent_x
      external MPI_Type_get_value_index
      external MPI_Type_indexed
      external MPI_Type_indexed_c
      external MPI_Type_match_size
      external MPI_Type_set_attr
      external MPI_Type_set_name
      external MPI_Type_size
      external MPI_Type_size_c
      external MPI_Type_size_x
      external MPI_Type_vector
      external MPI_Type_vector_c
      external MPI_Unpack
      external MPI_Unpack_c
      external MPI_Unpack_external
      external MPI_Unpack_external_c
      external MPI_Unpublish_name
      external MPI_Wait
      external MPI_Waitall
      external MPI_Waitany
      external MPI_Waitsome
      external MPI_Win_allocate
      external MPI_Win_allocate_c
      external MPI_Win_allocate_shared
      external MPI_Win_allocate_shared_c
      external MPI_Win_attach
      external MPI_Win_call_errhandler
      external MPI_Win_complete
      external MPI_Win_create
      external MPI_Win_create_c
      external MPI_Win_create_dynamic
      external MPI_Win_create_errhandler
      external MPI_Win_create_keyval
      external MPI_Win_delete_attr
      external MPI_Win_detach
      external MPI_Win_fence
      external MPI_Win_flush
      external MPI_Win_flush_all
      external MPI_Win_flush_local
      external MPI_Win_flush_local_all
      external MPI_Win_free
      external MPI_Win_free_keyval
      external MPI_Win_get_attr
      external MPI_Win_get_errhandler
      external MPI_Win_get_group
      external MPI_Win_get_info
      external MPI_Win_get_name
      external MPI_Win_lock
      external MPI_Win_lock_all
      external MPI_Win_post
      external MPI_Win_set_attr
      external MPI_Win_set_errhandler
      external MPI_Win_set_info
      external MPI_Win_set_name
      external MPI_Win_shared_query
      external MPI_Win_shared_query_c
      external MPI_Win_start
      external MPI_Win_sync
      external MPI_Win_test
      external MPI_Win_unlock
      external MPI_Win_unlock_all
      external MPI_Win_wait

      integer(MPI_ADDRESS_KIND), external :: MPI_Aint_add
      integer(MPI_ADDRESS_KIND), external :: MPI_Aint_diff
      double precision, external :: MPI_Wtick
      double precision, external :: MPI_Wtime
