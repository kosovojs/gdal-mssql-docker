/* GDAL tools never call setlocale(); msodbcsql converts narrow SQL text using
 * the process LC_CTYPE. Leave LC_NUMERIC and all other categories unchanged. */
#include <locale.h>

__attribute__((constructor)) static void utf8_ctype(void)
{
    setlocale(LC_CTYPE, "C.UTF-8");
}
