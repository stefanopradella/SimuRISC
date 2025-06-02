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

    % Get information about the .text and the .data sections
    [~, cmdout] = system(strcat("riscv64-unknown-elf-objdump -h ", elfFilePath));
    cmdout = splitlines(string(cmdout));

    memoryBaseAddrList = table();
    for iLine = 1:numel(cmdout)
        newEntry = [];
        if regexp(cmdout(iLine), "\s+\d+\s+\.text(?:\.init)?\s+")
            newEntry.ID = ".text";
        end
        if regexp(cmdout(iLine), "\s+\d+\s+\.data\s+")
            newEntry.ID = ".data";
        end

        if isfield(newEntry, "ID")
            lineSplit = split(cmdout(iLine));
            newEntry.StartAddr = lineSplit(5);
            newEntry.Size = lineSplit(4);
            memoryBaseAddrList = [memoryBaseAddrList; struct2table(newEntry)];
        end
    end

    % Simulate elf file the first time to get the number of instructions
    cmd = strcat("env -u LD_LIBRARY_PATH whisper ", elfFilePath, " --configfile ", whisperConfigFilePath);
    [~, response] = system(cmd);
    responseRows = splitlines(string(response));

    nInstructions = sscanf(responseRows(2), "Executed %d");

    vprintf(printOutput, "Simulating %d instructions...\n", nInstructions)

    % Simulate elf file and save status after last instruction
    % -1 is because the last instruction writes to the .tohost variable to
    % terminate the execution
    cmd = strcat("env -u LD_LIBRARY_PATH whisper ", elfFilePath, " --snapshotperiod ", num2str(nInstructions-1), " --snapshotdir ", ...
        filepath, "/snapshot --configfile ", whisperConfigFilePath);
    [ret, out] = system(cmd);

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
            memoryBlocksInfo(dec2hex(str2double(tmp(1)))) = tmp(2);
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
    memoryDumpData = bytesToWords(loadMemory(strcat(filepath, "/snapshot0/memory")));
    
    % Extracting memory dump
    simulationOutput.codeMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));
    simulationOutput.dataMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));

    textSectionBaseIndex = (hex2dec(memoryBaseAddrList{memoryBaseAddrList.ID == ".text", "StartAddr"}) - SimuRISC_Constants.RAM_BASE_ADDR) / (SimuRISC_Constants.XLEN/8);

    if ~isempty(memoryBaseAddrList(memoryBaseAddrList.ID == ".data", :))
        dataSectionBaseIndex = (hex2dec(memoryBaseAddrList{memoryBaseAddrList.ID == ".data", "StartAddr"}) - SimuRISC_Constants.RAM_BASE_ADDR) / (SimuRISC_Constants.XLEN/8);
    else
        dataSectionBaseIndex = 0;
    end
    
    memoryBlocksInfo_keys = memoryBlocksInfo.keys();
    memoryBaseAddrList_keys = memoryBaseAddrList.StartAddr(:);

    programMemoryArraySize = (hex2dec(memoryBlocksInfo_keys(end)) - SimuRISC_Constants.RAM_BASE_ADDR) + (str2double(memoryBlocksInfo(memoryBlocksInfo_keys(end)))/4);
    programMemory = uint32(zeros(programMemoryArraySize, 1));
    for iBlock = 1:memoryBlocksInfo.numEntries
        % Get start and end address of the dumped memory block
        memoryBlockStartAddr = hex2dec(memoryBlocksInfo_keys(iBlock)) - SimuRISC_Constants.RAM_BASE_ADDR;
        memoryBlockLength = str2double(memoryBlocksInfo(memoryBlocksInfo_keys(iBlock)));
        memoryBlockEndAddr = memoryBlockStartAddr + memoryBlockLength;
        memoryBlockStartIdx = (memoryBlockStartAddr/4)+1;
        memoryBlockEndIdx = memoryBlockEndAddr/4;
        
        % Get the index of such block in the memory dump data
        dumpBlockStartIdx = ((iBlock-1)*(memoryBlockLength/4))+1;
        dumpBlockEndIdx = dumpBlockStartIdx+(memoryBlockLength/4)-1;

        % Load data from the memory dump into the program memory array
        programMemory(memoryBlockStartIdx:memoryBlockEndIdx) = memoryDumpData(dumpBlockStartIdx:dumpBlockEndIdx);

    end

    % Split the program memory into text and data memory
    for iSection = 1:numel(memoryBaseAddrList_keys)
        sectionAddress_key = memoryBaseAddrList_keys(iSection);
        sectionID = memoryBaseAddrList{memoryBaseAddrList.StartAddr == sectionAddress_key, "ID"};

        switch sectionID
            case ".text"
                vprintf(printOutput, 'Extracting .text memory dump...\n')
                textSectionArraySize = hex2dec(memoryBaseAddrList{memoryBaseAddrList.ID == ".text", "Size"})/4;
                textSectionArrayStart = ((hex2dec(sectionAddress_key) - SimuRISC_Constants.RAM_BASE_ADDR)/4)+1;
                simulationOutput.codeMemory(textSectionBaseIndex+1:textSectionBaseIndex+textSectionArraySize) = programMemory(textSectionArrayStart:textSectionArrayStart+textSectionArraySize-1, :);
            case ".data"
                vprintf(printOutput, 'Extracting .data memory dump...\n')
                dataSectionArrayStart = ((hex2dec(sectionAddress_key) - SimuRISC_Constants.RAM_BASE_ADDR)/4)+1;
                simulationOutput.dataMemory(dataSectionBaseIndex+1:dataSectionBaseIndex+(SimuRISC_Constants.DATA_SECTION_MAX_SIZE/4)) = programMemory(dataSectionArrayStart:dataSectionArrayStart+(SimuRISC_Constants.DATA_SECTION_MAX_SIZE/4)-1, :);
            otherwise
                vprintf(printOutput, 'Unrecognized section: %s, ignoring...\n', sectionID)
        end
    end

    % Writing the correct value to the .tohost variable address, to take
    % account of the last instruction which is not dumped

    [~, ~, elfExtras] = parseELFFile(elfFilePath);
    simulationOutput.dataMemory(elfExtras.tohostVarInfo.address /(SimuRISC_Constants.XLEN/8) + 1) = 1;

end