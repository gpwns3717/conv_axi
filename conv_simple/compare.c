#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[])
{
    printf("%s\t%s\n\r", argv[1], argv[2]);
    FILE *fp1 = fopen(argv[1], "r");
    FILE *fp2 = fopen(argv[2], "r");
    int  value1, value2;
    int  ret1, ret2;

    if (fp1 == NULL || fp2 == NULL) {
        printf("error!!\n\r");
        return -1;
    }

    while (1) {
        ret1 = fscanf(fp1, "%d\n", &value1);
        ret2 = fscanf(fp2, "%d\n", &value2);
        if (ret1 == EOF) {
            if (ret2 == EOF) {
                printf("same\n\r");
                break;
            }
            else {
                printf("diff\n\r");
                break;
            }
        }
        else if (ret2 == EOF) {
            if (ret1 == EOF) {
                printf("same\n\r");
                break;
            }
            else {
                printf("diff\n\r");
                break;
            }
        }

        if (value1 == value2) 
            printf("%d\t%d\t%s\n\r", value1, value2, "same");
        else
            printf("%d\t%d\t%s\n\r", value1, value2, "diff");

    }

    fclose(fp1);
    fclose(fp2);
    return 0;
}
