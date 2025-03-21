!
! License-Identifier: GPL
!
! Copyright (C) 2010 The Yambo Team
!
! Authors (see AUTHORS file for details): AM
!
subroutine SC_add_XC(X,Xw,Xk,E,k,q,iteration,V_xc_nm1,ELEC,HOLE,DELTA)
 !
 ! The definition of the XC part is the same in the two approches. The only
 ! difference is that in _XC the operator is written in the SC basis, while
 ! _RT works in the LDa basis.
 !
 use pars,           ONLY:SP,cZERO,cI
 use drivers,        ONLY:l_sc_exx,l_sc_srpa,l_sc_coh,l_sc_sex,l_sc_is_libDFT,&
&                         l_use_Hxc_collisions,l_sc_fock,l_use_COH_collisions
 use R_lattice,      ONLY:bz_samp
 use QP_m,           ONLY:QP_t,QP_reset
 use parallel_m,     ONLY:master_cpu
 use electrons,      ONLY:levels,n_spin,spin_occ
 use frequency,      ONLY:w_samp
 use X_m,            ONLY:X_t
 use xc_functionals, ONLY:V_xc,XC_potential_driver
 use hamiltonian,    ONLY:l_sc_V_is_local,l_sc_XC_is_local,V_xc_sc,H_rotation,&
&                         H_rotation_ref,E_reference
 use SC,             ONLY:SC_kind,SC_xc_functional,SC_cycle_mixing,SC_nbands,       &
&                         SC_bands,l_oep_iterative,SC_neq_kind,SC_last_coh_it,SC_mu
 use FFT_m,          ONLY:fft_size
 use IO_int,         ONLY:IO_and_Messaging_switch
 !
 implicit none
 !
 type(levels) ::E
 type(bz_samp)::k,q,Xk
 type(X_t)    ::X(2)  ! Xx Em1s
 type(w_samp) ::Xw(2)
 !
 integer      ::iteration
 real(SP)     ::V_xc_nm1(fft_size,n_spin)
 !
 ! Work Space
 !
 integer      :: ib,ibp,ik
 complex(SP)  :: G_sex(SC_bands(1):SC_bands(2),SC_bands(1):SC_bands(2),E%nk)
 complex(SP)  :: G_coh(SC_bands(1):SC_bands(2),SC_bands(1):SC_bands(2),E%nk)
 complex(SP)  :: G_tmp(SC_bands(1):SC_bands(2),SC_bands(1):SC_bands(2))
 !
 ! tests for excitons
 !
 real(SP)                 :: ELEC,HOLE,DELTA
 !
 type(QP_t)   :: qp_dummy
 !
 ! Fock/SEX/Hartree + COH
 !=======================
 !
 if (l_use_Hxc_collisions.or.l_use_COH_collisions) then
   !
   G_sex=cZERO
   forall(ib=SC_bands(1):SC_bands(2),ik=1:E%nk) G_sex(ib,ib,ik)=cI*E%f(ib,ik,1)
   G_coh=cZERO
   forall(ib=SC_bands(1):SC_bands(2),ik=1:E%nk) G_coh(ib,ib,ik)=cI
   !
   ! Now I build the G_collisions rotating the non interaction one
   ! G_collisions(ib,ib,ik)=(0.,1)*en%f(ib,ik)
   !
   do ik=1,E%nk
     call OBS_rotate(H_rotation(:,:,ik,1),G_sex(:,:,ik),SC_nbands,-1)
     call OBS_rotate(H_rotation(:,:,ik,1),G_coh(:,:,ik),SC_nbands,-1)
   enddo
   !
   if (trim(SC_neq_kind)=="matsubara") then
     !
     ELEC=0._SP
     HOLE=0._SP
     DELTA=0._SP
     do ik=1,E%nk
       !
       ! Compute number of electrons and holes
       !
       G_tmp=G_sex(:,:,ik)
       call OBS_rotate(H_rotation_ref(:,:,ik,1),G_tmp,SC_nbands,1)
       do ib=SC_bands(1),SC_bands(2)
         if(E_reference%E(ib,ik,1)> SC_mu(1)) ELEC=ELEC          -real(cI*G_tmp(ib,ib),SP) *Xk%weights(ik)
         if(E_reference%E(ib,ik,1)<=SC_mu(1)) HOLE=HOLE+(spin_occ+real(cI*G_tmp(ib,ib),SP))*Xk%weights(ik)
         do ibp=SC_bands(1),SC_bands(2)
           if( .not.( E_reference%E(ib,ik,1)>SC_mu(1) .and. E_reference%E(ibp,ik,1)<=SC_mu(1) ) ) cycle
           DELTA=DELTA-G_tmp(ib,ibp)**2*Xk%weights(ik)
         enddo
       enddo
       !
       ! Impose starting off diagonal elements
       !
       if(iteration>SC_last_coh_it) cycle
       do ib=SC_bands(1),SC_bands(2)
         do ibp=SC_bands(1),SC_bands(2)
           if( .not.( E_reference%E(ib,ik,1)>SC_mu(1) .and. E_reference%E(ibp,ik,1)<=SC_mu(1) ) ) cycle
           G_sex(ib,ibp,ik) = cI*real(ib*ibp,SP)*0.2
           G_sex(ibp,ib,ik) = cI*real(ib*ibp,SP)*0.2
         enddo
       enddo
     enddo
     !
   endif
   !
   call COLLISIONS_compose_sc(G_sex,G_coh)
   !
 else
   !
   if (.not.l_sc_V_is_local) then
     !
     call QP_reset(qp_dummy)
     !
     ! Stop all messagging
     !
     call IO_and_Messaging_switch("-report -io_in -io_out")
     !
     if (l_sc_sex.or.l_sc_fock) call XCo_driver(E,k,k,q)
     !
     call IO_and_Messaging_switch("+io_in")
     !
     if (l_sc_sex.or.l_sc_coh)  call QP_ppa_cohsex(X(2),Xk,E,k,q,qp_dummy,Xw(2),(/0._SP,0._SP/),-1)
     !
     call IO_and_Messaging_switch("+report +io_out",CONDITION=master_cpu)
     !
   else if (l_sc_XC_is_local) then
     !
     if (.not.l_oep_iterative) V_xc_sc=0._SP
     !
     ! OEP's
     !=======
     !
     if (l_sc_exx.or.l_sc_srpa) call OEP_driver(X,Xw(2),E,k,q,V_xc_sc)
     !
     ! DFT-like 
     !==========
     !
     if (l_sc_is_libDFT) call XC_potential_driver(E,Xk,SC_kind,SC_xc_functional,1)
     !
     if (l_sc_is_libDFT.and..not.(l_sc_exx.or.l_sc_srpa)) V_xc_sc(:,:)=V_xc(:,:)
     if (l_sc_is_libDFT.and.     (l_sc_exx.or.l_sc_srpa)) V_xc_sc(:,:)=V_xc(:,:)+V_xc_sc(:,:)
     !
     ! Mixing 
     !========
     !
     ! WARNING:
     ! The mixing of the potential has been eliminated for HF and COHSEX, for
     ! V_xc_sc case tests are needed.
     ! 
     if (iteration>1.and..not.(l_sc_exx.or.l_sc_srpa)) V_xc_sc = SC_cycle_mixing*V_xc_sc + (1._SP-SC_cycle_mixing)*V_xc_nm1
     !
     V_xc_nm1=V_xc_sc
     !
   endif
   !
 endif
 !
end subroutine SC_add_XC
