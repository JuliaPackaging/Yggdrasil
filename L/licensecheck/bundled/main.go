package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"github.com/google/licensecheck"

	"unsafe"
	"log"
)

var _licenses []licensecheck.License;
var _scanner *licensecheck.Scanner = nil;
var _result unsafe.Pointer = nil;

//export License
func License(msg *C.char) (**C.char, int, float64) {

	if len(_licenses) == 0 {
		// _scanner do now work if there are no licenses, work-around such case
		return (**C.char)(nil), 0, 0.0
	}

	bytes := []byte(C.GoString(msg))
	cov := _scanner.Scan(bytes)

	// assuming Julia made a copy of the result, we can safely free prev. buffer and populate a new one
	if _result != nil {
		C.free(_result)
	}
	// https://stackoverflow.com/a/41493208
	_result := C.malloc(C.size_t(len(cov.Match)) * C.size_t(unsafe.Sizeof(uintptr(0))))
	// mimic https://github.com/docker/docker-credential-helpers/pull/61
	a := (*[(1 << 29) - 1]*C.char)(_result)

	for idx, m := range cov.Match {
		a[idx] = C.CString(m.ID)
	}

	return (**C.char)(_result), len(cov.Match), cov.Percent
}

//export ClearLicenseList
func ClearLicenseList() {
	_licenses = []licensecheck.License{};
	rebuildScanner()
}

//export ResetToBuiltinLicences
func ResetToBuiltinLicences() {
	_licenses = licensecheck.BuiltinLicenses()
	rebuildScanner()
}

//export AddBuiltinLicense
func AddBuiltinLicense(name *C.char) {
	sname := C.GoString(name)

	for _, license := range licensecheck.BuiltinLicenses() {
        if license.ID == sname {
            _licenses = append(_licenses, license)
			break;
        }
    }
	rebuildScanner()
}

//export AddLicense
func AddLicense(cID *C.char, cLRE *C.char) {
	_licenses = append(_licenses, licensecheck.License{
		C.GoString(cID), licensecheck.Unknown, C.GoString(cLRE), ""})
	rebuildScanner()
}

func rebuildScanner() {
	var err any;
	_scanner, err = licensecheck.NewScanner(_licenses)
	if err != nil {
		log.Fatal(err)
	}
}

func init() {
	ResetToBuiltinLicences()
}

func main() {}
