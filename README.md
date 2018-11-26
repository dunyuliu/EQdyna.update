# EQdyna

A parallel Finite Element software to model earthquake spontaneous dynamic ruptures. The software is designed to use high-performance computing. It is written in FORTRAN 90 and MPI.

### Dunyu Liu, 10/04/2016, dunyuliu@gmail.com
# Version 4.1.1
## Features
* Significant simplification of the system.
* Reduction in variable declarations.
* Moving all controllable parameters into globalvar.f90.
* This version is tested against SCEC TPV8.

### Dunyu Liu, Bin Luo, 09/29/2016, dunyuliu@gmail.com 
# Version 4.0
## Features
* 3D MPI (Bin Luo) incorporated with Version 3.2.1 by Dunyu Liu.
* Further simplification.
* More controllable parameters in globalvar.f90.
* This version is verified against SCEC TPV 8.
* EOS retired and batch file written for ADA. 

### Dunyu Liu, 09/19/2015, dunyuliu@gmail.com
# Version 3.2.1
## Features
* Coarse-grained Q model is implemented (Ma and Liu, 2006; Day, 1998).
* Elastic and plastic models are combined. 
* qconstant.f90 is added.
* Controllable parameters are moved to globalvar.f90 and switched to change mechanicms are added.
* The code is validated against the model with PML and Q model in Ma and Liu (2006) and is later used in the Tianjin Scenario Earthquake project (Duan et al., 2017; Liu and Duan, 2018).

### Dunyu Liu, 09/2015, dunyuliu@gmail.com
# Version 3.1.2
## Patch update
* Double-couple point source is implemented based on Ma and Liu (2006)

### Dunyu Liu, 09/2015, dunyuliu@gmail.com
# Version 3.1.1
## Features
* Implementation of the Perfectly Matched Layer (Ma and Liu, 2006)
* Major update to use 1D array to store nodal forces, and kinematic quantities. It is designed to solve the different dimensions of regular and PML elements. It involves many files that pass such quantities. 
* Element type is introduced to sperate regular and PML elements.
* 2 F90 files are added and 13 are modified. 
* Both viscous and KF78 hourglass controls are implemented.
* Makefile updated to include the 2 new files. 
* This version is verified against SCEC TPV29&30. 

### Benchun Duan, 09/12/2014, bduan@tamu.edu
# Version 3.1
## Features
* Finite Element Method (FEM) is based on Duan (2010)
* Traction-at-split Node (TSN) technique in faulting.f90 to simulate earthquake faults (Day et al., 2005)
* Drucker-Prager plastic yielding (Ma and Andrews, 2010).
* MPI/OpenMP hybrid parallelization (Wu et al., 2011)
* The code is verified in SCEC benchmark problems 
  TPV18-21 (scecdata.usc.edu/cvws/) and used in Jingqian Kang's PhD project - low velocity fault zone response to nearby earthquake. 

## Model description
* Material properties, initial stresses, friction, and plasticity (c = 0 Mpa case) of Ma and Andrews (2010) are used.
* Revised to taper stress drop at two lateral edges of the fault by following the scheme for tapering stresses at top and bottom parts as they proposed, to gradually stop rupture.
* The fault dimension is x=[-16.1 km, 16.1 km] and 
  z=[-15.1 km, 0], with element size of 100 m.
