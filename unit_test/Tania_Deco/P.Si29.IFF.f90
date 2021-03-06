! Code to calculate analytical T matriics for hahn sequence
! using only pair correlation
!  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
! Inputs: 
!         1) choose time size Deltat (in microseconds) in line 78 ie we evolve for npulse* Deltat
!     so if your decay lasts 1 second and npulse=100 you want Delta=10000.
!     maybe relocate Deltat to P.Si.h if you prefer.
!   2) number of realisations - enter 2256 for 48X47 file
 
!&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

	IMPLICIT NONE      
        integer  ::ll,kk,it,ii,jj,ireal,NPAIR,itime,ib,NREAL,ipair
        integer:: isite,jsite,icount,ncouple,i1,i2,i3
        integer::ibath,index1,index2,id,iup
        integer::ncluster,NBM,NTOT,NZ,NT
        double precision::time,OT2,OTOT,BMAG,temp,temp1,T2
! analytics
     double precision::XJA,XJB,CB1,CB2,C12,POLD,POLUP,Sigma4
! assume NCS> or =NB (dim of CS bigger or eq to Bath)

! parameter file 
        integer:: NCS,NB,NRED,NDIM,ibfree,nsite
        integer::npulse,NMAX,iEPR1,iEPR2
! hf constants of central and bth spins
        double precision::ACS,AB,AC,AB0
! fields
        double precision:: B0,BX,OMX,FB
        double precision::xs,xi,xsb,xib
        double precision::Cmus,Cmun,Bmus,Bmun

        include 'P.SI.h'
        double precision:: PI,PI2
! time propagation
        double precision::DELTAT,test,TT2,T2TOT

        
! configurations for central spin and 1 bath spin
         INTEGER, DIMENSION(NRED):: ICS

      double precision, dimension(nsite,nsite)::CHYP
      double precision, dimension(nsite)::CSHF

! Cluster data and spin labels
 

   integer, dimension(50000):: NUMREAL
 
! Decoherence
         double complex::TRACEBATH
           double complex::TRACEB(npulse)
     double precision, dimension(NMAX,npulse):: TILDL

     double precision, dimension(npulse+1):: DECAY,DECAYav
     double precision, dimension(50000,npulse+1):: DROP
 
!&&&&&&&&&&&&&&&&&&& April 2014
! this is set up for phosphorus now
! state 4 has m=+1; state 3 m=0; state 2 m=-1; state 1 m=0
! | 1/2 1/2>=4; | 1/2 -1/2>=3; | -1/2 -1/2>=2; |-1/2 1/2>=1;
! But check the numbering above!
!&&&&&&&&&&&&&&&&&&
     POLUP=1.d0
     POLD=-1.d0
       DECAYav=0.d0

! set time step in microseconds. About 2000 at OWP
! since the decays are very long. About 4.d0 far 
! from OWP. Note that Hahn fails at OWP- ifyou want OWP use the
! FID code.
!              DELTAT=10000.d0
!               DELTAT=4.d0
      write(6,*)'time step deltat in mu s? use ~10000 if 1 s decay; 4. if 0.4ms'
        read(5,*) deltat
      write(6,*) 'number of realisations <20 '
      !read(5,*) NREAL
      read(5,*) NPAIR
      NREAL=1
!&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

! Zero arrays
                TILDL=0.d0
     
            
 	       pi=dacos(-1.d0)
               pi2=2.d0*pi 
               ACS=AC*pi2

!************************
      OPEN(11,file='couplings.dat',status='unknown')
      OPEN(8,file='DECAY.dat',status='unknown')
      OPEN(10,file='DECAYav.dat',status='unknown')
      OPEN(12,file='T2.dat',status='unknown')
!******************************************************************
      NTOT=NRED*NB**nsite
     write(6,*)NTOT,NTOT
! Read in data on the clusters
   
!  Call ReadClusters(NREAL,NUMREAL,SHFHOLD,HYPHOLD)
 
! loop over realisations
    do ireal=1,NREAL
 
! Zero trace arrays
                TILDL=0.d0
  
! Loop over pairs
!       NPAIR=NUMREAL(ireal)

!     read(11,*)NPAIR
      write(6,*)NPAIR,ireal
!      ncluster=2 
       DO ipair=1,NPAIR
!       DO ipair=1,1
!      write(6,*)'realization=',ipair
! Load up the cluster coupling of the Si29s
! there are 2 Si29 bath spins with equal J= XJB
! the "qubit" Si 29 has J=XJA
! there are 3 dipolar couplings: C12 between bath spins;
! CB1,CB2 are between the A qubit Si29 and the other two 

     read(11,*)C12,CB1,CB2,XJA,XJB
     write(6,*)ipair,C12,CB1,CB2,XJA,XJB
! add hyperfine mediated correction of Yao sham Liu PRB 74 2006
! = J1J2/4 sigma_e  where sigma e is Zeeman energy of electron 9 GHz*2pi
     Sigma4=9.7d9*2*pi
!     C12=C12+XJB*XJB/sigma4
!     CB1=CB1+XJB*XJA/sigma4
!     CB2=CB2+XJB*XJA/sigma4
!     C12=abs(C12)+XJ1*XJ2/sigma4
!&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
! Scale C12 and XJ2 by 1.e-6 because Roland uses Herz units
! code is written in Mrads
     C12=1.d-6*C12
     CB1=1.d-6*CB1
     CB2=1.d-6*CB2
     XJA=1.d-6*XJA
     XJB=1.d-6*XJB
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
100 format(2I5,D14.6)

  Call DIAGONALISER(NTOT,NT,NBM,C12,CB1,CB2,POLD,POLUP,DELTAT,TRACEB,OT2)
     
!**********************************************************
! propagate each realisation in time: 
!**************************************************************
! average the XL(ibath,itime) over the initial ibath states
! and store the results in tildeL   
   do itime=1,npulse
! average over bath states...up up/dd L=1
       TILDL(ipair,itime)=0.5+0.5d0*(TRACEB(itime))
!       TILDL(ipair,itime)=abs(TRACEB(itime))
!       TILDL(ipair,itime)=(TRACEB(itime))
   enddo

! finish loop over pairs
    enddo

     write(6,102)BMAG,POLD,POLUP
!     write(10,102)BMAG,test/abs(POLD-POLUP),POLD,POLUP
102 format(6D14.6)

      
 

!*************************************************************
! finally combine all clusters- multiply all |L(t)| together
!*************************************************************
         call DECOHERE(NPAIR,NUMREAL,TILDL,DECAY)
       time=0.d0
!        write(8,*)time,TEMP,BMAG
!        DROP(ib,1)=TEMP
       do itime=1,npulse
       time=(itime)*DeltaT*1.d-3
       DROP(ib,itime)=DECAY(itime)
       DECAYav(itime)=DECAYav(itime)+DECAY(itime)/NReal
! print out total decay
       write(8,*)2*time,DECAY(itime)
!
       enddo


! END LOOP OVER REALIZATIONS
        enddo
! write averaged decay
           do itime=1,npulse
       time=(itime)*DeltaT*1.d-3
! double the time because Hahn is for 2*Tau
!   TEMP=0.25+0.35*DECAYav(itime)+0.25*DECAYav(itime)**2+0.15*DECAYav(itime)**3
!                  write(10,*)2*time,TEMP
              write(10,*)2*time,abs(DECAYav(itime))
       !write(10,*)time,abs(DECAYav(itime))
        enddo

        stop
        end




   Subroutine DIAGONALISER(NTOT,NT,NBM,C12,CB1,CB2,POLD,POLUP,DELTAT,TRACE,OT2)
	IMPLICIT NONE
           integer::itime,NBM
 
! parameter file 
        integer:: NCS,NB,NRED,NDIM,ibfree,nsite
        integer::npulse,NMAX
! hf constants of central and bth spins
        double precision::ACS,AB,AC,AB0
! fields
        double precision:: B0,BX,OMX,FB
        double precision::xs,xi,xsb,xib
        double precision::Cmus,Cmun,Bmus,Bmun
        double precision:: DELTAT,PI,DIF
        include 'P.SI.h'
     integer::NTOT,NT,ii,jj,icn,index

       DOUBLE precision::PH,CB1,CB2,C12,HOLDM,ANORM,test
  
       DOUBLE PRECISION::phiup,phid
       DOUBLE precision:: COEF1,COEF2,TIME,POLD,POLUP,OT2,TEM,TEM1,TEM2,TEM3
 
        double precision::ENEUP,ENED,EPSUP,EPSD
  
         double complex ::PHASE,DPP,DMM,RPP,RMM,DPP2,DMM2,RPP2,RMM2,RSM,RSP
          DOUBLE COMPLEX:: TRACE(npulse)
       DOUBLE COMPLEX, DIMENSION(2,2)::HOLD,UMATU,UMATL,ROTU,ROTL,ROTRU,ROTRL
       DOUBLE COMPLEX, DIMENSION(2,2)::ZGU,ZGL,HOLD1,ZGUL,ZGLU
 
       PI=dacos(-1.d0)
 
       TRACE=CMPLX(0.d0,0.d0)

       ROTU=CMPLX(0.d0,0.d0)
       ROTL=CMPLX(0.d0,0.d0)
       ROTRU=CMPLX(0.d0,0.d0)
       ROTRL=CMPLX(0.d0,0.d0)
       HOLD=CMPLX(0.d0,0.d0)
       HOLD1=CMPLX(0.d0,0.d0)
       ZGU=CMPLX(0.d0,0.d0)
       ZGL=CMPLX(0.d0,0.d0)

      PHASE=CMPLX(0.d0,0.d0)
 
! &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

!&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
        DIF=CB1-CB2

        HOLDM=DIF*POLUP
        ENEUP=HOLDM
        EPSUP=sqrt(HOLDM**2+C12**2)
        HOLDM=DIF*POLD
        ENED=HOLDM
        EPSD=sqrt(HOLDM**2+C12**2)
!        write(6,*)index,EPS(index)
! work out the pseudo spin angles
         phiup=atan(abs(c12)/abs(ENEUP))
         phid=atan(abs(c12)/abs(ENED))
         if(ENEUP.lt.0.d0)phiup=pi-phiup
         if(ENED.lt.0.d0)phid=pi-phid
         phiup=phiup/2
         phid=phid/2

! upper state : rotation matrices
         ROTU(1,1)=CMPLX(cos(phiup),0.d0)
         ROTU(1,2)=CMPLX(sin(phiup),0.d0)
         ROTU(2,1)=CMPLX(-sin(phiup),0.d0)
         ROTU(2,2)=ROTU(1,1)
         ROTRU(1,1)=ROTU(1,1)
         ROTRU(2,2)=ROTU(2,2)
         ROTRU(1,2)=-ROTU(1,2)
         ROTRU(2,1)=-ROTU(2,1)
!    lower state: rotation matrices
         ROTL(1,1)=CMPLX(cos(phid),0.d0)
         ROTL(1,2)=CMPLX(sin(phid),0.d0)
         ROTL(2,1)=CMPLX(-sin(phid),0.d0)
         ROTL(2,2)=ROTL(1,1)
         ROTRL(1,1)=ROTL(1,1)
         ROTRL(2,2)=ROTL(2,2)
         ROTRL(1,2)=-ROTL(1,2)
         ROTRL(2,1)=-ROTL(2,1)

        do jj=1,npulse

        ZGU=CMPLX(0.d0,0.d0)
        ZGL=CMPLX(0.d0,0.d0)
        ZGUL=CMPLX(0.d0,0.d0)
        ZGLU=CMPLX(0.d0,0.d0)
        UMATU=CMPLX(0.d0,0.d0)
        UMATL=CMPLX(0.d0,0.d0)

        TIME=jj*deltat
!        TIME=10000.
! Zgates
   
! sum Z gate
         phase=CMPLX(0.d0,EPSUP*TIME/4.)
         ZGUL(1,1)=EXP(-PHASE)
         !phase=CMPLX(0.d0,(EPSD+EPSUP)*TIME/4.)
         ZGUL(2,2)=EXP(PHASE)
         !phase=CMPLX(0.d0,-(EPSUP-EPSD)*TIME/4.)
         !ZGUL(1,2)=EXP(PHASE)*sin(phiup-phid)
         !phase=CMPLX(0.d0,(EPSUP-EPSD)*TIME/4.)
         !ZGUL(2,1)=-EXP(PHASE)*sin(phiup-phid)
! sum Z gate
         phase=CMPLX(0.d0,EPSD*TIME/4.)
         ZGLU(1,1)=EXP(-PHASE)
         !phase=CMPLX(0.d0,(EPSD+EPSUP)*TIME/4.)
         ZGLU(2,2)=EXP(PHASE)

         !phase=CMPLX(0.d0,-(EPSUP-EPSD)*TIME/4.)
         !ZGLU(1,2)=-EXP(-PHASE)*sin(phiup-phid)
         !phase=CMPLX(0.d0,(EPSUP-EPSD)*TIME/4.)
         !ZGLU(2,1)=EXP(-PHASE)*sin(phiup-phid)
       
! work out transition matrices for FID
         HOLD=CMPLX(0.d0,0.d0)
!work out TUL
         HOLD=MATMUL(ZGUL,ROTL)
         UMATU=MATMUL(ROTRU,HOLD)
 
!work out TLU
         HOLD=MATMUL(ZGLU,ROTU)
         UMATL=MATMUL(ROTRL,HOLD)
     
      TRACE(jj)=UMATU(1,1)*CONJG(UMATL(1,1))-UMATU(2,1)*(UMATL(1,2))
     TRACE(jj)=abs(TRACE(jj))
        enddo

102  format(I3,4D16.8)
100  format(6D14.6)
!**************************************************

      RETURN
      END

 
!**************************************************************
!***************************************************
 Subroutine Readclusters(NREAL,NUMREAL,SHFHOLD,HYPHOLD)
   IMPLICIT NONE
   integer:: ii,ll,jj,nn,ipair,isite,jsite,ncluster
   integer::ispin1,ispin2,ncount,ncouple,index,NPAIR,ireal,NREAL
! parameter file 
        integer:: NCS,NB,NRED,NDIM,ibfree,nsite
        integer::npulse,NMAX,iEPR1,iEPR2
! hf constants of central and bth spins
        double precision::ACS,AB,AC,AB0
! fields
        double precision:: B0,BX,OMX,FB,XX
        double precision::xs,xi,xsb,xib
        double precision::Cmus,Cmun,Bmus,Bmun
        include 'P.SI.h'

   integer, dimension(20):: NUMREAL
   double precision:: HYPHOLD(3000,8000)
   double precision:: SHFHOLD(3000,8000)

     NUMREAL=0
     ncluster=2
  
                  do ireal=1,NREAL

   
     do jj=1,NMax 
    SHFHOLD(jj,ireal)=0.d0
    HYPHOLD(jj,ireal)=0.d0
     enddo
    
  Open(7,file='Roland.coupling.dat',status='unknown')
   read(7,*) NPAIR

  NUMREAL(ireal)=NPAIR
        write(6,*)NPAIR,NREAL
        DO ipair=1,NPAIR
      read(7,*)XX,HYPHOLD(ipair,ireal),SHFHOLD(ipair,ireal),XX
    
        ENDDO

                       enddo
        RETURN
        END

!***********************************************
! combine results to work out decay in time   
   SUBROUTINE DECOHERE(NPAIR,NUMREAL,TILDL,DECAY)
   IMPLICIT NONE

! parameter file 
        integer:: NCS,NB,NRED,NDIM,ibfree,nsite
        integer::npulse,NMAX,iEPR1,iEPR2
! hf constants of central and bth spins
        double precision::ACS,AB,AC,AB0
! fields
        double precision:: B0,BX,OMX,FB
        double precision::xs,xi,xsb,xib
        double precision::Cmus,Cmun,Bmus,Bmun
        include 'P.SI.h'
      integer:: NT,NTOT,NBM,ii,jj,icn,itime
       integer::ipair,NPAIR,ncluster
        integer, dimension(nsite):: NUMREAL 
          double precision::TEMP
          double precision, dimension(NMAX,npulse):: TILDL
         double precision, dimension(npulse):: DECAY
       DECAY=0.d0       
       
       do itime=1,npulse
       TEMP=1.d0
       do ipair=1,NPAIR
       TEMP=TEMP*TILDL(ipair,itime)
       enddo
       DECAY(itime)=TEMP
       enddo
       RETURN
       END
 
 
