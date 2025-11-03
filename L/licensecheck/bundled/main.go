package main

import "C"
import (
	"github.com/google/licensecheck"

	"unsafe"
	"log"
)

var _licenses []licensecheck.License;
var _scanner *licensecheck.Scanner = nil;

//export License
func License(msg *C.char) (**C.char, int, float64) {
	bytes := []byte(C.GoString(msg))
	cov := _scanner.Scan(bytes)

	// https://stackoverflow.com/a/41493208
	cArray := C.malloc(C.size_t(len(cov.Match)) * C.size_t(unsafe.Sizeof(uintptr(0))))
	// mimic https://github.com/docker/docker-credential-helpers/pull/61
	a := (*[(1 << 29) - 1]*C.char)(cArray)

	for idx, m := range cov.Match {
		a[idx] = C.CString(m.ID)
	}

	return (**C.char)(cArray), len(cov.Match), cov.Percent
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
func AddLicense(cID *C.char, /*cType *C.char,*/ cLRE *C.char, cURL *C.char) {
	// type, err := licensecheck.ParseType(C.GoString(cType))
	// if err != nil {
	// 	type = licensecheck.Unknown
	// }
	_licenses = append(_licenses, licensecheck.License{
		C.GoString(cID), licensecheck.Unknown, C.GoString(cLRE), C.GoString(cURL)})
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
