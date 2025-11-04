#![no_std]

// Minimal, deterministic policy demo ABI.
//
// Exported symbol:
//   validate(entry_ptr, entry_len, state_ptr, state_len, out_ptr, out_len_ptr) -> u32
//
// Semantics:
//   - Returns 0 to indicate acceptance; non-zero for rejection.
//   - Writes a short UTF-8 message into [out_ptr, out_ptr+*out_len_ptr) if non-null.
//   - This demo accepts iff entry_len is even AND state_len is even; otherwise rejects.
//   - Purely deterministic: no clock, randomness, or host I/O.

#[no_mangle]
pub extern "C" fn validate(
    _entry_ptr: *const u8,
    entry_len: usize,
    _state_ptr: *const u8,
    state_len: usize,
    out_ptr: *mut u8,
    out_len_ptr: *mut usize,
    ) -> u32 {
    let accept = (entry_len & 1) == 0 && (state_len & 1) == 0;
    let msg = if accept { b"ACCEPT\n" } else { b"REJECT\n" };

    unsafe {
        if !out_ptr.is_null() && !out_len_ptr.is_null() {
            let mut n = core::ptr::read(out_len_ptr);
            if n > msg.len() { n = msg.len(); }
            core::ptr::copy_nonoverlapping(msg.as_ptr(), out_ptr, n);
            core::ptr::write(out_len_ptr, n);
        }
    }
    if accept { 0 } else { 1 }
}

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
