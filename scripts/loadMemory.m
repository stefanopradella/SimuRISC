function [memoryData, memoryHexWords]= loadMemory(varargin)
%  LOADMEMORY - Reads a binary memory file and returns the memory data variable.
%
%   memData = LOADMEMORY() Prompts the user for the binary file location
%   memData = LOADMEMORY(filepath) Loads the file specified in the filepath variable
%   [memData, hexDataWords] = LOADMEMORY(___) Also returns the memory data in hexadecimal

    if nargin == 0
        [filename, filepath] = uigetfile('*');
        memoryFilePath = [filepath, filename];
    else
        memoryFilePath = varargin{1};
    end

    fileId = fopen(memoryFilePath);
    memoryData = fread(fileId);
    fclose(fileId);

    memoryData = fliplr(reshape(memoryData', 4, numel(memoryData)/4)');
    
    memoryHexWords = strings(size(memoryData, 1), 1);
    for iWord = 1:size(memoryData, 1)
        hexWord = '';
        for iWordByte = 1:size(memoryData, 2)
            hexWord = [hexWord, dec2hex(memoryData(iWord,iWordByte), 2)];
        end
        memoryHexWords(iWord) = string(hexWord);
    end
end