#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

void randomName(char* filename, int length) {
    const char charset[] = "abcdefghijklmnopqrstuvwxyz";
    for (int i = 0; i < length; i++) {
        int index = rand() % (sizeof(charset) - 1);
        filename[i] = charset[index];
    }
    filename[length] = '\0';
}

int main() {
    char originalFileName[MAX_PATH] = "original_file.txt";
    char tempFileName[MAX_PATH];
    char finalFileName[MAX_PATH] = "start.bat";
    HANDLE originalFileHandle, tempFileHandle, finalFileHandle;
    LARGE_INTEGER originalFileSize;
    PVOID mappedView;
    SYSTEMTIME systemTime;
    FILETIME fileTime;
    ULARGE_INTEGER largeInteger;
    DWORD bytesRead, bytesWritten;
    BYTE randomByte;

    GetSystemTime(&systemTime);
    SystemTimeToFileTime(&systemTime, &fileTime);
    largeInteger.LowPart = fileTime.dwLowDateTime;
    largeInteger.HighPart = fileTime.dwHighDateTime;
    srand(largeInteger.QuadPart);

    randomName(tempFileName, 8);
    strcat(tempFileName, ".tmp");

    DeleteFile(finalFileName);

    if (!CopyFile(originalFileName, tempFileName, FALSE)) {
        printf("Failed to copy file.\n");
        return 1;
    }

    originalFileHandle = CreateFile(originalFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (originalFileHandle == INVALID_HANDLE_VALUE) {
        printf("Failed to open original file.\n");
        return 1;
    }

    GetFileSizeEx(originalFileHandle, &originalFileSize);

    tempFileHandle = CreateFileMapping(tempFileName, NULL, PAGE_READWRITE, 0, 0, NULL);
    if (tempFileHandle == NULL) {
        printf("Failed to create file mapping.\n");
        CloseHandle(originalFileHandle);
        return 1;
    }

    mappedView = MapViewOfFile(tempFileHandle, FILE_MAP_WRITE, 0, 0, 0);
    if (mappedView == NULL) {
        printf("Failed to map view of file.\n");
        CloseHandle(tempFileHandle);
        CloseHandle(originalFileHandle);
        return 1;
    }

    BYTE* finalFileData = (BYTE*)malloc(originalFileSize.LowPart + 0x120000);
    if (finalFileData == NULL) {
        printf("Failed to allocate memory.\n");
        UnmapViewOfFile(mappedView);
        CloseHandle(tempFileHandle);
        CloseHandle(originalFileHandle);
        return 1;
    }

    BYTE* finalFilePointer = finalFileData;
    const char compainStart[] = "copy ";
    memcpy(finalFilePointer, compainStart, sizeof(compainStart) - 1);
    finalFilePointer += sizeof(compainStart) - 1;

    while (originalFileSize.QuadPart > 0) {
        randomName(tempFileName, 8);

        tempFileHandle = CreateFile(tempFileName, GENERIC_READ | GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        if (tempFileHandle == INVALID_HANDLE_VALUE) {
            printf("Failed to create new file.\n");
            free(finalFileData);
            UnmapViewOfFile(mappedView);
            CloseHandle(tempFileHandle);
            CloseHandle(originalFileHandle);
            return 1;
        }

        int chunkSize = rand() % 6 + 3;
        int bytesToWrite = (chunkSize < originalFileSize.LowPart) ? chunkSize : originalFileSize.LowPart;
        ReadFile(originalFileHandle, finalFilePointer, bytesToWrite, &bytesRead, NULL);
        WriteFile(tempFileHandle, finalFilePointer, bytesRead, &bytesWritten, NULL);
        originalFileSize.QuadPart -= bytesRead;
        finalFilePointer += bytesRead;

        CloseHandle(tempFileHandle);
    }

    finalFileHandle = CreateFile(finalFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (finalFileHandle == INVALID_HANDLE_VALUE) {
        printf("Failed to create final file.\n");
        free(finalFileData);
        UnmapViewOfFile(mappedView);
        CloseHandle(originalFileHandle);
        return 1;
    }

    WriteFile(finalFileHandle, finalFileData, finalFilePointer - finalFileData, &bytesWritten, NULL);

    free(finalFileData);
    UnmapViewOfFile(mappedView);
    CloseHandle(tempFileHandle);
    CloseHandle(originalFileHandle);
    CloseHandle(finalFileHandle);
    DeleteFile(tempFileName);

    return 0;
}
