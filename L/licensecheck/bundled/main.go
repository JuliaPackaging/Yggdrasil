package main

import "C"
import (
    "github.com/google/licensecheck"

    "unsafe"
)

//export License
func License(msg *C.char) (**C.char, int, float64) {
    bytes := []byte(C.GoString(msg))
    cov := licensecheck.Scan(bytes)

    // https://stackoverflow.com/a/41493208
    cArray := C.malloc(C.size_t(len(cov.Match)) * C.size_t(unsafe.Sizeof(uintptr(0))))
    a := (*[1<<30 - 1]*C.char)(cArray)

    for idx, m := range cov.Match {
        a[idx] = C.CString(m.ID)
    }
    
    return (**C.char)(cArray), len(cov.Match), cov.Percent
}

func main() {}
