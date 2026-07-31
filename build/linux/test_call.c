#include <stdio.h>
#include "libmylib.h"

int main() {
    int sum = Add(3, 4);
    printf("Add(3, 4) = %d\n", sum);

    char* greeting = Greet("Hideaki");
    printf("Greet(\"Hideaki\") = %s\n", greeting);
    FreeString(greeting);

    return 0;
}
