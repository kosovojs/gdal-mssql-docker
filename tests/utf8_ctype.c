#include <assert.h>
#include <iconv.h>
#include <langinfo.h>
#include <locale.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    assert(argc == 2);
    const int baseline = strcmp(argv[1], "C") == 0;
    assert(strcmp(setlocale(LC_NUMERIC, NULL), "C") == 0);
    char number[32];
    snprintf(number, sizeof(number), "%.2f", 1234.5);
    assert(strcmp(number, "1234.50") == 0);

    if (baseline) {
        assert(strcmp(setlocale(LC_CTYPE, NULL), "C") == 0);
    } else {
        assert(strcmp(nl_langinfo(CODESET), "UTF-8") == 0);
        /* Same locale-derived conversion used for narrow ODBC query text. */
        char input[] = "R\xc4\xabga";
        const unsigned char expected[] = {0x52, 0, 0x2b, 1, 0x67, 0, 0x61, 0};
        char output[32];
        char *in = input;
        char *out = output;
        size_t in_left = strlen(input);
        size_t out_left = sizeof(output);
        iconv_t converter = iconv_open("UTF-16LE", nl_langinfo(CODESET));
        assert(converter != (iconv_t)-1);
        assert(iconv(converter, &in, &in_left, &out, &out_left) != (size_t)-1);
        assert(in_left == 0);
        assert(sizeof(output) - out_left == sizeof(expected));
        assert(memcmp(output, expected, sizeof(expected)) == 0);
        assert(iconv_close(converter) == 0);
    }
    puts(baseline ? "baseline: C locale" : "UTF-8 query conversion; numeric locale unchanged");
    return 0;
}
