
	    program test
	    implicit none 
#include "looptools.h" 
		ComplexType ltb0c, ltb0, lte0i, lte0ic
		RealType lta0i
	    ! call ltini 
!	    a0(m2)
		!print*, lta0i(1, 0.1d0)
	    !print*, ltb0c((1D0,0d0), (0.1D0, 0.1d0), (0.1D0,0d0)) 
		!print*, ltb0(1D0, 0.1d0, 0.1d0) 
		print*, lte0i(1, 20.64d0, 0.0196d0, 0.0196d0, 0.0196d0, 9d0, 
     +  12.25d0, 0.09d0, 0.09d0, 10.89d0, 0.25d0, 
     +  6d0, 4d0, 4d0, 1d0, 1d0)
	! 	print*, lte0ic(1, (20.64d0,0d0), (0.0196d0,0d0), 
    !  +  (0.0196d0,0d0), (0.0196d0,0d0), (9d0,0d0), (12.25d0,0d0), 
    !  +  (0.09d0,0d0), (0.09d0,0d0), (10.89d0,0d0), (0.25d0,0d0), 
    !  +  (6d0,-0.1d0), (4d0,0d0), (4d0,0d0), (1d0,0d0), (1d0,0d0))
	    ! call ltexi 
	    end


!=======1-point functions========
		! a0ic not defined
		RealType function lta0i(id, m)
	    implicit none
#include "looptools.h" 
		RealType m
		integer id
	    call ltini
			lta0i = a0i(id, m)
			! if not commented out there will be summary of warning/error even if everything is fine
	    ! call ltexi 
		end
		
		ComplexType function lta0ic(id, m)
	    implicit none
#include "looptools.h" 
		ComplexType m
		integer id
	    call ltini
	    lta0ic = a0i(id, m)
	    ! call ltexi
		end

        RealType function lta0(m)
	    implicit none
#include "looptools.h" 
	    RealType m
	    call ltini
	    lta0 = A0(m)
	    ! call ltexi
	    end
		
	    ComplexType function lta0c(m)
	    implicit none
#include "looptools.h" 
	    ComplexType m
	    call ltini
	    lta0c = A0c(m)
	    ! call ltexi
		end
		
!=======2-point functions========
	    ComplexType function ltb0(p, m1, m2)
	    implicit none
#include "looptools.h" 
	    RealType p, m1, m2
	    ! ComplexType B0
	    call ltini
	    ltb0 = B0(p, m1, m2)
	    ! call ltexi
		end

	    ComplexType function ltb0c(p, m1, m2)
	    implicit none
#include "looptools.h" 
        ! RealType p
	    ComplexType p, m1, m2
	    call ltini
	    ltb0c = B0c(p, m1, m2)
	    ! call ltexi
		end

		ComplexType function ltb0i(id, p, m1, m2)
	    implicit none
#include "looptools.h" 
		RealType p, m1, m2
		integer id
	    call ltini
	    ltb0i = b0i(id, p, m1, m2)
	    ! call ltexi
	    end

		ComplexType function ltb0ic(id, p, m1, m2)
	    implicit none
#include "looptools.h" 
		ComplexType p, m1, m2
		integer id
	    call ltini
	    ltb0ic = b0ic(id, p, m1, m2)
	    ! call ltexi
	    end
		
!=======3-point functions========
	    ComplexType function ltc0(p1, p2, p3, m1, m2, m3)
	    implicit none
#include "looptools.h" 
        RealType p1, p2, p3, m1, m2, m3
	    call ltini
	    ltc0 = c0(p1, p2, p3, m1, m2, m3)
	    ! call ltexi
		end
		
	    ComplexType function ltc0c(p1, p2, p3, m1, m2, m3)
	    implicit none
#include "looptools.h" 
        RealType p1, p2, p3
	    ComplexType m1, m2, m3
	    call ltini
	    ltc0c = c0c(p1, p2, p3, m1, m2, m3)
	    ! call ltexi
		end

		ComplexType function ltc0i(id, p1, p2, p3, m1, m2, m3)
	    implicit none
#include "looptools.h" 
		RealType p1, p2, p3, m1, m2, m3
		integer id
	    call ltini
	    ltc0i = c0i(id, p1, p2, p3, m1, m2, m3)
	    ! call ltexi
		end
		
		ComplexType function ltc0ic(id, p1, p2, p3, m1, m2, m3)
	    implicit none
#include "looptools.h" 
		ComplexType p1, p2, p3, m1, m2, m3
		integer id
	    call ltini
	    ltc0ic = c0ic(id, p1, p2, p3, m1, m2, m3)
	    ! call ltexi
		end
		
		ComplexType function ltc0i2(id,xpi,xmi)
	    implicit none
#include "looptools.h" 
        RealType xpi(3), xmi(3)
		RealType p1,p2,p3
		RealType m1,m2,m3
		integer id
		p1 = xpi(1)
		p2 = xpi(2)
		p3 = xpi(3)
		m1 = xmi(1)
		m2 = xmi(2)
		m3 = xmi(3)
	    call ltini
		ltc0i2=c0i(id,p1,p2,p3,m1,m2,m3)
	    ! call ltexi
		end
		
		ComplexType function ltc0ic2(id,xpi,xmi)
	    implicit none
#include "looptools.h" 
        ComplexType xpi(3), xmi(3)
		ComplexType p1,p2,p3
		ComplexType m1,m2,m3
		integer id
		p1 = xpi(1)
		p2 = xpi(2)
		p3 = xpi(3)
		m1 = xmi(1)
		m2 = xmi(2)
		m3 = xmi(3)
	    call ltini
		ltc0ic2=c0ic(id,p1,p2,p3,m1,m2,m3)
	    ! call ltexi
		end

		
!=======4-point functions========
	    ComplexType function ltd0(p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    implicit none
#include "looptools.h" 
        RealType p1, p2, p3, p4, p12, p23, m1, m2, m3, m4
	    call ltini
	    ltd0 = d0(p1, p2, p3, p4, p12, p23, m1, m2, m3, m4)
	    ! call ltexi
		end
		
	    ComplexType function ltd0c(p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    implicit none
#include "looptools.h" 
        RealType p1, p2, p3, p4, p12, p23
	    ComplexType m1, m2, m3, m4
	    call ltini
	    ltd0c = d0c(p1, p2, p3, p4, p12, p23, m1, m2, m3, m4)
	    ! call ltexi
		end

		ComplexType function ltd0i(id,p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    implicit none
#include "looptools.h" 
		RealType p1,p2,p3,p4,p12,p23,m1,m2,m3,m4
		integer id
	    call ltini
	    ltd0i = d0i(id, p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    ! call ltexi
		end
		
	  ComplexType function ltd0ic(id,p1,p2,p3,p4,p12,p23,m1,m2,
     +  m3,m4)
	    implicit none
#include "looptools.h" 
		ComplexType p1,p2,p3,p4,p12,p23,m1,m2,m3,m4
		integer id
	    call ltini
	    ltd0ic = d0ic(id, p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    ! call ltexi
		end
		
        ComplexType function ltd0i2(id,xpi,xmi)
	    implicit none
#include "looptools.h" 
        RealType xpi(6), xmi(4)
		RealType p1,p2,p3,p4,p12,p23
		RealType m1,m2,m3,m4
		integer id
		p1 = xpi(1)
		p2 = xpi(2)
		p3 = xpi(3)
		p4 = xpi(4)
		p12 = xpi(5)
		p23 = xpi(6)
		m1 = xmi(1)
		m2 = xmi(2)
		m3 = xmi(3)
		m4 = xmi(4)
	    call ltini
		ltd0i2=d0i(id,p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    ! call ltexi
		end

		ComplexType function ltd0ic2(id,xpi,xmi)
	    implicit none
#include "looptools.h" 
        ComplexType xpi(6), xmi(4)
		ComplexType p1,p2,p3,p4,p12,p23
		ComplexType m1,m2,m3,m4
		integer id
		p1 = xpi(1)
		p2 = xpi(2)
		p3 = xpi(3)
		p4 = xpi(4)
		p12 = xpi(5)
		p23 = xpi(6)
		m1 = xmi(1)
		m2 = xmi(2)
		m3 = xmi(3)
		m4 = xmi(4)
	    call ltini
		ltd0ic2=d0ic(id,p1,p2,p3,p4,p12,p23,m1,m2,m3,m4)
	    ! call ltexi
		end
	
!=======5-point functions========
      ComplexType function lte0i(id,p1,p2,p3,p4,p5,p12,p23,p34,
     +  p45,p51,m1,m2,m3,m4,m5)
	    implicit none
#include "looptools.h" 
        ! RealType xpi(10), xmi(5)
		RealType p1,p2,p3,p4,p5,p12,p23,p34,p45,p51
		RealType m1,m2,m3,m4,m5
		integer id
		call ltini
		lte0i = e0i(id,p1,p2,p3,p4,p5,p12,p23,p34,p45,p51,
     +            m1,m2,m3,m4,m5)
	    ! call ltexi
		end

      ComplexType function lte0ic(id,p1,p2,p3,p4,p5,p12,p23,p34,
     +  p45,p51,m1,m2,m3,m4,m5)
	    implicit none
#include "looptools.h" 
		ComplexType p1,p2,p3,p4,p5,p12,p23,p34,p45,p51
		ComplexType m1,m2,m3,m4,m5
		integer id
		call ltini
		lte0ic = e0ic(id,p1,p2,p3,p4,p5,p12,p23,p34,p45,p51,
     +              m1,m2,m3,m4,m5)
	    ! call ltexi
		end

	    ComplexType function lte0i2(id,xpi,xmi)
	    implicit none
#include "looptools.h" 
        RealType xpi(10), xmi(5)
		RealType p1,p2,p3,p4,p5,p12,p23,p34,p45,p51
		RealType m1,m2,m3,m4,m5
		integer id
		p1 = xpi(1)
		p2 = xpi(2)
		p3 = xpi(3)
		p4 = xpi(4)
		p5 = xpi(5)
		p12 = xpi(6)
		p23 = xpi(7)
		p34 = xpi(8)
		p45 = xpi(9)
		p51 = xpi(10)
		m1 = xmi(1)
		m2 = xmi(2)
		m3 = xmi(3)
		m4 = xmi(4)
		m5 = xmi(5)
	    call ltini
		lte0i2=e0i(id,p1,p2,p3,p4,p5,p12,p23,p34,p45,p51,
     +  m1,m2,m3,m4,m5)
	    ! call ltexi
		end
		
		ComplexType function lte0ic2(id,xpi,xmi)
	    implicit none
#include "looptools.h" 
		ComplexType xpi(10), xmi(5)
		ComplexType p1,p2,p3,p4,p5,p12,p23,p34,p45,p51
		ComplexType m1,m2,m3,m4,m5
		integer id
		p1 = xpi(1)
		p2 = xpi(2)
		p3 = xpi(3)
		p4 = xpi(4)
		p5 = xpi(5)
		p12 = xpi(6)
		p23 = xpi(7)
		p34 = xpi(8)
		p45 = xpi(9)
		p51 = xpi(10)
		m1 = xmi(1)
		m2 = xmi(2)
		m3 = xmi(3)
		m4 = xmi(4)
		m5 = xmi(5)
	    call ltini
		lte0ic2=e0ic(id,p1,p2,p3,p4,p5,p12,p23,p34,p45,p51,
     +  m1,m2,m3,m4,m5)
	    ! call ltexi
		end

