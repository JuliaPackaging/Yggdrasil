/* Script to check the usability of CUDA drivers. */

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// These match the flags of Libdl.dlopen():
// https://docs.julialang.org/en/v1/stdlib/Libdl/#Base.Libc.Libdl.dlopen
#ifdef __APPLE__
#define DLOPEN_FLAGS RTLD_LAZY | RTLD_DEEPBIND | RTLD_GLOBAL
#else
#define DLOPEN_FLAGS RTLD_LAZY | RTLD_DEEPBIND | RTLD_LOCAL
#endif

const int DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR = 75;
const int DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR = 76;

typedef int (*cuInit_t)(unsigned int);
typedef int (*cuDriverGetVersion_t)(int *);
typedef int (*cuDeviceGetCount_t)(int *);
typedef int (*cuDeviceGet_t)(int *, int);
typedef int (*cuDeviceGetAttribute_t)(int *, unsigned int, int);


int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <driver> <inspect_devices> [deps...]\n", argv[0]);
        return -1;
    }

    const char *driver = argv[1];
    int inspect_devices = (strcmp(argv[2], "true") == 0 || strcmp(argv[2], "1") == 0);

    for (int i = 3; i < argc; i++) {
        if (dlopen(argv[i], DLOPEN_FLAGS) == NULL) {
            return -1;
        }
    }

    void *library_handle = dlopen(driver, DLOPEN_FLAGS);
    if (library_handle == NULL) {
        return -1;
    }

    cuInit_t cuInit = (cuInit_t)dlsym(library_handle, "cuInit");
    int status = cuInit(0);
    if (status != 0) {
        return -2;
    }

    cuDriverGetVersion_t cuDriverGetVersion = (cuDriverGetVersion_t)dlsym(library_handle, "cuDriverGetVersion");
    int version;
    status = cuDriverGetVersion(&version);
    if (status != 0) {
        return -3;
    }
    int major = version / 1000;
    int ver = version % 1000;
    int minor = ver / 10;
    int patch = ver % 10;
    printf("%d.%d.%d\n", major, minor, patch);

    if (inspect_devices) {
        cuDeviceGetCount_t cuDeviceGetCount = (cuDeviceGetCount_t)dlsym(library_handle, "cuDeviceGetCount");
        int device_count;
        status = cuDeviceGetCount(&device_count);
        if (status != 0) {
            return -4;
        }

        cuDeviceGet_t cuDeviceGet = (cuDeviceGet_t)dlsym(library_handle, "cuDeviceGet");
        cuDeviceGetAttribute_t cuDeviceGetAttribute = (cuDeviceGetAttribute_t)dlsym(library_handle, "cuDeviceGetAttribute");

        for (int i = 0; i < device_count; i++) {
            int device = -1;
            status = cuDeviceGet(&device, i);
            if (status != 0) {
                return -5;
            }

            int dev_major;
            status = cuDeviceGetAttribute(&dev_major, DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR, device);
            if (status != 0) {
                return -6;
            }

            int dev_minor;
            status = cuDeviceGetAttribute(&dev_minor, DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR, device);
            if (status != 0) {
                return -7;
            }

            printf("%d.%d\n", dev_major, dev_minor);
        }
    }

    return 0;
}
