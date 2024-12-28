package main

import "C"

import (
    "github.com/google/uuid"
    "unsafe"
    "fmt"
    "context"
    // "log"
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
    _id := C.CString(uuid.NewString())
    if err != nil {
        fmt.Println(err)
        _id = C.CString("error")
        return _id
    }
    _FILES[_id] = file
    return _id
}

//export Close
func Close(_id *C.char){
    ctx := context.Background()
    file, found := _FILES[_id]

    if !found {
        fmt.Println("can't find id to close")
    }
    if err := file.Close(ctx); err != nil {
        fmt.Println(err)
    }
}

//export Size
func Size(_id *C.char) C.long {
    ctx := context.Background()
    file, _ := _FILES[_id]
    info, err := file.Stat(ctx)

    if err != nil {
        fmt.Println(err)
    }
    return C.long(info.EntrySize)
}

//export ReadAt
func ReadAt(res unsafe.Pointer, _id *C.char, NBytes C.long, offset C.long) {
    file := _FILES[_id]
    data := unsafe.Slice((*byte)(res), int64(NBytes));
    // data := (*(*[2147483647]byte)(res))[:NBytes]
    _, err := file.ReadAt(data, int64(offset))
    if err != nil {
        fmt.Println(err)
    }
}

func main() {}
