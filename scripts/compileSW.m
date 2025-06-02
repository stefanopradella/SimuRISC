function compileSW(NameValueArgs)
% COMPILESW - Compiles the assembler code into ELF file.
%   Syntax:
%       COMPILESW()                                 [Prompts the user for the source file location]
%       COMPILESW('SourceFilePath', 'test.S')       [Uses default linker set in SimuRISC_Environment constants]
%       COMPILESW('SourceFilePath', 'test.S', 'LinkerFilePath' 'myLinker.ld')
    arguments
        NameValueArgs.SourceFilePath (1,1) string = ''
        NameValueArgs.LinkerFilePath (1,1) string = which(SimuRISC_Environment.DEFAULT_LINKER_FILE)
    end

    if strcmp(NameValueArgs.SourceFilePath, "")
        [filename, filepath] = uigetfile('*');
        sourceFilePath = [filepath, filename];
    else
        sourceFilePath = NameValueArgs.SourceFilePath;
    end
    linkerFilePath = NameValueArgs.LinkerFilePath;

    [filePath,fileName,fileExtension]=fileparts(sourceFilePath);

    sourceFilePath = strcat(filePath, filesep, fileName, fileExtension);
    objectFilePath = strcat(filePath, filesep, fileName, '.o');
    elfFilePath = strcat(filePath, filesep, fileName, '.elf');


    [status,cmdout] = system(strcat("riscv64-unknown-elf-as -march=",SimuRISC_Constants.ARCH, " -mabi=", SimuRISC_Constants.ABI, " -o ", objectFilePath," ", sourceFilePath));
    if status ~= 0
        ME = MException('compileSW:assemblerCommandError', ...
            'Error invoking assembler command: %s',cmdout);
    throw(ME)
    end
    [status,cmdout] = system(strcat("riscv64-unknown-elf-ld -o ", elfFilePath, " -T ", linkerFilePath, " -m elf32lriscv -nostdlib --no-relax ", objectFilePath));
    if status ~= 0
        ME = MException('compileSW:objcopyCommandError', ...
            'Error invoking objcopy command: %s',cmdout);
    throw(ME)
    end
end