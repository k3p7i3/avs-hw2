#include "stdio.h"
#include "stdlib.h"
#include "time.h"
#include "string.h"

char TIME_FLAG = 0; // flag to know if we should measure time

char *read_string(char *file_name) {
    // read and return string from file_name

    FILE *istream = fopen(file_name, "r");

    // calculate size of file to malloc buffer
    fseek(istream, 0, SEEK_END);
    size_t istream_size = ftell(istream);
    fseek(istream, 0, SEEK_SET);

    char *str = malloc(istream_size + 1);

    //  read the string
    for (size_t i = 0; i < istream_size; ++i) {
        str[i] = fgetc(istream);
    }
    //  determine the end of string
    str[istream_size] = 0;

    fclose(istream);
    return str;
}

void write_string(char *str, char *file_name) {
    FILE *ostream = fopen(file_name, "w");
    fprintf(ostream, "%s", str);
    fclose(ostream);
}

char *random_string(size_t size) {
    // generate and return random string
    char *str = malloc(size + 1);
    srand(time(NULL));

    for (size_t i = 0; i < size; ++i) {
        // generate random char value from 32 to 126 (these symbols are pictured correctly on the txt format)
        str[i] = rand() % (127 - 32) + 32;
    }
    // end of string
    str[size] = 0;
    return str;
}

unsigned int count_uppercase(char *str) {
    unsigned int count = 0;

    //  while str isn't the end of the string
    while (*str) {
        // if *str is uppercase
        if ('A' <= *str && *str <= 'Z') {
            ++count;
        }
        ++str;
    }

    return count;
}

unsigned int count_lowercase(char *str) {
    unsigned int count = 0;

    //  while str isn't the end of the string
    while (*str) {
        // if *str is lowercase
        if ('a' <= *str && *str <= 'z') {
            ++count;
        }
        ++str;
    }

    return count;
}

void write_result(unsigned int uppercase, unsigned int lowercase, char *file_name) {
    FILE *ostream = fopen(file_name, "w");

    //  write the numbers of upper and lowercase letters
    fprintf(ostream, "Number of uppercase letters: %u\n", uppercase);
    fprintf(ostream, "Number of lowercase letters: %u\n", lowercase);

    fclose(ostream);
}

void free_memory(char *str) {
    free(str);
}

int main(int argc, char **argv) {
    //  get all options and arguments from cmd
    if (argc < 3) {
        fprintf(stderr, "2 argements excepted - input file and output file");
        exit(1);
    }
    char *input = argv[1];
    char *output = argv[2];

    size_t random_size = 0; // size for random generated string (if size == 0 then just read str from input)
    //  handle options
    for (size_t i = 3; i < argc; ++i)
    {
        if (!strcmp(argv[i], "--rand")) { // option to generate a random array
            if (i + 1 < argc) {
                random_size = atoi(argv[i + 1]); // get size of generated array
            }
            if (!random_size) { // if there's no argument, then default size = 1000
                random_size = 1000;
            }
        }

        if (!strcmp(argv[i], "--time")) { // option to measure time
            TIME_FLAG = 1;
        }
    }

    //  read or generate the string
    char *string = 0;
    if (random_size) {
        string = random_string(random_size);
        write_string(string, input); // output the generated string so we can test the programm
    } else {
        string = read_string(input);
    }

    clock_t time_start, time_end; // measure time for calculating the results
    time_start = clock();

    unsigned int uppercase = count_uppercase(string);
    unsigned int lowercase = count_lowercase(string);

    // cycle if we have to measure time
    if (TIME_FLAG) {
        for (int i = 0; i < 500; ++i) {
            count_uppercase(string);
            count_lowercase(string);
        }
    }

    time_end = clock();

    write_result(uppercase, lowercase, output); // write the results into output

    if (TIME_FLAG) {    // print time
        double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;
        printf("Process time:%f seconds\n", cpu_time_used);
    }

    // free memory
    free_memory(string);
    return 0;
}