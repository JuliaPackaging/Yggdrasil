//! C ABI for PtrHash with `u64` keys.
use ptr_hash::{DefaultPtrHash, PtrHashParams};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::slice;

pub struct PtrHashHandle(DefaultPtrHash);

/// Build a minimal perfect hash function for `n` distinct keys.
/// Returns NULL if construction fails.
#[no_mangle]
pub unsafe extern "C" fn ptrhash_new(keys: *const u64, n: usize) -> *mut PtrHashHandle {
    let keys = slice::from_raw_parts(keys, n);
    match catch_unwind(AssertUnwindSafe(|| {
        DefaultPtrHash::try_new(keys, PtrHashParams::default())
    })) {
        Ok(Some(h)) => Box::into_raw(Box::new(PtrHashHandle(h))),
        _ => std::ptr::null_mut(),
    }
}

/// Free a handle returned by `ptrhash_new`.
#[no_mangle]
pub unsafe extern "C" fn ptrhash_free(h: *mut PtrHashHandle) {
    if !h.is_null() {
        drop(Box::from_raw(h));
    }
}

/// Number of keys.
#[no_mangle]
pub unsafe extern "C" fn ptrhash_len(h: *const PtrHashHandle) -> usize {
    (*h).0.n()
}

/// Index of `key` in `[0, n)`. Only meaningful for keys the function was built on.
#[no_mangle]
pub unsafe extern "C" fn ptrhash_index(h: *const PtrHashHandle, key: u64) -> usize {
    (*h).0.index(&key)
}

/// Write the indices of `n` keys to `out`, prefetching ahead.
#[no_mangle]
pub unsafe extern "C" fn ptrhash_index_many(
    h: *const PtrHashHandle,
    keys: *const u64,
    n: usize,
    out: *mut usize,
) {
    let keys = slice::from_raw_parts(keys, n);
    let out = slice::from_raw_parts_mut(out, n);
    // The stream iterator only implements `fold`, so `for_each` rather than `next`.
    let mut j = 0;
    (*h).0.index_stream::<32, _>(keys).for_each(|i| {
        out[j] = i;
        j += 1;
    });
}
