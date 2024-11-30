function simulationOutput = whisperSimulateElf(NameValueArgs)
% WHISPERSIMULATEELF - Simulate Elf file with Whisper and return memory and registers state.
%   Syntax:
%       WHISPERSIMULATEELF()                                   [Prompts the user for the elf file location]
%       WHISPERSIMULATEELF  ('ElfFilePath', 'test.elf')
%       WHISPERSIMULATEELF  ('ElfFilePath', 'test.elf', 'WhisperConfigFilePath', 'customWhisperConfig.cfg')
    arguments
        NameValueArgs.ElfFilePath (1,1) string = ''
        NameValueArgs.WhisperConfigFilePath (1,1) string = which(SimuRISC_Environment.DEFAULT_WHISPER_CONFIG_FILE)
    end

    if strcmp(NameValueArgs.ElfFilePath, "")
        [filename, filepath] = uigetfile('*');
        elfFilePath = [filepath, filename];
    else
        elfFilePath = NameValueArgs.ElfFilePath;
        [filepath, ~] = fileparts(elfFilePath);
    end

    whisperConfigFilePath = NameValueArgs.WhisperConfigFilePath;

    % Get the size of the code section and the offset of the data section
    [~, cmdout] = system(strcat("riscv32-unknown-elf-objdump -h ", elfFilePath));
    cmdout = splitlines(string(cmdout));

    memoryLocations = dictionary();
    for iLine = 1:numel(cmdout)
        if regexp(cmdout(iLine), "\s+\d+\s+\.text\s+")
            lineSplit = split(cmdout(iLine));
            nInstructions = hex2dec(lineSplit(4))/4;                        % TODO parametric instruction length (maybe with a constant)
            textSectionBaseAddr = hex2dec(lineSplit(5));
            memoryLocations(string(textSectionBaseAddr)) = ".text";
        end
        if regexp(cmdout(iLine), "\s+\d+\s+\.data\s+")
            lineSplit = split(cmdout(iLine));
            dataSectionSize = hex2dec(lineSplit(4))/4; 
            dataSectionBaseAddr = hex2dec(lineSplit(5));                    % TODO parametric instruction length (maybe with a constant)
            memoryLocations(string(dataSectionBaseAddr)) = ".data";
        end
    end

    % Simulate elf file the first time to get the number of instructions
    [~, response] = system(strcat("whisper ", elfFilePath, " --configfile ", whisperConfigFilePath));
    responseRows = splitlines(string(response));

    nInstructions = sscanf(responseRows(2), "Retired %d");

    fprintf("Simulating %d instructions...\n", nInstructions)

    % Simulate elf file and save status after last instruction
    % -1 is because the last instruction writes to the .tohost variable to
    % terminate the execution
    system(strcat("whisper ", elfFilePath, " --snapshotperiod ", num2str(nInstructions-1), " --snapshotdir ", ...
        filepath, "/snapshot --configfile ", whisperConfigFilePath));

    % Get used memory blocks
    memoryBlocks = splitlines(string(fileread(strcat(filepath, "/snapshot0/usedblocks"))));
    memoryBlocksInfo = dictionary();
    for iLine = 1:numel(memoryBlocks)
        if memoryBlocks(iLine) ~= ""
            tmp = split(memoryBlocks(iLine));
            memoryBlocksInfo(tmp(1)) = tmp(2);
        end
    end


    % Read register status from snapshot
    registerFile = dictionary();

    registerDumpFile = splitlines(string(fileread(strcat(filepath, "/snapshot0/registers"))));
    for iLine = 1:numel(registerDumpFile)
        if regexp(registerDumpFile(iLine), "x\s\d+\s")
            lineSplit = split(registerDumpFile(iLine));
            registerFile(strcat("x", lineSplit(2))) = lineSplit(3);
        end
    end

    % Read memory status from snapshot
    movefile(strcat(filepath, "/snapshot0/memory"), strcat(filepath, "/snapshot0/memory.gz"))
    system(strcat("gzip -dk ", filepath, "/snapshot0/memory"))
    memoryDump = loadMemory(strcat(filepath, "/snapshot0/memory"));
    
    % Extracting memory dump
    memoryPointer = 1;
    memoryBlocksInfo_keys = memoryBlocksInfo.keys();
    for iBlock = 1:memoryBlocksInfo.numEntries
        memoryOffset = memoryBlocksInfo_keys(iBlock);
        sectionName = memoryLocations(memoryOffset);
        
        switch sectionName
            case ".text"
                disp('Extracting .text memory dump...')
                simulationOutput.codeMemory = memoryDump(memoryPointer: memoryPointer+str2double(memoryBlocksInfo(memoryOffset))/4-1, :);
                memoryPointer = memoryPointer + str2double(memoryBlocksInfo(memoryOffset))/4;
            case ".data"
                disp('Extracting .data memory dump...')
                simulationOutput.dataMemory = memoryDump(memoryPointer: memoryPointer+str2double(memoryBlocksInfo(memoryOffset))/4-1, :);
                memoryPointer = memoryPointer + str2double(memoryBlocksInfo(memoryOffset))/4;
            otherwise
                disp(['Unrecognized section: ' sectionName ', ignoring...'])
        end
    end
end