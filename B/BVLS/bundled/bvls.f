c=======================================================================
      subroutine bvls(key, m, n, a, b, bl, bu, x, w, act, zz, istate,
     +  loopA)
c=======================================================================
      implicit double precision (a-h, o-z)
c
c$$$$ calls qr
c--------------------Bounded Variable Least Squares---------------------
c
c        Robert L. Parker and Philip B. Stark    Version 3/19/90
c
c  Robert L. Parker                           Philip B. Stark
c  Scripps Institution of Oceanography        Department of Statistics
c  University of California, San Diego        University of California
c  La Jolla CA 92093                          Berkeley CA 94720-3860
c  rlparker@ucsd.edu                          stark@stat.berkeley.edu
c
c  Copyright the authors 1995-November 2007.
c  Copyright GPL version 2 or newer from December 2007.
c
c
c  See the article ``Bounded Variable Least Squares:  An Algorithm and
c  Applications'' by P.B. Stark and R.L. Parker, in the journal 
c  Computational Statistics, in press (1995) for further description 
c  and applications to minimum l-1, l-2 and l-infinity fitting problems, 
c  as well as finding bounds on linear functionals subject to bounds on 
c  variables and fitting linear data within l-1, l-2 or l-infinity 
c  measures of misfit.
c
c  BVLS solves the problem: 
c
c          min  || a.x - b ||     such that   bl <= x <= bu
c                            2
c    where  
c               x  is an unknown n-vector
c               a  is a given m by n matrix
c               b  is a given  m-vector 
c               bl is a given n-vector of lower bounds on the
c                                components of x.
c               bu is a given n-vector of upper bounds on the
c                                components of x.
c
c               
c-----------------------------------------------------------------------
c    Input parameters:
c
c  m, n, a, b, bl, bu   see above.   Let mm=min(m,n).
c
c  If key = 0, the subroutine solves the problem from scratch.
c
c  If key > 0 the routine initializes using the user's guess about
c   which components of  x  are `active', i.e. are stricly within their
c   bounds, which are at their lower bounds, and which are at their 
c   upper bounds.  This information is supplied through the array  
c   istate.  istate(n+1) should contain the total number of components 
c   at their bounds (the `bound variables').  The absolute values of the
c   first nbound=istate(n+1) entries of  istate  are the indices
c   of these `bound' components of  x.  The sign of istate(j), j=1,...,
c   nbound, indicates whether  x(|istate(j)|) is at its upper or lower
c   bound.  istate(j) is positive if the component is at its upper
c   bound, negative if the component is at its lower bound.
c   istate(j), j=nbound+1,...,n  contain the indices of the components
c   of  x  that are active (i.e. are expected to lie strictly within 
c   their bounds).  When key > 0, the routine initially sets the active 
c   components to the averages of their upper and lower bounds: 
c   x(j)=(bl(j)+bu(j))/2, for j in the active set.  
c
c-----------------------------------------------------------------------
c    Output parameters:
c
c  x       the solution vector.
c
c  w(1)    the minimum 2-norm || a.x-b ||.
c
c  istate  vector indicating which components of  x  are active and 
c          which are at their bounds (see the previous paragraph).  
c          istate can be supplied to the routine to give it a good 
c          starting guess for the solution.
c
c  loopA   number of iterations taken in the main loop, Loop A.
c
c-----------------------------------------------------------------------
c    Working  arrays:
c
c  w      dimension n.               act      dimension m*(mm+2).
c  zz     dimension m.               istate   dimension n+1.
c
c-----------------------------------------------------------------------
c  Method: active variable method along the general plan of NNLS by
c  Lawson & Hanson, "Solving Least Squares Problems," 1974.  See
c  Algorithm 23.10.  Step numbers in comment statements refer to their 
c  scheme.
c  For more details and further uses, see the article 
c  "Bounded Variable Least Squares:  An Algorithm and Applications" 
c  by Stark and Parker in 1995 Computational Statistics.
c
c-----------------------------------------------------------------------
c  A number of measures are taken to enhance numerical reliability:
c
c 1. As noted by Lawson and Hanson, roundoff errors in the computation
c   of the gradient of the misfit may cause a component on the bounds
c   to appear to want to become active, yet when the component is added
c   to the active set, it moves away from the feasible region.  In this
c   case the component is not made active, the gradient of the misfit
c   with respect to a change in that component is set to zero, and the
c   program returns to the Kuhn-Tucker test.  Flag  ifrom5  is used in 
c   this test, which occurs at the end of Step 6.
c
c
c 2. When the least-squares minimizer after Step 6 is infeasible, it
c   is used in a convex interpolation with the previous solution to 
c   obtain a feasible vector.  The constant in this interpolation is
c   supposed to put at least one component of  x   on a bound. There can
c   be difficulties: 
c
c 2a. Sometimes, due to roundoff, no interpolated component ends up on 
c   a bound.  The code in Step 11 uses the flag  jj, computed in Step 8,
c   to ensure that at least the component that determined the 
c   interpolation constant  alpha  is moved to the appropriate bound.  
c   This guarantees that what Lawson and Hanson call `Loop B' is finite.
c
c 2b. The code in Step 11 also incorporates Lawson and Hanson's feature
c   that any components remaining infeasible at this stage (which must
c   be due to roundoff) are moved to their nearer bound.
c
c
c 3. If the columns of  a  passed to qr are linearly dependent, the new
c   potentially active component is not introduced: the gradient of the
c   misfit with respect to that component is set to zero, and control
c   returns to the Kuhn-Tucker test.
c
c
c 4. When some of the columns of  a  are approximately linearly 
c   dependent, we have observed cycling of active components: a 
c   component just moved to a bound desires immediately to become 
c   active again; qr allows it to become active and a different 
c   component is moved to its bound.   This component immediately wants
c   to become active, which qr allows, and the original component is
c   moved back to its bound.  We have taken two steps to avoid this 
c   problem:
c
c 4a. First, the column of the matrix  a  corresponding to the new 
c   potentially active component is passed to qr as the last column of 
c   its matrix.  This ordering tends to make a component recently moved
c   to a bound fail the test mentioned in (1), above.
c
c 4b. Second, we have incorporated a test that prohibits short cycles.
c   If the most recent successful change to the active set was to move
c   the component x(jj) to a bound, x(jj) is not permitted to reenter 
c   the solution at this stage.  This test occurs just after checking
c   the Kuhn-Tucker conditions, and uses the flag  jj, set in Step 8.
c   The flag  jj  is reset after Step 6 if Step 6 was entered from
c   Step 5 indicating that a new component has successfully entered the
c   active set. The test for resetting  jj  uses the flag  ifrom5,
c   which will not equal zero in case Step 6 was entered from Step 5.
c
c
      dimension a(m,n), b(m), x(n), bl(n), bu(n)
c     dimension w(n), act(m,min(m,n)+2), zz(m), istate(n+1)
      dimension w(n), act(m,m+2), zz(m), istate(n+1)
c
      data eps/1.0d-11/
c
c----------------------First Executable Statement-----------------------
c
c  Step 1.  Initialize everything--active and bound sets, initial 
c   values, etc.
c
c  Initialize flags, etc.
      mm=min(m,n)
      mm1 = mm + 1
      jj = 0
      ifrom5 = 0
c  Check consistency of given bounds  bl, bu.
      bdiff = 0.0
      do 1005 j=1, n
        bdiff=max(bdiff, bu(j)-bl(j))
        if (bl(j) .gt. bu(j)) then
           return
        endif
C        print *,' Inconsistent bounds in BVLS. '
C     stop
        
 1005 continue
      if (bdiff .eq. 0.0) then
         return
C        print *,' No free variables in BVLS--check input bounds.'
C     stop 
      endif
c
c  In a fresh initialization (key = 0) bind all variables at their lower
c   bounds.  If (key != 0), use the supplied  istate  vector to
c   initialize the variables.  istate(n+1) contains the number of
c   bound variables.  The absolute values of the first 
c   nbound=istate(n+1) entries of  istate  are the indices of the bound
c   variables.  The sign of each entry determines whether the indicated
c   variable is at its upper (positive) or lower (negative) bound.
      if (key .eq. 0) then
        nbound=n
        nact=0
        do 1010 j=1, nbound
          istate(j)=-j
 1010   continue
      else
        nbound=istate(n+1)
      endif
      nact=n - nbound
      if ( nact .gt. mm ) then
         return
C        print *, ' Too many active variables in BVLS starting solution!'
C        stop
      endif
      do 1100 k=1, nbound
        j=abs(istate(k))
        if (istate(k) .lt. 0) x(j)=bl(j)
        if (istate(k) .gt. 0) x(j)=bu(j)
 1100 continue
c
c  In a warm start (key != 0) initialize the active variables to 
c   (bl+bu)/2.  This is needed in case the initial qr results in 
c   active variables out-of-bounds and Steps 8-11 get executed the 
c   first time through. 
      do 1150 k=nbound+1,n
        kk=istate(k)
        x(kk)=(bu(kk)+bl(kk))/2
 1150 continue
c
c  Compute bnorm, the norm of the data vector b, for reference.
      bsq=0.0
      do 1200 i=1, m
        bsq=bsq + b(i)**2
 1200 continue
      bnorm=sqrt(bsq)
c
c-----------------------------Main Loop---------------------------------
c
c  Initialization complete.  Begin major loop (Loop A).
      do 15000 loopA=1, 3*n
c
c  Step 2.
c  Initialize the negative gradient vector w(*).
 2000 obj=0.0
      do 2050 j=1, n
        w(j)=0.0
 2050 continue
c
c  Compute the residual vector b-a.x , the negative gradient vector
c   w(*), and the current objective value obj = || a.x - b ||.
c   The residual vector is stored in the mm+1'st column of act(*,*).
      do 2300 i=1, m
        ri=b(i)
        do 2100 j=1, n
          ri=ri - a(i,j)*x(j)
 2100   continue
        obj=obj + ri**2
        do 2200 j=1, n
          w(j)=w(j) + a(i,j)*ri
 2200   continue
        act(i,mm1)=ri
 2300 continue
c
c  Converged?  Stop if the misfit << || b ||, or if all components are 
c   active (unless this is the first iteration from a warm start). 
      if (sqrt(obj) .le. bnorm*eps .or. 
     +  (loopA .gt. 1 .and. nbound .eq. 0)) then
         istate(n+1)=nbound
         w(1)=sqrt(obj)
         return
      endif
c
c  Add the contribution of the active components back into the residual.
      do 2500 k=nbound+1, n
        j=istate(k)
        do 2400 i=1, m
          act(i,mm1)=act(i,mm1) + a(i,j)*x(j)
 2400   continue
 2500 continue
c
c  The first iteration in a warm start requires immediate qr.
      if (loopA .eq. 1 .and. key .ne. 0) goto 6000
c
c  Steps 3, 4.
c  Find the bound element that most wants to be active.
 3000 worst=0.0
      it=1
      do 3100 j=1, nbound
         ks=abs(istate(j))
         bad=w(ks)*sign(1, istate(j))
         if (bad .lt. worst) then
            it=j
            worst=bad
            iact=ks
         endif
 3100 continue
c
c  Test whether the Kuhn-Tucker condition is met.
      if (worst .ge. 0.0 ) then
         istate(n+1)=nbound
         w(1)=sqrt(obj)
         return
      endif
c
c  The component  x(iact)  is the one that most wants to become active.
c   If the last successful change in the active set was to move x(iact)
c   to a bound, don't let x(iact) in now: set the derivative of the 
c   misfit with respect to x(iact) to zero and return to the Kuhn-Tucker
c   test.
      if ( iact .eq. jj ) then
        w(jj)=0.0
        goto 3000
      endif
c
c  Step 5.
c  Undo the effect of the new (potentially) active variable on the 
c   residual vector.
      if (istate(it) .gt. 0) bound=bu(iact)
      if (istate(it) .lt. 0) bound=bl(iact)
      do 5100 i=1, m
        act(i,mm1)=act(i,mm1) + bound*a(i,iact)
 5100 continue
c 
c  Set flag ifrom5, indicating that Step 6 was entered from Step 5.
c   This forms the basis of a test for instability: the gradient
c   calculation shows that x(iact) wants to join the active set; if 
c   qr puts x(iact) beyond the bound from which it came, the gradient 
c   calculation was in error and the variable should not have been 
c   introduced.
      ifrom5=istate(it)
c
c  Swap the indices (in istate) of the new active variable and the
c   rightmost bound variable; `unbind' that location by decrementing
c   nbound.
      istate(it)=istate(nbound)
      nbound=nbound - 1
      nact=nact + 1
      istate(nbound+1)=iact
c
      if (mm .lt. nact) then
         return
C     print *,' Too many free variables in BVLS!'
C         stop
      endif
c
c  Step 6.
c  Load array  act  with the appropriate columns of  a  for qr.  For
c   added stability, reverse the column ordering so that the most
c   recent addition to the active set is in the last column.  Also 
c   copy the residual vector from act(., mm1) into act(., mm1+1).
 6000 do 6200 i=1, m
        act(i,mm1+1)=act(i,mm1)
        do 6100 k=nbound+1, n
          j=istate(k)
          act(i,nact+1-k+nbound)=a(i,j)
 6100   continue
 6200 continue
c
      call qr(m, nact, act, act(1,mm1+1), zz, resq)
c
c  Test for linear dependence in qr, and for an instability that moves
c   the variable just introduced away from the feasible region 
c   (rather than into the region or all the way through it). 
c   In either case, remove the latest vector introduced from the
c   active set and adjust the residual vector accordingly.  
c   Set the gradient component (w(iact)) to zero and return to 
c   the Kuhn-Tucker test.
      if (resq .lt. 0.0 
     +   .or. (ifrom5 .gt. 0 .and. zz(nact) .gt. bu(iact))
     +   .or. (ifrom5 .lt. 0 .and. zz(nact) .lt. bl(iact))) then
         nbound=nbound + 1
         istate(nbound)=istate(nbound)*sign(1.0d0, x(iact)-bu(iact))
         nact=nact - 1
         do 6500 i=1, m
           act(i,mm1)=act(i,mm1) - x(iact)*a(i,iact)
 6500    continue
         ifrom5=0
         w(iact)=0.0
         goto 3000
      endif
c
c  If Step 6 was entered from Step 5 and we are here, a new variable 
c   has been successfully introduced into the active set; the last 
c   variable that was fixed at a bound is again permitted to become 
c   active.
      if ( ifrom5 .ne. 0 ) jj=0
      ifrom5=0
c
c   Step 7.  Check for strict feasibility of the new qr solution.
      do 7100 k=1, nact
        k1=k
        j=istate(k+nbound)
        if (zz(nact+1-k).lt.bl(j) .or. zz(nact+1-k).gt.bu(j)) goto 8000
 7100 continue
      do 7200 k=1, nact
        j=istate(k+nbound)
        x(j)=zz(nact+1-k)
 7200 continue
c  New iterate is feasible; back to the top.
      goto 15000
c
c  Steps 8, 9.
c sj=sign(1, zz(nact+1-k)-bl(j)) was the way the last if statement in 
c the block below was formulated - am changing to make compiling w/gfortran
c possible.  Am also commenting out print and stop statements throughout,
C and replacing with return. (KMM, 3.12.07)  
 8000 alpha=2.0
      alf=alpha
      do 8200 k=k1, nact
        j=istate(k+nbound)
        if (zz(nact+1-k) .gt. bu(j)) 
     +    alf=(bu(j)-x(j))/(zz(nact+1-k)-x(j))
        if (zz(nact+1-k) .lt. bl(j)) 
     +    alf=(bl(j)-x(j))/(zz(nact+1-k)-x(j))
        if (alf .lt. alpha) then
          alpha=alf
          jj=j
          if(zz(nact+1-k)-bl(j) .gt. 0.0) then
             sj = 1
          else
             sj = -1
          endif           
        endif
 8200 continue
c
c  Step 10
      do 10000 k=1, nact
        j=istate(k+nbound)
        x(j)=x(j) + alpha*(zz(nact+1-k)-x(j))
10000 continue
c
c  Step 11.  
c  Move the variable that determined alpha to the appropriate bound.  
c   (jj is its index; sj is + if zz(jj)> bu(jj), - if zz(jj)<bl(jj) ).
c   If any other component of  x  is infeasible at this stage, it must
c   be due to roundoff.  Bind every infeasible component and every
c   component at a bound to the appropriate bound.  Correct the
c   residual vector for any variables moved to bounds.  Since at least
c   one variable is removed from the active set in this step, Loop B 
c   (Steps 6-11) terminates after at most  nact  steps.
      noldb=nbound
      do 11200 k=1, nact
        j=istate(k+noldb)
        if (((bu(j)-x(j)) .le. 0.0) .or. 
     +    (j .eq. jj .and. sj .gt. 0.0)) then
c  Move x(j) to its upper bound.
          x(j)=bu(j)
          istate(k+noldb)=istate(nbound+1)
          istate(nbound+1)=j
          nbound=nbound+1
          do 11100 i=1, m
             act(i,mm1)=act(i,mm1) - bu(j)*a(i,j)
11100     continue
        else if (((x(j)-bl(j)) .le. 0.0) .or.
     +    (j .eq. jj .and. sj .lt. 0.0)) then
c  Move x(j) to its lower bound.
          x(j)=bl(j)
          istate(k+noldb)=istate(nbound+1)
          istate(nbound+1)=-j
          nbound=nbound+1
          do 11150 i=1, m
             act(i,mm1)=act(i,mm1) - bl(j)*a(i,j)
11150     continue
        endif
11200 continue
      nact=n - nbound
c
c  If there are still active variables left repeat the qr; if not,
c    go back to the top.
      if (nact .gt. 0 ) goto 6000
c
15000 continue
c
C      print *,' BVLS fails to converge! '
C      stop
      end
c======================================================================
      subroutine qr(m, n, a, b, x, resq)
c======================================================================
      implicit double precision (a-h, o-z)                              *doub
c$$$$ calls no other routines
c  Relies on FORTRAN77 do-loop conventions!
c  Solves over-determined least-squares problem  ax ~ b
c  where  a  is an  m by n  matrix,  b  is an m-vector .
c  resq  is the sum of squared residuals of optimal solution.  Also used
c  to signal error conditions - if -2 , system is underdetermined,  if
c  -1,  system is singular.
c  Method - successive Householder rotations.  See Lawson & Hanson - 
c  Solving Least Squares Problems (1974).
c  Routine will also work when m=n.
c*****   CAUTION -  a and b  are overwritten by this routine.
      dimension a(m,n),b(m),x(n)
      double precision sum, dot
c
      resq=-2.0
      if (m .lt. n) return
      resq=-1.0
c   Loop ending on 1800 rotates  a  into upper triangular form.
      do 1800 j=1, n
c   Find constants for rotation and diagonal entry.
        sq=0.0
        do 1100 i=j, m
          sq=a(i,j)**2 + sq
 1100   continue
        if (sq .eq. 0.0) return
        qv1=-sign(sqrt(sq), a(j,j))
        u1=a(j,j) - qv1
        a(j,j)=qv1
        j1=j + 1
c  Rotate remaining columns of sub-matrix.
        do 1400 jj=j1, n
          dot=u1*a(j,jj)
          do 1200 i=j1, m
            dot=a(i,jj)*a(i,j) + dot
 1200     continue
          const=dot/abs(qv1*u1)
          do 1300 i=j1, m
            a(i,jj)=a(i,jj) - const*a(i,j)
 1300     continue
          a(j,jj)=a(j,jj) - const*u1
 1400   continue
c  Rotate  b  vector.
        dot=u1*b(j)
        do 1600 i=j1, m
          dot=b(i)*a(i,j) + dot
 1600   continue
        const=dot/abs(qv1*u1)
        b(j)=b(j) - const*u1
        do 1700 i=j1, m
          b(i)=b(i) - const*a(i,j)
 1700   continue
 1800 continue
c  Solve triangular system by back-substitution.
      do 2200 ii=1, n
        i=n-ii+1
        sum=b(i)
        do 2100 j=i+1, n
          sum=sum - a(i,j)*x(j)
 2100   continue
        if (a(i,i).eq. 0.0) return
         x(i)=sum/a(i,i)
 2200 continue
c  Find residual in overdetermined case.
      resq=0.0
      do 2300 i=n+1, m
        resq=b(i)**2 + resq
 2300 continue
      return
      end                                                               qr
c______________________________________________________________________
