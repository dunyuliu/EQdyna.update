!/* Copyright (C) 2006-2020, Earthquake Modeling Lab @ Texas A&M University. 
! * All Rights Reserved.
! * This code is part of software EQdyna, please see EQdyna License Agreement
! * attached before you copy, download, install or use EQdyna./

PROGRAM EQdyna_3D

	use globalvar
	implicit none
	include 'mpif.h'
		
	integer (kind=4) :: i, j, k, l, itmp, alloc_err, ierr

	call MPI_Init(ierr)
	call mpi_comm_rank(MPI_COMM_WORLD,me,ierr)
	call mpi_comm_size(MPI_COMM_WORLD,nprocs,ierr)

	if (me == master) then 
		write(*,*) '====================================================================='
		write(*,*) '================== Welcome to EQdyna 3D 5.2.3 ======================='
		write(*,*) '===== Product of Earthquake Modeling Lab @ Texas A&M University ====='
		write(*,*) '========== Website https://seismotamu.wixsite.com/emlam ============='
		write(*,*) '=========== Contacts: dunyuliu@tamu.edu, bduan@tamu.edu ============='
		write(*,*) '=                                                                   ='
		write(*,*) '=   EQdyna 3D uses FEM to simulate earthquake dynamic ruptures      ='
		write(*,*) '=   on geometrically realistic fault systems.                       ='
		write(*,*) '=                                                                   ='
		write(*,*) '=   Model and system related parameters can be adjusted in          ='
		write(*,*) '=       FE_Global.txt,                                              ='
		write(*,*) '=       FE_Model_Geometry.txt,                                      ='
		write(*,*) '=       FE_Fault_Geometry.txt,                                      ='
		write(*,*) '=       FE_Material.txt,                                            ='
		write(*,*) '=       FE_Fric.txt,                                                ='		
		write(*,*) '=       FE_Stations.txt,                                            ='
		write(*,*) '=                                                                   ='
		write(*,*) '====================================================================='	
	endif 
	
	timebegin=MPI_WTIME()
	time1=MPI_WTIME()	

	write(mm,'(i6)') me
	mm=trim(adjustl(mm))
	
	call readglobal
	call readmodelgeometry
	allocate(fxmin(ntotft),fxmax(ntotft),fymin(ntotft),fymax(ntotft),fzmin(ntotft),fzmax(ntotft),material(nmat,n2mat))
	allocate(nonfs(ntotft))
	
	allocate(fltxyz(2,4,ntotft))
	call readfaultgeometry
	call readmaterial
	!call readfric
	call readstations1
	itmp = maxval(nonfs)

	allocate(an4nds(2,n4nds), xonfs(2,itmp,ntotft), x4nds(3,n4nds))
	call readstations2
	
	if (rough_fault == 1) call read_fault_rough_geometry

	call warning
	
	nplpts=0	!initialize number of time history plot
	if (nhplt>0) then
		nplpts=int(nstep/nhplt)+2
	endif

	allocate(nftnd(ntotft),shl(nrowsh,nen))
	
	call qdcshl

	call mesh4num
	
	allocate(id1(maxm),locid(numnp),dof1(numnp),x(ndof,numnp), fnms(numnp), surface_node_id(numnp), stat=alloc_err) 

	allocate(ien(nen,numel), mat(numel,5), et(numel), eleporep(numel), pstrain(numel), &
				eledet(numel), elemass(nee,numel), eleshp(nrowsh-1,nen,numel), &
				ss(6,numel), phi(nen,4,numel), stat=alloc_err)

	eleporep = 0.0d0
	pstrain  = 0.0d0
	eledet   = 0.0d0
	elemass  = 0.0d0

	nftmx=maxval(nftnd) !max fault nodel num for all faults, used for arrays.
	if(nftmx<=0) nftmx=1  !fortran arrays cannot be zero size,use 1 for 0
	nonmx=sum(nonfs)    !max possible on-fault stations number
	
	allocate(nsmp(2,nftmx,ntotft), fnft(nftmx,ntotft), un(3,nftmx,ntotft),&
				us(3,nftmx,ntotft), ud(3,nftmx,ntotft), fric(100,nftmx,ntotft),&
				arn(nftmx,ntotft), r4nuc(nftmx,ntotft), anonfs(3,nonmx),&
				arn4m(nftmx,ntotft), state(nftmx,ntotft), fltgm(nftmx),&
				Tatnode(nftmx,ntotft), patnode(nftmx,ntotft))
		
	!INITIATION 	
	fltgm   = 0  
	nsmp    = 0    
	fnft    = 1000.0d0 
	fric    = 0.0d0
	un      = 0.0d0
	us      = 1000.0d0
	ud      = 0.0d0
	arn     = 0.0d0
	arn4m   = 0.0d0
	r4nuc   = 0.0d0
	anonfs  = 0
	state   = 0.0d0
	Tatnode = 0.0d0 
	patnode = 0.0d0

	allocate(ids(numel))
	allocate(s1(5*maxm))
	s1=0.0d0
	
	call memory_estimate
	
	call meshgen
	
	call netcdf_read_on_fault_eqdyna("on_fault_vars_input.nc")
	
	if (output_ground_motion == 1) call find_surface_node_id
	
    if (C_degen == 1) then 
        do i = 1, numnp
           if (x(2,i)>dx/2.0d0) then 
                x(1,i) = x(1,i) - dx/2.0d0
           endif
           if (x(2,i)<-dx/2.0d0) then 
                x(1,i) = x(1,i) + dx/2.0d0
           endif 
        enddo 
     endif
	
	if (me == master) then 
		write(*,*) '=                                                                   ='
		write(*,*) '=                        Mesh generated                             ='
		write(*,*) '=                                                                   ='
		write(*,*) '= Interior model boundary                                           ='
		write(*,*) '= xmax',PMLb(1),'xmin',PMLb(2),'ymax',PMLb(3),'ymin',PMLb(4),'zmin',PMLb(5)
		write(*,*) '= Max element size',PMLb(6),PMLb(7),PMLb(8)
		write(*,*) '= Model boundary                                           ='
		write(*,*) '= xmax',xmax1,'xmin',xmin1,'ymax',ymax1,'ymin',ymin1,'zmin',zmin1		
	endif
	
	if(n4onf<=0) n4onf=1 
	allocate(fltsta(12,nplpts-1,n4onf),stat=alloc_err)
	fltsta = 0.0d0

	allocate(brhs(neq),v1(neq),d1(neq), alhs(neq), v(ndof,numnp),d(ndof,numnp),stat=alloc_err)

	brhs    = 0.0d0
	alhs    = 0.0d0
	v1      = 0.0d0
	d1      = 0.0d0
	v       = 0.0d0
	d       = 0.0d0

	allocate(frichis(2,nftmx,nplpts,ntotft))
	frichis = 0.0d0

	if(n4out>0) then 
		ndout=n4out*ndof*noid!3 components of 2 quantities: v and d
		!   write(*,*) 'ndout= ',ndout    
		allocate(idhist(3,ndout),dout(ndout+1,nplpts),stat=alloc_err)
		if(alloc_err /=0) then
			write(*,*) 'me= ',me,'insufficient space to allocate array idhist or dout'
		endif

		idhist=0
		dout=0.0d0
		l=0
		do i=1,n4out
			do j=1,ndof
				do k=1,noid
					l = l + 1
					idhist(1,l) = an4nds(2,i) !node number (>1, <NUMNP)
					if(idhist(1,l)<=0) idhist(1,l)=1  !avoid zero that cannot be in array below
					idhist(2,l) = j	!degree of freedom number (<=NDOF)
					idhist(3,l) = k	!kinematic quantity specifier 
					!(disp, vel, or acc)
				enddo
			enddo
		enddo			
	endif
	
	time2=MPI_WTIME()		
	timeused(1)=time2-time1

	call driver
	
	if (me == master) then 
		write(*,*) '=                                                                   ='
		write(*,*) '=                      Writing out results                          ='
		write(*,*) '====================================================================='	
	endif
	
	time1=MPI_WTIME()
	
	if (output_ground_motion == 0) then 
		call output_onfault_st
	
		call output_offfault_st
	endif
	
	call output_frt

	time2=MPI_WTIME()
	timeused(8)=time2-time1 
	timeover=MPI_WTIME()
	timeused(9)=timeover-timebegin 
	
	if (timeinfo == 1) call output_timeanalysis
	if (output_plastic == 1) call output_plastic_strain
	
	call MPI_Finalize(ierr)
	stop
	
end PROGRAM EQdyna_3D
