
! License-Identifier: GPL
!
! Copyright (C) 2012 The Yambo Team
!
! Authors (see AUTHORS file for details): AM
!
subroutine OCCUPATIONS_Gaps(E,E_g_dir,E_g_ind,Nbf,Nbm,I_dir,E_k_dir,E_k_ind)
 !
 use pars,          ONLY:SP
 use electrons,     ONLY:levels,n_sp_pol,filled_tresh,spin_occ
 !
 implicit none
 !
 type(levels)       ::E
 real(SP), optional ::E_g_dir(1+(n_sp_pol-1)*2,2) ! min gap - max gap 
 real(SP), optional ::E_g_ind(1+(n_sp_pol-1)*2,3) ! min - val. band width - cond. band width
 integer , optional ::Nbf(2)
 integer , optional ::Nbm(2)
 integer , optional ::I_dir(2)
 integer , optional ::E_k_dir(1+(n_sp_pol-1)*2)
 integer , optional ::E_k_ind(n_sp_pol,2)
 ! 
 ! Work Space
 ! 
 integer :: ib,ik,i_sp_pol,j_sp_pol,i_sp_ref,j_sp_ref
 !
 real(SP):: E_g_dir_old
 real(SP):: E_vb_min(n_sp_pol),E_vb_max(n_sp_pol)
 real(SP):: E_cb_min(n_sp_pol),E_cb_max(n_sp_pol)
 real(SP):: r_nk
 real(SP), parameter ::tresh=epsilon(1._SP)
 ! 
 ! Shadow variables 
 ! 
 real(SP) ::E_g_dir_(1+(n_sp_pol-1)*2,2)
 real(SP) ::E_g_ind_(1+(n_sp_pol-1)*2,3) 
 integer  ::Nbf_(2),I_dir_(2),Nbm_(2)
 integer  ::E_k_dir_(1+(n_sp_pol-1)*2),E_k_ind_(n_sp_pol,2)
 !
 if(sum(E%f(:,:,:))<1._SP-filled_tresh) call error('The system contains less than 1 electron')
 !
 ! Initialization
 !
 E_g_dir_=0
 E_g_ind_=0
 E_k_dir_=0
 E_k_ind_=0
 Nbm_=0
 Nbf_=0
 !
 ! Evaluate Metallic/Filled bands
 !
 do i_sp_pol=1,n_sp_pol
   do ib=1,E%nb
     !
     ! A single state (n k) weights 2 only when there is no spin components 
     !
     r_nk=sum(E%f(ib,:,i_sp_pol))/spin_occ/real(E%nk,SP)
     !
     if (r_nk<=tresh) cycle
     if (abs(r_nk-1._SP)<=filled_tresh) then
       Nbf_(i_sp_pol)=ib
       cycle
     endif
     Nbm_(i_sp_pol)=ib
   enddo
   if (Nbm_(i_sp_pol)==0) Nbm_(i_sp_pol)=Nbf_(i_sp_pol)
 enddo
 !
 if (n_sp_pol==1) then
   Nbf_(2)=Nbf_(1)
   Nbm_(2)=Nbm_(1)
 endif
 !
 E%nbf=Nbf_
 E%nbm=Nbm_
#if defined _RT
 if(all(E%nbc/=0)) then
   do i_sp_pol=1,n_sp_pol
     E%nbf(i_sp_pol)=min(E%nbc(1)-1,E%nbf(i_sp_pol))
     E%nbm(i_sp_pol)=max(E%nbc(2)  ,E%nbm(i_sp_pol))
   enddo
 endif
#endif
 !
 if (any(E%Nbm+1 > E%nb)) call warning(' No completely empy band found. Include more states in the DFT run?')
 !
 ! VBM/CBM
 !
 E_vb_min=-100._SP
 E_vb_max=-100._SP
 E_cb_min=0._SP
 E_cb_max=0._SP
 do i_sp_pol=1,n_sp_pol
   if(Nbf_(i_sp_pol)>0) then
     E_vb_min(i_sp_pol)  =minval(E%E(Nbf_(i_sp_pol),:,i_sp_pol))
     E_vb_max(i_sp_pol)  =maxval(E%E(Nbf_(i_sp_pol),:,i_sp_pol))
     E_k_ind_(i_sp_pol,1)=maxloc(E%E(Nbf_(i_sp_pol),:,i_sp_pol), DIM=1)
   endif
   E_cb_min(i_sp_pol)  =minval(E%E(Nbf_(i_sp_pol)+1,:,i_sp_pol))
   E_k_ind_(i_sp_pol,2)=minloc(E%E(Nbf_(i_sp_pol)+1,:,i_sp_pol), DIM=1)
   E_cb_max(i_sp_pol)  =maxval(E%E(Nbf_(i_sp_pol)+1,:,i_sp_pol))
 enddo
 !
 E%E_VBM(:n_sp_pol)=E_vb_max
 E%E_CBm(:n_sp_pol)=E_cb_min
 !
 ! [1] Indirect Gaps (min/max)
 !
 E_g_ind_(1,1)=minval(E_cb_min)-maxval(E_vb_max)
 E_g_ind_(1,2)=minval(E_vb_max)-maxval(E_vb_min)
 E_g_ind_(1,3)=minval(E_cb_max)-maxval(E_cb_min)
 ! This should never happen
 if(E_g_ind_(1,1)<0.and.n_sp_pol==2) call warning('Merged spin levels are metallic')
 !
 if(n_sp_pol==2.and.any(Nbf_==Nbm_)) then
   do i_sp_pol=1,n_sp_pol
     !
     if (Nbf_(i_sp_pol)/=Nbm_(i_sp_pol)) cycle
     E_g_ind_(i_sp_pol+1,1)=E_cb_min(i_sp_pol)-E_vb_max(i_sp_pol)
     E_g_ind_(i_sp_pol+1,2)=E_vb_max(i_sp_pol)-E_vb_min(i_sp_pol)
     E_g_ind_(i_sp_pol+1,3)=E_cb_max(i_sp_pol)-E_cb_min(i_sp_pol)
     !
   enddo
 endif
 !
 if(n_sp_pol==1) E%E_ind_gap(1)  =E_g_ind_(1,1)
 if(n_sp_pol==2) E%E_ind_gap(1:2)=E_g_ind_(2:3,1)
 ! 
 ! [2] Direct Gaps (min/max)
 !
 if (all(Nbf_==Nbm_)) then
   E_g_dir_(1,:)=(/100._SP,-100._SP/)
   i_sp_ref=1
   j_sp_ref=1
   do ik=1,E%nk
     do i_sp_pol=1,n_sp_pol
       do j_sp_pol=1,n_sp_pol
         if(Nbf_(j_sp_pol)==0) cycle
         E_g_dir_old=E_g_dir_(1,1)
         E_g_dir_(1,1)=min(E_g_dir_(1,1),&
&                      E%E(Nbf_(i_sp_pol)+1,ik,i_sp_pol)-E%E(Nbf_(j_sp_pol),ik,j_sp_pol) )
         if(E_g_dir_(1,1)<E_g_dir_old) then
           i_sp_ref=i_sp_pol
           j_sp_ref=j_sp_pol
           I_dir_=(/Nbf_(i_sp_pol),ik/)
           E_k_dir_(i_sp_pol)=ik
         endif
       enddo
     enddo
     E_g_dir_(1,2)=max(E_g_dir_(1,2),E%E(Nbf_(i_sp_ref)+1,ik,i_sp_ref)-E%E(Nbf_(j_sp_ref),ik,j_sp_ref) )
   enddo
 endif
 !
 if (n_sp_pol==2.and.any(Nbf_==Nbm_)) then
   do i_sp_pol=1,n_sp_pol
     !
     if (Nbf_(i_sp_pol)/=Nbm_(i_sp_pol)) cycle
     if (Nbf_(i_sp_pol)==0) cycle
     !
     E_g_dir_(i_sp_pol+1,:)=(/100._SP,-100._SP/)
     do ik=1,E%nk
       if(E%E(Nbf_(i_sp_pol)+1,ik,i_sp_pol)-E%E(Nbf_(i_sp_pol),ik,i_sp_pol)<E_g_dir_(i_sp_pol+1,1)) then
          E_g_dir_(i_sp_pol+1,1)= E%E(Nbf_(i_sp_pol)+1,ik,i_sp_pol)-E%E(Nbf_(i_sp_pol),ik,i_sp_pol) 
          E_k_dir_(i_sp_pol+1)  = ik
       endif
       E_g_dir_(i_sp_pol+1,2)=max(E_g_dir_(i_sp_pol+1,2),&
&                      E%E(Nbf_(i_sp_pol)+1,ik,i_sp_pol)-E%E(Nbf_(i_sp_pol),ik,i_sp_pol) )
     enddo
     !
   enddo
 endif
 !
 ! If the system is metallic VBM and CBm are set to zero, i.e. equal to the Fermi level
 ! so that stretching corrections are applied properly
 !
 do i_sp_pol=1,n_sp_pol
   if(Nbf_(i_sp_pol)/=Nbm_(i_sp_pol)) then
     E%E_VBM(i_sp_pol)=E%E_Fermi
     E%E_CBm(i_sp_pol)=E%E_Fermi
   endif
 enddo
 !
 if (n_sp_pol==1) E%E_dir_gap(1)  =E_g_dir_(1,1)
 if (n_sp_pol==2) E%E_dir_gap(1:2)=E_g_dir_(2:3,1)
 !
 ! From Shadow variables to optional variables
 !
 if (present(I_dir))   I_dir=I_dir_
 if (present(E_k_dir)) E_k_dir=E_k_dir_
 if (present(E_k_ind)) E_k_ind=E_k_ind_
 if (present(E_g_dir)) E_g_dir=E_g_dir_
 if (present(E_g_ind)) E_g_ind=E_g_ind_
 if (present(Nbf))     Nbf=Nbf_
 if (present(Nbm))     Nbm=Nbm_
 !
end subroutine
