/* Stub: windows.applicationmodel.core.h is unavailable in this mingw-w64
 * toolchain shard, so real UWP package enumeration is unsupported here.
 * See gwin32packageparser.h for the expected signature. */
#include "gwin32packageparser.h"

#ifdef G_PLATFORM_WIN32

gboolean
g_win32_package_parser_enum_packages (GWin32PackageParserCallback callback,
                                       gpointer                    user_data,
                                       GError                    **error)
{
  g_set_error_literal (error,
                       G_IO_ERROR,
                       G_IO_ERROR_NOT_SUPPORTED,
                       "UWP package enumeration is not supported on this build");
  return FALSE;
}

#endif /* G_PLATFORM_WIN32 */
