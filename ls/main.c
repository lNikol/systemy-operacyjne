#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <locale.h>
#include <langinfo.h>
#include <limits.h>
#include <stdbool.h>

const char *sperm(mode_t mode) {
    static char perms[11];
    strcpy(perms, "----------");

    // Typ pliku
    if (S_ISDIR(mode)) perms[0] = 'd';
    if (S_ISCHR(mode)) perms[0] = 'c';
    if (S_ISBLK(mode)) perms[0] = 'b';
    if (S_ISLNK(mode)) perms[0] = 'l';
    if (S_ISFIFO(mode)) perms[0] = 'p';
    if (S_ISSOCK(mode)) perms[0] = 's';

    // Prawa użytkownika
    if (mode & S_IRUSR) perms[1] = 'r';
    if (mode & S_IWUSR) perms[2] = 'w';
    if (mode & S_IXUSR) perms[3] = 'x';

    // Prawa grupy
    if (mode & S_IRGRP) perms[4] = 'r';
    if (mode & S_IWGRP) perms[5] = 'w';
    if (mode & S_IXGRP) perms[6] = 'x';

    // Prawa innych
    if (mode & S_IROTH) perms[7] = 'r';
    if (mode & S_IWOTH) perms[8] = 'w';
    if (mode & S_IXOTH) perms[9] = 'x';

    return perms;
}

void print_size(off_t size, bool human_readable) {
    // pokazywanie rozmiaru
    if (human_readable) {
        char suffixes[] = {'B', 'K', 'M', 'G', 'T'};
        int i = 0;
        double dsize = size;
        while (dsize >= 1024 && i < sizeof(suffixes) - 1) {
            dsize /= 1024;
            i++;
        }
        printf(" %4.1f%c", dsize, suffixes[i]);
    } else {
        printf(" %ld", size);
    }
}

void list_directory(const char *directory, bool long_format, bool recursive, bool show_hidden, bool human_readable, bool show_inode) {
    DIR *pDIR;
    struct dirent *pDirEnt;
    struct passwd *pwd;
    struct group *grp;
    struct tm *tm;
    char datestring[256];
    char path[PATH_MAX];
    struct stat statbuf;

    pDIR = opendir(directory);
    if (pDIR == NULL) {
        fprintf(stderr, "%s %d: opendir() failed (%s)\n", __FILE__, __LINE__, strerror(errno));
        exit(-1);
    }

    printf("\nDirectory: %s\n", directory);

    while ((pDirEnt = readdir(pDIR)) != NULL) {
        if (!show_hidden && pDirEnt->d_name[0] == '.') {
            continue;
        }

        snprintf(path, sizeof(path), "%s/%s", directory, pDirEnt->d_name);

        if (stat(path, &statbuf) == -1) {
            fprintf(stderr, "Failed to stat file: %s (%s)\n", path, strerror(errno));
            continue;
        }

        if (long_format) {
            if (show_inode) {
                // inode
                printf("%ld ", pDirEnt->d_ino);
            }
            // prawa dostępu
            printf("%s", sperm(statbuf.st_mode));
            // liczba dowiązań
            printf(" %ld", statbuf.st_nlink);
            // właściciel pliku/katalogu
            if ((pwd = getpwuid(statbuf.st_uid)) != NULL)
                printf(" %-8.8s", pwd->pw_name);
            else
                printf(" %-8d", statbuf.st_uid);
            // wyświetlanie nazwy grupy właściciela pliku/katalogu
            if ((grp = getgrgid(statbuf.st_gid)) != NULL)
                printf(" %-8.8s", grp->gr_name);
            else
                printf(" %-8d", statbuf.st_gid);
        }

        print_size(statbuf.st_size, human_readable);

        tm = localtime(&statbuf.st_mtime);
        strftime(datestring, sizeof(datestring), "%Y-%m-%d %H:%M", tm);
        printf(" %s %s\n", datestring, pDirEnt->d_name);

        if (recursive && S_ISDIR(statbuf.st_mode) && strcmp(pDirEnt->d_name, ".") != 0 && strcmp(pDirEnt->d_name, "..") != 0) {
            // jeśli z podkatalogami i rekurencyjna, to rób to w kółko
            list_directory(path, long_format, recursive, show_hidden, human_readable, show_inode);
        }
    }

    closedir(pDIR);
}

int main(int argc, char *argv[]) {
    const char *directory = ".";
    bool long_format = false;
    bool recursive = false;
    bool show_hidden = false;
    bool human_readable = false;
    bool show_inode = false;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-l") == 0) {
            long_format = true;
        } else if (strcmp(argv[i], "-R") == 0) {
            long_format = true;
            recursive = true;
        } else if (strcmp(argv[i], "-a") == 0) {
            show_hidden = true;
        } else if (strcmp(argv[i], "-h") == 0) {
            human_readable = true;
        } else if (strcmp(argv[i], "-i") == 0) {
            show_inode = true;
        } else {
            directory = argv[i];
        }
    }

    list_directory(directory, long_format, recursive, show_hidden, human_readable, show_inode);

    // wynik:
    // inode prawa liczba_dowiązań użytkownik grupa_użytkownika rozmiar kiedy_został_utworzony nazwa

    return 0;
}
