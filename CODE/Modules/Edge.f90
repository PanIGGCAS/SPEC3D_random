module sedges

! Modified by Gaetano Festa 23/02/2005
! Modified by Paul Cupillard 06/11/2005

type :: edge

logical :: PML, Abs, FPML

integer :: ngll
integer, dimension (:), pointer :: Iglobnum_Edge

real, dimension (:), pointer  :: MassMat
real, dimension (:,:), pointer :: Forces, Displ, Veloc, Accel, V0
real, dimension (:,:), pointer :: DumpMass, DumpVx, DumpVy, DumpVz
real, dimension (:,:), pointer :: Veloc1, Veloc2, Veloc3
real, dimension (:,:), pointer :: Forces1, Forces2, Forces3

real, dimension (:,:), pointer :: IVeloc1, Iveloc2, Iveloc3
real, dimension (:), pointer :: Ivx, Ivy, Ivz
!!$real,dimension(:,:),allocatable::D0
end type

contains

! ############################################################
subroutine Prediction_Edge_Veloc (E, alpha, bega, gam1, dt)
implicit none

type (Edge), intent (INOUT) :: E
real, intent (IN) :: alpha, bega, gam1, dt

integer :: ngll

ngll = E%ngll

E%Forces(:,:) = E%Displ(:,:) + dt * E%Veloc(:,:) + dt**2 * (0.5 - bega) * E%Accel(:,:)
E%V0(:,:) = E%Veloc(:,:)
E%Forces(:,:) = alpha * E%Forces(:,:) + (1-alpha) * E%Displ(:,:)
!!$if (allocated(E%D0)) E%D0(:,:)=E%Displ(:,:)
return
end subroutine Prediction_Edge_Veloc

! ###########################################################
subroutine Correction_Edge_Veloc (E, bega, gam1, dt,ne)
implicit none

type (Edge), intent (INOUT) :: E
real, intent (IN) :: bega, gam1, dt
integer, intent (IN) :: ne

integer :: i, ngll, j

ngll = E%ngll
do i = 0,2
  do j=1,ngll-2
    E%Forces(j,i) = E%MassMat(j) * E%Forces(j,i)
  enddo
enddo

E%Veloc(:,:) = E%v0(:,:) + dt * E%Forces(:,:)
E%Accel(:,:) = E%Accel(:,:) + gam1 / dt * (E%Veloc(:,:)-E%V0(:,:))
E%Displ(:,:) = E%Displ(:,:) + bega * dt * (E%Veloc(:,:)+E%V0(:,:))


return
end subroutine Correction_Edge_Veloc

! ############################################################
subroutine Correction_Edge_PML_Veloc (E, dt)

implicit none

type (Edge), intent (INOUT) :: E
real, intent (IN) :: dt

integer :: i

do i = 0,2
    E%Veloc1(:,i) = E%DumpVx(:,0) * E%Veloc1(:,i) + dt * E%DumpVx(:,1) * E%Forces1(:,i)
    E%Veloc2(:,i) = E%DumpVy(:,0) * E%Veloc2(:,i) + dt * E%DumpVy(:,1) * E%Forces2(:,i)
    E%Veloc3(:,i) = E%DumpVz(:,0) * E%Veloc3(:,i) + dt * E%DumpVz(:,1) * E%Forces3(:,i)
enddo

E%Veloc = E%Veloc1 + E%Veloc2 + E%Veloc3

if (E%Abs) then
    E%Veloc = 0
endif

return
end subroutine Correction_Edge_PML_Veloc



! ############################################
subroutine Correction_Edge_FPML_Veloc (E, dt,fil)

implicit none

type (Edge), intent (INOUT) :: E
real, intent (IN) :: dt,fil

integer :: i
real :: fil2
real, dimension (1:E%ngll-1) :: Ausiliar_velocity

do i = 0,2
    Ausiliar_velocity = E%Veloc1(:,i)
    E%Veloc1(:,i) = E%DumpVx(:,0) * E%Veloc1(:,i) + dt * E%DumpVx(:,1) * E%Forces1(:,i) + E%Ivx * E%Iveloc1(:,i)
    E%Iveloc1(:,i) = Fil2 * E%Iveloc1(:,i) + 0.5 * (1-Fil2) *  (Ausiliar_velocity + E%Veloc1(:,i))

    Ausiliar_velocity = E%Veloc2(:,i)
    E%Veloc2(:,i) = E%DumpVy(:,0) * E%Veloc2(:,i) + dt * E%DumpVy(:,1) * E%Forces2(:,i) + E%Ivy * E%Iveloc2(:,i)
    E%Iveloc2(:,i) = Fil2 * E%Iveloc2(:,i) + 0.5 * (1-Fil2) *  (Ausiliar_velocity + E%Veloc2(:,i))

    Ausiliar_velocity = E%Veloc3(:,i)
    E%Veloc3(:,i) = E%DumpVz(:,0) * E%Veloc3(:,i) + dt * E%DumpVz(:,1) * E%Forces3(:,i) + E%Ivz * E%Iveloc3(:,i)
    E%Iveloc3(:,i) = Fil2 * E%Iveloc3(:,i) + 0.5 * (1-Fil2) *  (Ausiliar_velocity + E%Veloc3(:,i))
enddo

E%Veloc = E%Veloc1 + E%Veloc2 + E%Veloc3

if (E%Abs) then
    E%Veloc = 0
endif

return
end subroutine Correction_Edge_FPML_Veloc
! ############################################

subroutine get_vel_edge (E, Vfree, ngll, dt, logic, orient)
implicit none

integer, intent (IN) :: ngll, orient
real, intent (IN) :: dt
type (Edge), intent (IN) :: E
real, dimension (1:ngll-2,0:2), intent (INOUT) :: Vfree
logical, intent (IN) :: logic 

integer :: i,j

if (logic) then
   if ( orient ==0 ) then
     do i = 0,2
        Vfree(1:ngll-2,i) = Vfree(1:ngll-2,i) - ( E%V0(1:ngll-2,i) + dt*E%MassMat(1:ngll-2)*E%Forces(1:ngll-2,i) )
     enddo
   else
     do i = 0,2
       do j = 1, ngll-2
	  Vfree(j,i) = Vfree(j,i) - ( E%V0(ngll-1-j,i) + dt*E%MassMat(ngll-1-j)*E%Forces(ngll-1-j,i) )
       enddo
     enddo
   endif
else
   do i = 0,2
        Vfree(1:ngll-2,i) =  E%V0(1:ngll-2,i) + dt*E%MassMat(1:ngll-2)*E%Forces(1:ngll-2,i)
   enddo
endif
return
end subroutine get_vel_edge

! ############################################################

end module sedges
