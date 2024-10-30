function compileSW(varargin)
% COMPILESW - Compiles the assembler code into binary code.
%
%   COMPILESW() Prompts the user for thesource file location
%   COMPILESW(filepath) Compiles the file specified in the filepath variable

    if nargin == 0
        [filename, filepath] = uigetfile('*');
        sourceFilePath = [filepath, filename];
    else
        sourceFilePath = varargin{1};
    end

    [filePath,fileName,~]=fileparts(sourceFilePath);

    sourceFilePath = [filepath, filename];
    objectFilePath = [filePath filesep fileName '.o'];
    binaryFilePath = [filePath filesep fileName '.bin'];


    [status,cmdout] = system(['riscv32-unknown-elf-as -o ' objectFilePath ' ' sourceFilePath]);
    if status ~= 0
        ME = MException('compileSW:assemblerCommandError', ...
            'Error invoking assembler command: %s',cmdout);
    throw(ME)
    end
    [status,cmdout] = system(['riscv32-unknown-elf-objcopy -O binary ' objectFilePath ' ' binaryFilePath]);
    if status ~= 0
        ME = MException('compileSW:objcopyCommandError', ...
            'Error invoking objcopy command: %s',cmdout);
    throw(ME)
    end
end