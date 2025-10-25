#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Try harder! Usage: %s <password>\n", argv[0]);
        return 1;
    }

    // Hidden password: "IUST-CE-1404" (XORed with 0xAA)
    unsigned char hidden[] = {
        0xE3, 0xFF, 0xF9, 0xFE, 0x87, 0xE9,
        0xEF, 0x87, 0x9B, 0x9E, 0x9A, 0x9E,
        0x00  // ← null terminator!
    };
    int len = sizeof(hidden) / sizeof(hidden[0]) - 1;
    for (int i = 0; i < len; ++i) hidden[i] ^= 0xAA;

    if (strcmp(argv[1], (char*)hidden) == 0) {
        puts("Access granted! You cracked it!");
    } else {
        puts("Access denied. Keep reversing!");
    }
    return 0;
}
