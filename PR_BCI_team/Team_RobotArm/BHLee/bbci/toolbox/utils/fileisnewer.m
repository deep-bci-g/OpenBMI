function erg= fileisnewer(file1, file2)%FILEISNEWER - Check whether one file is newer than another one%%BOOL= fileisnewer(FILE1, FILE2)%% BOOL is true if FILE1 is newer than FILE2, false otherwise.e1= dir(file1);e2= dir(file2);if (datenum([e1.date]) > datenum([e2.date]))  erg = true;else  erg = false;end