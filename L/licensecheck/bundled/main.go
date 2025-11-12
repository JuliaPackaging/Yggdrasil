package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"github.com/google/licensecheck"

	"log"
	"sync"
	"unsafe"
)

var (
	_licenses []licensecheck.License
	_scanner  *licensecheck.Scanner = nil
	_mu       sync.Mutex
)

//export License
func License(msg *C.char) (**C.char, int, float64) {
    _mu.Lock()
    if len(_licenses) == 0 {
        _mu.Unlock()
        return (**C.char)(nil), 0, 0.0
    }
    scanner := _scanner            // copy pointer under lock
    _mu.Unlock()

    if scanner == nil {
        // shouldn't happen if you keep invariants, but be defensive
        return (**C.char)(nil), 0, 0.0
    }

	bytes := []byte(C.GoString(msg))
	cov := _scanner.Scan(bytes)

    n := len(cov.Match)
    if n == 0 {
        return (**C.char)(nil), 0, cov.Percent
    }
	// Collect IDs from each match into a slice of *C.char
	cArray := C.malloc(C.size_t(len(cov.Match)) * C.size_t(unsafe.Sizeof(uintptr(0))))

	ids := (*[1<<30 - 1]*C.char)(cArray)[0:len(cov.Match)]
	for i, m := range cov.Match {
		ids[i] = C.CString(m.ID)
	}

	return (**C.char)(cArray), len(ids), cov.Percent
}

//export FreeLicenseResult
func FreeLicenseResult(result **C.char, length C.int) {
	if result == nil || length <= 0 {
		return
	}
	// Convert **C.char to a slice so we can index it
	slice := (*[1<<30 - 1]*C.char)(unsafe.Pointer(result))[0:int(length)]
	for i := 0; i < int(length); i++ {
		C.free(unsafe.Pointer(slice[i]))
	}
	C.free(unsafe.Pointer(result))
}

//export ClearLicenseList
func ClearLicenseList() {
	_mu.Lock()
	defer _mu.Unlock()

	_licenses = []licensecheck.License{}
	rebuildScanner()
}

//export ResetToBuiltinLicences
func ResetToBuiltinLicences() {
	_mu.Lock()
	defer _mu.Unlock()

	_licenses = licensecheck.BuiltinLicenses()
	rebuildScanner()
}

//export AddBuiltinLicense
func AddBuiltinLicense(name *C.char) {
	_mu.Lock()
	defer _mu.Unlock()

	sname := C.GoString(name)

	for _, license := range licensecheck.BuiltinLicenses() {
		if license.ID == sname {
			_licenses = append(_licenses, license)
			break
		}
	}
	rebuildScanner()
}

//export AddLicense
func AddLicense(cID *C.char, cLRE *C.char) {
	_mu.Lock()
	defer _mu.Unlock()

	_licenses = append(_licenses, licensecheck.License{
		C.GoString(cID), licensecheck.Unknown, C.GoString(cLRE), ""})
	rebuildScanner()
}

func rebuildScanner() {
	var err any
	_scanner, err = licensecheck.NewScanner(_licenses)
	if err != nil {
		log.Fatal(err)
	}
}

func init() {
	ResetToBuiltinLicences()
}

func main() {}
