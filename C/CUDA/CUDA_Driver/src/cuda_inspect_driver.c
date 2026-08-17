/* Script to check the usability of CUDA drivers. */

/* On glibc-based Linux, dlinfo/RTLD_DI_LINKMAP require _GNU_SOURCE. The build
 * script passes -D_GNU_SOURCE in CFLAGS. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
  #include <windows.h>

  typedef HMODULE lib_handle_t;
  static lib_handle_t lib_open(const char *path) {
      return LoadLibraryA(path);
  }
  static void *lib_sym(lib_handle_t h, const char *name) {
      return (void *)GetProcAddress(h, name);
  }
  static int lib_path(lib_handle_t h, char *out, size_t out_size) {
      DWORD n = GetModuleFileNameA(h, out, (DWORD)out_size);
      if (n == 0 || n >= out_size) {
          return -1;
      }
      return 0;
  }
#else
  #include <dlfcn.h>
  #include <link.h>

  /* These match the flags of Libdl.dlopen():
   * https://docs.julialang.org/en/v1/stdlib/Libdl/#Base.Libc.Libdl.dlopen */
  #define DLOPEN_FLAGS (RTLD_LAZY | RTLD_DEEPBIND | RTLD_LOCAL)

  typedef void *lib_handle_t;
  static lib_handle_t lib_open(const char *path) {
      return dlopen(path, DLOPEN_FLAGS);
  }
  static void *lib_sym(lib_handle_t h, const char *name) {
      return dlsym(h, name);
  }
  static int lib_path(lib_handle_t h, char *out, size_t out_size) {
      struct link_map *lm = NULL;
      if (dlinfo(h, RTLD_DI_LINKMAP, &lm) != 0 || lm == NULL || lm->l_name == NULL) {
          return -1;
      }
      strncpy(out, lm->l_name, out_size - 1);
      out[out_size - 1] = '\0';
      return 0;
  }
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
        if (lib_open(argv[i]) == NULL) {
            return -1;
        }
    }

    lib_handle_t library_handle = lib_open(driver);
    if (library_handle == NULL) {
        return -1;
    }

    /* Report the resolved absolute path of the loaded driver, so that callers
     * can register it as a file dependency (e.g. for cache invalidation) without
     * having to dlopen the library themselves. */
    char path_buf[4096];
    if (lib_path(library_handle, path_buf, sizeof(path_buf)) != 0) {
        return -1;
    }
    printf("%s\n", path_buf);

    cuInit_t cuInit = (cuInit_t)lib_sym(library_handle, "cuInit");
    if (cuInit == NULL) {
        return -2;
    }
    int status = cuInit(0);
    if (status != 0) {
        return -2;
    }

    cuDriverGetVersion_t cuDriverGetVersion = (cuDriverGetVersion_t)lib_sym(library_handle, "cuDriverGetVersion");
    if (cuDriverGetVersion == NULL) {
        return -3;
    }
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
        cuDeviceGetCount_t cuDeviceGetCount = (cuDeviceGetCount_t)lib_sym(library_handle, "cuDeviceGetCount");
        if (cuDeviceGetCount == NULL) {
            return -4;
        }
        int device_count;
        status = cuDeviceGetCount(&device_count);
        if (status != 0) {
            return -4;
        }

        cuDeviceGet_t cuDeviceGet = (cuDeviceGet_t)lib_sym(library_handle, "cuDeviceGet");
        cuDeviceGetAttribute_t cuDeviceGetAttribute = (cuDeviceGetAttribute_t)lib_sym(library_handle, "cuDeviceGetAttribute");
        if (cuDeviceGet == NULL || cuDeviceGetAttribute == NULL) {
            return -5;
        }

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
