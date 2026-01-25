module handyg_capi
  use, intrinsic :: iso_c_binding, only: c_ptr, c_int, c_int8_t, c_f_pointer
  use globals, only: prec, zero, set_options
  use ieps, only: inum, di0
  use gpl_module, only: G_flat, G_condensed, clearcache
  implicit none
contains

  subroutine handyg_clearcache() bind(C, name="handyg_clearcache")
    call clearcache()
  end subroutine handyg_clearcache

  subroutine handyg_set_mpldelta(val_ptr) bind(C, name="handyg_set_mpldelta")
    type(c_ptr), value :: val_ptr
    real(kind=prec), pointer :: val
    call c_f_pointer(val_ptr, val)
    call set_options(mpldel=val)
  end subroutine handyg_set_mpldelta

  subroutine handyg_set_lidelta(val_ptr) bind(C, name="handyg_set_lidelta")
    type(c_ptr), value :: val_ptr
    real(kind=prec), pointer :: val
    call c_f_pointer(val_ptr, val)
    call set_options(lidel=val)
  end subroutine handyg_set_lidelta

  subroutine handyg_set_hoelder_circle(val_ptr) bind(C, name="handyg_set_hoelder_circle")
    type(c_ptr), value :: val_ptr
    real(kind=prec), pointer :: val
    call c_f_pointer(val_ptr, val)
    call set_options(hcircle=val)
  end subroutine handyg_set_hoelder_circle

  subroutine set_inum_auto(out, z)
    type(inum), intent(out) :: out
    complex(kind=prec), intent(in) :: z
    out%c = z
    out%i0 = di0
    if (abs(aimag(z)) > zero) out%i0 = int(sign(1._prec, aimag(z)), kind=1)
  end subroutine set_inum_auto

  subroutine set_inum_real(out, x)
    type(inum), intent(out) :: out
    real(kind=prec), intent(in) :: x
    out%c = cmplx(x, 0._prec, kind=prec)
    out%i0 = di0
  end subroutine set_inum_real

  subroutine set_inum_i0(out, z, i0)
    type(inum), intent(out) :: out
    complex(kind=prec), intent(in) :: z
    integer(c_int8_t), intent(in) :: i0
    out%c = z
    out%i0 = int(i0, kind=1)
    if (abs(aimag(z)) > zero) out%i0 = int(sign(1._prec, aimag(z)), kind=1)
  end subroutine set_inum_i0

  subroutine set_inum_real_i0(out, x, i0)
    type(inum), intent(out) :: out
    real(kind=prec), intent(in) :: x
    integer(c_int8_t), intent(in) :: i0
    out%c = cmplx(x, 0._prec, kind=prec)
    out%i0 = int(i0, kind=1)
  end subroutine set_inum_real_i0

  subroutine handyg_g_flat_cc(out_ptr, z_ptr, n, y_ptr) bind(C, name="handyg_g_flat_cc")
    type(c_ptr), value :: out_ptr, z_ptr, y_ptr
    integer(c_int), value :: n
    complex(kind=prec), pointer :: out
    complex(kind=prec), pointer :: z(:)
    complex(kind=prec), pointer :: y
    type(inum) :: z_inum(n)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(z_ptr, z, [n])
    call c_f_pointer(y_ptr, y)

    if (n < 1) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, n
      call set_inum_auto(z_inum(i), z(i))
    end do
    call set_inum_auto(y_inum, y)

    out = G_flat(z_inum, y_inum)
  end subroutine handyg_g_flat_cc

  subroutine handyg_g_flat_rc(out_ptr, z_ptr, n, y_ptr) bind(C, name="handyg_g_flat_rc")
    type(c_ptr), value :: out_ptr, z_ptr, y_ptr
    integer(c_int), value :: n
    complex(kind=prec), pointer :: out
    real(kind=prec), pointer :: z(:)
    complex(kind=prec), pointer :: y
    type(inum) :: z_inum(n)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(z_ptr, z, [n])
    call c_f_pointer(y_ptr, y)

    if (n < 1) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, n
      call set_inum_real(z_inum(i), z(i))
    end do
    call set_inum_auto(y_inum, y)

    out = G_flat(z_inum, y_inum)
  end subroutine handyg_g_flat_rc

  subroutine handyg_g_flat_i0(out_ptr, z_ptr, z_i0_ptr, n, y_ptr, y_i0) bind(C, name="handyg_g_flat_i0")
    type(c_ptr), value :: out_ptr, z_ptr, z_i0_ptr, y_ptr
    integer(c_int), value :: n
    integer(c_int8_t), value :: y_i0
    complex(kind=prec), pointer :: out
    complex(kind=prec), pointer :: z(:)
    integer(c_int8_t), pointer :: z_i0(:)
    complex(kind=prec), pointer :: y
    type(inum) :: z_inum(n)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(z_ptr, z, [n])
    call c_f_pointer(z_i0_ptr, z_i0, [n])
    call c_f_pointer(y_ptr, y)

    if (n < 1) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, n
      call set_inum_i0(z_inum(i), z(i), z_i0(i))
    end do
    call set_inum_i0(y_inum, y, y_i0)

    out = G_flat(z_inum, y_inum)
  end subroutine handyg_g_flat_i0

  subroutine handyg_g_superflat_c(out_ptr, g_ptr, n) bind(C, name="handyg_g_superflat_c")
    type(c_ptr), value :: out_ptr, g_ptr
    integer(c_int), value :: n
    complex(kind=prec), pointer :: out
    complex(kind=prec), pointer :: g(:)
    type(inum) :: z_inum(n)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(g_ptr, g, [n])

    if (n < 2) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, n-1
      call set_inum_auto(z_inum(i), g(i))
    end do
    call set_inum_auto(y_inum, g(n))

    out = G_flat(z_inum(1:n-1), y_inum)
  end subroutine handyg_g_superflat_c

  subroutine handyg_g_superflat_r(out_ptr, g_ptr, n) bind(C, name="handyg_g_superflat_r")
    type(c_ptr), value :: out_ptr, g_ptr
    integer(c_int), value :: n
    complex(kind=prec), pointer :: out
    real(kind=prec), pointer :: g(:)
    type(inum) :: z_inum(n)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(g_ptr, g, [n])

    if (n < 2) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, n-1
      call set_inum_real(z_inum(i), g(i))
    end do
    call set_inum_real(y_inum, g(n))

    out = G_flat(z_inum(1:n-1), y_inum)
  end subroutine handyg_g_superflat_r

  subroutine handyg_g_condensed_cc(out_ptr, m_ptr, z_ptr, k, y_ptr) bind(C, name="handyg_g_condensed_cc")
    type(c_ptr), value :: out_ptr, m_ptr, z_ptr, y_ptr
    integer(c_int), value :: k
    complex(kind=prec), pointer :: out
    integer(c_int), pointer :: m(:)
    complex(kind=prec), pointer :: z(:)
    complex(kind=prec), pointer :: y
    type(inum) :: z_inum(k)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(m_ptr, m, [k])
    call c_f_pointer(z_ptr, z, [k])
    call c_f_pointer(y_ptr, y)

    if (k < 1) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, k
      call set_inum_auto(z_inum(i), z(i))
    end do
    call set_inum_auto(y_inum, y)

    out = G_condensed(m, z_inum, y_inum, k)
  end subroutine handyg_g_condensed_cc

  subroutine handyg_g_condensed_rc(out_ptr, m_ptr, z_ptr, k, y_ptr) bind(C, name="handyg_g_condensed_rc")
    type(c_ptr), value :: out_ptr, m_ptr, z_ptr, y_ptr
    integer(c_int), value :: k
    complex(kind=prec), pointer :: out
    integer(c_int), pointer :: m(:)
    real(kind=prec), pointer :: z(:)
    complex(kind=prec), pointer :: y
    type(inum) :: z_inum(k)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(m_ptr, m, [k])
    call c_f_pointer(z_ptr, z, [k])
    call c_f_pointer(y_ptr, y)

    if (k < 1) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, k
      call set_inum_real(z_inum(i), z(i))
    end do
    call set_inum_auto(y_inum, y)

    out = G_condensed(m, z_inum, y_inum, k)
  end subroutine handyg_g_condensed_rc

  subroutine handyg_g_condensed_i0(out_ptr, m_ptr, z_ptr, z_i0_ptr, k, y_ptr, y_i0) bind(C, name="handyg_g_condensed_i0")
    type(c_ptr), value :: out_ptr, m_ptr, z_ptr, z_i0_ptr, y_ptr
    integer(c_int), value :: k
    integer(c_int8_t), value :: y_i0
    complex(kind=prec), pointer :: out
    integer(c_int), pointer :: m(:)
    complex(kind=prec), pointer :: z(:)
    integer(c_int8_t), pointer :: z_i0(:)
    complex(kind=prec), pointer :: y
    type(inum) :: z_inum(k)
    type(inum) :: y_inum
    integer :: i

    call c_f_pointer(out_ptr, out)
    call c_f_pointer(m_ptr, m, [k])
    call c_f_pointer(z_ptr, z, [k])
    call c_f_pointer(z_i0_ptr, z_i0, [k])
    call c_f_pointer(y_ptr, y)

    if (k < 1) then
      out = cmplx(0._prec, 0._prec, kind=prec)
      return
    end if

    do i = 1, k
      call set_inum_i0(z_inum(i), z(i), z_i0(i))
    end do
    call set_inum_i0(y_inum, y, y_i0)

    out = G_condensed(m, z_inum, y_inum, k)
  end subroutine handyg_g_condensed_i0

  subroutine handyg_g_flat_batch_cc(out_ptr, z_ptr, depth_max, ncols, len_ptr, y_ptr) bind(C, name="handyg_g_flat_batch_cc")
    type(c_ptr), value :: out_ptr, z_ptr, len_ptr, y_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    complex(kind=prec), pointer :: z(:, :)
    integer(c_int), pointer :: len(:)
    complex(kind=prec), pointer :: y(:)
    type(inum) :: z_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, n

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(z_ptr, z, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])
    call c_f_pointer(y_ptr, y, [ncols])

    do j = 1, ncols
      n = len(j)
      if (n < 1) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      do i = 1, n
        call set_inum_auto(z_inum(i), z(i, j))
      end do
      call set_inum_auto(y_inum, y(j))
      out(j) = G_flat(z_inum(1:n), y_inum)
    end do
  end subroutine handyg_g_flat_batch_cc

  subroutine handyg_g_flat_batch_rc(out_ptr, z_ptr, depth_max, ncols, len_ptr, y_ptr) bind(C, name="handyg_g_flat_batch_rc")
    type(c_ptr), value :: out_ptr, z_ptr, len_ptr, y_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    real(kind=prec), pointer :: z(:, :)
    integer(c_int), pointer :: len(:)
    complex(kind=prec), pointer :: y(:)
    type(inum) :: z_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, n

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(z_ptr, z, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])
    call c_f_pointer(y_ptr, y, [ncols])

    do j = 1, ncols
      n = len(j)
      if (n < 1) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      do i = 1, n
        call set_inum_real(z_inum(i), z(i, j))
      end do
      call set_inum_auto(y_inum, y(j))
      out(j) = G_flat(z_inum(1:n), y_inum)
    end do
  end subroutine handyg_g_flat_batch_rc

  subroutine handyg_g_flat_batch_i0(out_ptr, z_ptr, z_i0_ptr, depth_max, ncols, len_ptr, y_ptr, y_i0_ptr) bind(C, name="handyg_g_flat_batch_i0")
    type(c_ptr), value :: out_ptr, z_ptr, z_i0_ptr, len_ptr, y_ptr, y_i0_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    complex(kind=prec), pointer :: z(:, :)
    integer(c_int8_t), pointer :: z_i0(:, :)
    integer(c_int), pointer :: len(:)
    complex(kind=prec), pointer :: y(:)
    integer(c_int8_t), pointer :: y_i0(:)
    type(inum) :: z_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, n

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(z_ptr, z, [depth_max, ncols])
    call c_f_pointer(z_i0_ptr, z_i0, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])
    call c_f_pointer(y_ptr, y, [ncols])
    call c_f_pointer(y_i0_ptr, y_i0, [ncols])

    do j = 1, ncols
      n = len(j)
      if (n < 1) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      do i = 1, n
        call set_inum_i0(z_inum(i), z(i, j), z_i0(i, j))
      end do
      call set_inum_i0(y_inum, y(j), y_i0(j))
      out(j) = G_flat(z_inum(1:n), y_inum)
    end do
  end subroutine handyg_g_flat_batch_i0

  subroutine handyg_g_superflat_batch_c(out_ptr, g_ptr, depth_max, ncols, len_ptr) bind(C, name="handyg_g_superflat_batch_c")
    type(c_ptr), value :: out_ptr, g_ptr, len_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    complex(kind=prec), pointer :: g(:, :)
    integer(c_int), pointer :: len(:)
    type(inum) :: g_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, n, nz

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(g_ptr, g, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])

    do j = 1, ncols
      n = len(j)
      if (n < 2) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      nz = n-1
      do i = 1, nz
        call set_inum_auto(g_inum(i), g(i, j))
      end do
      call set_inum_auto(y_inum, g(n, j))
      out(j) = G_flat(g_inum(1:nz), y_inum)
    end do
  end subroutine handyg_g_superflat_batch_c

  subroutine handyg_g_superflat_batch_r(out_ptr, g_ptr, depth_max, ncols, len_ptr) bind(C, name="handyg_g_superflat_batch_r")
    type(c_ptr), value :: out_ptr, g_ptr, len_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    real(kind=prec), pointer :: g(:, :)
    integer(c_int), pointer :: len(:)
    type(inum) :: g_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, n, nz

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(g_ptr, g, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])

    do j = 1, ncols
      n = len(j)
      if (n < 2) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      nz = n-1
      do i = 1, nz
        call set_inum_real(g_inum(i), g(i, j))
      end do
      call set_inum_real(y_inum, g(n, j))
      out(j) = G_flat(g_inum(1:nz), y_inum)
    end do
  end subroutine handyg_g_superflat_batch_r

  subroutine handyg_g_condensed_batch_cc(out_ptr, m_ptr, z_ptr, depth_max, ncols, len_ptr, y_ptr) bind(C, name="handyg_g_condensed_batch_cc")
    type(c_ptr), value :: out_ptr, m_ptr, z_ptr, len_ptr, y_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    integer(c_int), pointer :: m(:, :)
    complex(kind=prec), pointer :: z(:, :)
    integer(c_int), pointer :: len(:)
    complex(kind=prec), pointer :: y(:)
    type(inum) :: z_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, k

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(m_ptr, m, [depth_max, ncols])
    call c_f_pointer(z_ptr, z, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])
    call c_f_pointer(y_ptr, y, [ncols])

    do j = 1, ncols
      k = len(j)
      if (k < 1) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      do i = 1, k
        call set_inum_auto(z_inum(i), z(i, j))
      end do
      call set_inum_auto(y_inum, y(j))
      out(j) = G_condensed(m(1:k, j), z_inum(1:k), y_inum, k)
    end do
  end subroutine handyg_g_condensed_batch_cc

  subroutine handyg_g_condensed_batch_rc(out_ptr, m_ptr, z_ptr, depth_max, ncols, len_ptr, y_ptr) bind(C, name="handyg_g_condensed_batch_rc")
    type(c_ptr), value :: out_ptr, m_ptr, z_ptr, len_ptr, y_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    integer(c_int), pointer :: m(:, :)
    real(kind=prec), pointer :: z(:, :)
    integer(c_int), pointer :: len(:)
    complex(kind=prec), pointer :: y(:)
    type(inum) :: z_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, k

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(m_ptr, m, [depth_max, ncols])
    call c_f_pointer(z_ptr, z, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])
    call c_f_pointer(y_ptr, y, [ncols])

    do j = 1, ncols
      k = len(j)
      if (k < 1) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      do i = 1, k
        call set_inum_real(z_inum(i), z(i, j))
      end do
      call set_inum_auto(y_inum, y(j))
      out(j) = G_condensed(m(1:k, j), z_inum(1:k), y_inum, k)
    end do
  end subroutine handyg_g_condensed_batch_rc

  subroutine handyg_g_condensed_batch_i0(out_ptr, m_ptr, z_ptr, z_i0_ptr, depth_max, ncols, len_ptr, y_ptr, y_i0_ptr) bind(C, name="handyg_g_condensed_batch_i0")
    type(c_ptr), value :: out_ptr, m_ptr, z_ptr, z_i0_ptr, len_ptr, y_ptr, y_i0_ptr
    integer(c_int), value :: depth_max, ncols
    complex(kind=prec), pointer :: out(:)
    integer(c_int), pointer :: m(:, :)
    complex(kind=prec), pointer :: z(:, :)
    integer(c_int8_t), pointer :: z_i0(:, :)
    integer(c_int), pointer :: len(:)
    complex(kind=prec), pointer :: y(:)
    integer(c_int8_t), pointer :: y_i0(:)
    type(inum) :: z_inum(depth_max)
    type(inum) :: y_inum
    integer :: i, j, k

    call c_f_pointer(out_ptr, out, [ncols])
    call c_f_pointer(m_ptr, m, [depth_max, ncols])
    call c_f_pointer(z_ptr, z, [depth_max, ncols])
    call c_f_pointer(z_i0_ptr, z_i0, [depth_max, ncols])
    call c_f_pointer(len_ptr, len, [ncols])
    call c_f_pointer(y_ptr, y, [ncols])
    call c_f_pointer(y_i0_ptr, y_i0, [ncols])

    do j = 1, ncols
      k = len(j)
      if (k < 1) then
        out(j) = cmplx(0._prec, 0._prec, kind=prec)
        cycle
      end if
      do i = 1, k
        call set_inum_i0(z_inum(i), z(i, j), z_i0(i, j))
      end do
      call set_inum_i0(y_inum, y(j), y_i0(j))
      out(j) = G_condensed(m(1:k, j), z_inum(1:k), y_inum, k)
    end do
  end subroutine handyg_g_condensed_batch_i0

end module handyg_capi

