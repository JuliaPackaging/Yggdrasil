package main

import "C"

import (
    "github.com/google/uuid"
    "unsafe"
    // "fmt"
    "context"
    "log"
    "go-hep.org/x/hep/xrootd"
    "go-hep.org/x/hep/xrootd/xrdfs"
)

var _FILES = make(map[*C.char]xrdfs.File)

//export Open
func Open(_baseurl *C.char, _filepath *C.char, _username *C.char) *C.char {
    baseurl  := C.GoString(_baseurl)
    filepath := C.GoString(_filepath)
    username := C.GoString(_username)
    ctx := context.Background()
    client, _ := xrootd.NewClient(ctx, baseurl, username)
    file, err := client.FS().Open(ctx, filepath, xrdfs.OpenModeOwnerRead, xrdfs.OpenOptionsOpenRead)
    if err != nil {
        log.Fatal(err)
    }
    _id := C.CString(uuid.NewString())
    _FILES[_id] = file
    return _id
}

//export Close
func Close(_id *C.char){
    ctx := context.Background()
    file, found := _FILES[_id]

    if !found {
        log.Fatal("can't find id to close")
    }
    if err := file.Close(ctx); err != nil {
        log.Fatal(err)
    }
}

//export ReadAt
func ReadAt(res unsafe.Pointer, _id *C.char, NBytes C.int, offset C.int) {
// func ReadAt(res *C.char, _id *C.char, NBytes C.int, offset C.int) **C.char {
    file := _FILES[_id]
    // res := C.malloc(C.ulong(NBytes))
    data := unsafe.Slice((*byte)(res), int64(NBytes));
    _, err := file.ReadAt(data, int64(offset))
    if err != nil {
        log.Fatal(err)
    }
    // return (**C.char)(res)
}

func main() {}
