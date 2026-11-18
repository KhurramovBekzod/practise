#include <fcntl.h>
#include <unistd.h>

#define BUFFER_SIZE 4096

static void write_all(int fd, const char *buffer, ssize_t count)
{
    ssize_t total_written = 0;

    while (total_written < count) {
        ssize_t bytes_written = write(fd, buffer + total_written, count - total_written);

        if (bytes_written <= 0) {
            return;
        }

        total_written += bytes_written;
    }
}

int main(int argc, char *argv[])
{
    int file_count = argc - 1;
    int file_descriptors[file_count > 0 ? file_count : 1];
    char buffer[BUFFER_SIZE];
    ssize_t bytes_read;

    for (int i = 0; i < file_count; i++) {
        file_descriptors[i] = open(argv[i + 1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    }

    while ((bytes_read = read(STDIN_FILENO, buffer, BUFFER_SIZE)) > 0) {
        write_all(STDOUT_FILENO, buffer, bytes_read);

        for (int i = 0; i < file_count; i++) {
            write_all(file_descriptors[i], buffer, bytes_read);
        }
    }

    for (int i = 0; i < file_count; i++) {
        close(file_descriptors[i]);
    }

    return 0;
}
