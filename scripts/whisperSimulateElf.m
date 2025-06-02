function simulationOutput = whisperSimulateElf(NameValueArgs)
% WHISPERSIMULATEELF - Simulate Elf file with Whisper and return memory and registers state.
%   Syntax:
%       WHISPERSIMULATEELF()                                   [Prompts the user for the elf file location]
%       WHISPERSIMULATEELF  ('ElfFilePath', 'test.elf')
%       WHISPERSIMULATEELF  ('ElfFilePath', 'test.elf', 'PrintOutput', true)
%       WHISPERSIMULATEELF  ('ElfFilePath', 'test.elf', 'WhisperConfigFilePath', 'customWhisperConfig.cfg')
    arguments
        NameValueArgs.ElfFilePath (1,1) string = ''
        NameValueArgs.PrintOutput (1,1) logical = false
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
    printOutput = NameValueArgs.PrintOutput;

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

    vprintf(printOutput, "Simulating %d instructions...\n", nInstructions)

    % Simulate elf file and save status after last instruction
    % -1 is because the last instruction writes to the .tohost variable to
    % terminate the execution
    [ret, out] = system(strcat("whisper ", elfFilePath, " --snapshotperiod ", num2str(nInstructions-1), " --snapshotdir ", ...
        filepath, "/snapshot --configfile ", whisperConfigFilePath));

    vprintf(printOutput, "%s\n", out)

    if ret ~= 0
        error('Whisper execution failed, check system configuration')
    end
    
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
    simulationOutput.registerFile = zeros(1, 32);
    simulationOutput.pc = 0;

    registerDumpFile = splitlines(string(fileread(strcat(filepath, "/snapshot0/registers"))));
    for iLine = 1:numel(registerDumpFile)
        if regexp(registerDumpFile(iLine), "x\s\d+\s")
            lineSplit = split(registerDumpFile(iLine));
            simulationOutput.registerFile(str2double(lineSplit(2))+1) = hex2dec(lineSplit(3));
        elseif regexp(registerDumpFile(iLine), "pc\s")
            lineSplit = split(registerDumpFile(iLine));
            simulationOutput.pc = hex2dec(lineSplit(2));
        end

    end

    % Read memory status from snapshot
    movefile(strcat(filepath, "/snapshot0/memory"), strcat(filepath, "/snapshot0/memory.gz"))
    system(strcat("gzip -dk ", filepath, "/snapshot0/memory"));
    memoryDump = loadMemory(strcat(filepath, "/snapshot0/memory"));
    
    % Extracting memory dump
    simulationOutput.codeMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));
    simulationOutput.dataMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));

    textSectionBaseIndex = textSectionBaseAddr / (SimuRISC_Constants.XLEN/8);
    dataSectionBaseIndex = dataSectionBaseAddr / (SimuRISC_Constants.XLEN/8);

    memoryPointer = 1;
    memoryBlocksInfo_keys = memoryBlocksInfo.keys();
    for iBlock = 1:memoryBlocksInfo.numEntries
        try
            memoryOffset = memoryBlocksInfo_keys(iBlock);
            sectionName = memoryLocations(memoryOffset);
            
            textSectionArraySize = str2double(memoryBlocksInfo(memoryOffset))/(SimuRISC_Constants.XLEN/8);
            dataSectionArraySize = str2double(memoryBlocksInfo(memoryOffset))/(SimuRISC_Constants.XLEN/8);
    
            switch sectionName
                case ".text"
                    vprintf(printOutput, 'Extracting .text memory dump...')
                    simulationOutput.codeMemory(textSectionBaseIndex+1:textSectionBaseIndex+textSectionArraySize) = bytesToWords(memoryDump(memoryPointer: memoryPointer+textSectionArraySize-1, :));
                    memoryPointer = memoryPointer + str2double(memoryBlocksInfo(memoryOffset))/4;
                case ".data"
                    vprintf(printOutput, 'Extracting .data memory dump...')
                    simulationOutput.dataMemory(dataSectionBaseIndex+1:dataSectionBaseIndex+dataSectionArraySize) = bytesToWords(memoryDump(memoryPointer: memoryPointer+dataSectionArraySize-1, :));
                    memoryPointer = memoryPointer + str2double(memoryBlocksInfo(memoryOffset))/4;
                otherwise
                    vprintf(printOutput, 'Unrecognized section: %s, ignoring...', sectionName)
            end
        catch ME
            fprintf('Exception reading memory offset %s, skipping...\n', memoryOffset)
        end
    end

    % Writing the correct value to the .tohost variable address, to take
    % account of the last instruction which is not dumped

    [~, ~, elfExtras] = parseELFFile(elfFilePath);
    simulationOutput.dataMemory(hex2dec(elfExtras.tohostVarInfo.address) /(SimuRISC_Constants.XLEN/8) + 1) = 1;

end