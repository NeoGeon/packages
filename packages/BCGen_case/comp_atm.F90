module comp_atm
use mct_mod
use time_mod
use global_var
use proc_def
use ESMF
!use global_var
    implicit none
    integer  :: comp_id
    !---------------------------------------------------------
    ! notice that the fields of a2x and x2a maybe different
    ! but here we just assume they are same
    !---------------------------------------------------------
    integer,parameter :: CXX=4096
    character(CXX) :: fld_ar='r:r1'
    character(CXX) :: fld_ai='i:i1'
    character(*),parameter :: model_name='atm'

    public :: atm_init_mct
    !public :: atm_run_mct
    !public :: atm_final_mct

contains

!-------------------------------------------------------------------------
!  a_init_mct, init gsmap_aa, avect, avect init with zero, but not init
!  dom at present
!-------------------------------------------------------------------------
subroutine atm_init_mct(EClock, &
    atm2x_atmatm, x2atm_atmatm, ierr)

    implicit none
    !type(compMeta), target, intent(inout)  :: compInfo
    type(ESMF_Clock), intent(in)          :: EClock
    type(AttrVect), intent(inout)    :: atm2x_atmatm
    type(AttrVect), intent(inout)    :: x2atm_atmatm
    integer,        intent(inout)    :: ierr
    integer                :: ID
    type(gsMap)   :: gsMap_atmatm   
    type(gGrid)    :: domain
    integer ::local_comm,i

    ! control signal
    logical :: first_time = .true. ! if the first time to run or restart

    ! domain parameter
    integer ::ngy,ngx   !global points in x-dir and y-dir
    integer ::nlseg   !num of local segs
    integer ::nproc     !num of pes
    integer ::llseg     !length of each local segs


  
    integer, allocatable  :: start(:)
    integer, allocatable  :: length(:)
    integer               :: root = 0 !root of local communicator
    integer               :: comm_rank
    integer               :: comm_size
    integer               :: lsize,gsize

    !--- formats ---
    integer               :: logunit
    character(*), parameter :: F00   = "('(atm_init_mct) ',8a)"
    character(*), parameter :: F01   = "('(atm_init_mct) ',a,4i8)"
    character(*), parameter :: F02   = "('(atm_init_mct) ',a,4es13.6)"
    character(*), parameter :: F03   = "('(atm_init_mct) ',a,i8,a)"
    character(*), parameter :: F90   = "('(atm_init_mct ',73('='))"
    character(*), parameter :: F91   = "('(atm_init_mct) ',73('-'))"
    character(*), parameter :: subName = "(atm_init_mct) "

    !call compMeta_getInfo(compInfo, ID=ID, domain=domain, &
    !                      gsize =  gsize, comm=local_comm)

    !gsmap_atmatm=> compInfo%comp_gsmap
    local_comm = MPI_COMM_WORLD
    call mpi_comm_rank(local_comm, comm_rank, ierr)
    call mpi_comm_size(local_comm, comm_size, ierr)
!---
!   init model domain parameter todo init this parameter y xml file
!---
    ngx = 10
    ngy = 10
    nlseg = 1
    nproc = comm_size
! todo bcast this parameter

   
!---
!   log model info todo logo this info to log file
!---
    logunit = 0
    if (comm_rank == root) then
       write(logunit,*  ) ' Read in Xatm input from file= xatm_in'
       write(logunit,F00)
       write(logunit,F00) '         Model  :  ',trim(model_name)
       write(logunit,F01) '           NGX  :  ',ngx
       write(logunit,F01) '           NGY  :  ',ngy
       write(logunit,F01) ' Decomposition  :  ',0
       write(logunit,F03) ' Num pes in X   :  ',nproc
       write(logunit,F03) ' Num of local Segment :  ',nlseg
       write(logunit,F01) '    inst_index  :  ',10
       write(logunit,F00)
    end if

!---
! Init Time Manager todo time set and corresponding logics
!---



!---
! Init MCT grid todo
!---
    allocate(start(nlseg))
    allocate(length(nlseg))

    lsize = gsize / nproc
    llseg = lsize / nlseg

    do i=1,nlseg
      start(i) = (comm_rank * lsize) + (i-1) * llseg
      length(i) = llseg
    end do
!---
! Init MCT Global seg map
!---
  call gsMap_init(gsmap_atmatm, start, length, root, local_comm, ID)
!---
! Init MCT Domain todo(now is use constant number to init domain data),
!---
  call atm_domain_init(local_comm, gsmap_atmatm, domain)
!----
!Init Attrvect
!----
  ! Init Field list
  !call seq_flds_add(fld_ar, 'Sa_z')
  !call seq_flds_add(fld_ar, 'Sa_u')
  !call seq_flds_add(fld_ar, 'Sa_v')
  !call seq_flds_add(fld_ar, 'Sa_tbot')
  !call seq_flds_add(fld_ar, 'Sa_ptem')
  !call seq_flds_add(fld_ar, 'Sa_shum')
  !call seq_flds_add(fld_ar, 'Sa_dens')
  !call seq_flds_add(fld_ar, 'Sa_ptem')

  call avect_init(atm2x_atmatm, iList=fld_ai, rList=fld_ar, lsize=lsize)
  call avect_init(x2atm_atmatm, iList=fld_ai, rList=fld_ar, lsize=lsize)
 
  call avect_zero(atm2x_atmatm)
  call avect_zero(x2atm_atmatm) 

end subroutine atm_init_mct


!--- todo

subroutine atm_domain_init(mpicomm, gsMap_atmatm, domain)

  integer    , intent(in)   :: mpicomm
  type(gsMap), intent(in)   :: gsMap_atmatm
  type(gGrid), intent(inout)             :: domain

  !---local variables---
  real(8)    , pointer  :: data(:)     ! temporary
  integer , pointer  :: idata(:)    ! temporary
  integer ::ierr,lsize

  call gGrid_init(GGrid=domain, &
      CoordChars=trim('x:y:z'), &
      otherchars=trim('lat:lon:area:frac:mask:aream'),&
      lsize=gsMap_lsize(gsMap_atmatm, mpicomm))
  call avect_zero(domain%data)

  lsize=gsMap_lsize(gsMap_atmatm, mpicomm)

  allocate(data(lsize))
  allocate(idata(lsize))
  data(:) = -9999.0  ! generic special value 	
  call gGrid_importRAttr(domain,"lat" ,data,lsize) 
  call gGrid_importRAttr(domain,"lon" ,data,lsize) 
  call gGrid_importRAttr(domain,"area",data,lsize) 
  call gGrid_importRAttr(domain,"frac",data,lsize) 

  data(:) = 0.0  ! generic special value 	
  call gGrid_importRAttr(domain,"mask" ,data,lsize) 
  call gGrid_importRAttr(domain,"aream",data,lsize) 
  deallocate(data)
  deallocate(idata)


end subroutine

end module comp_atm
