#include <stdio.h>
#include "libfoo.h"

int main(void) {
    double two = foo(2.0);
    printf("foo(2.0) == %.1f\n", two);
    return 0;
}
