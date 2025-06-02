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
    [~, cmdout] = system(strcat("riscv64-unknown-elf-objdump -h ", elfFilePath));
    cmdout = splitlines(string(cmdout));

    memoryLocations = dictionary();
    for iLine = 1:numel(cmdout)
        if regexp(cmdout(iLine), "\s+\d+\s+\.text(?:\.init)?\s+")
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

    nInstructions = sscanf(responseRows(2), "Executed %d");

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

    textSectionBaseIndex = (textSectionBaseAddr - SimuRISC_Constants.RAM_BASE_ADDR) / (SimuRISC_Constants.XLEN/8);

    if exist('dataSectionBaseAddr', 'var')
        dataSectionBaseIndex = (dataSectionBaseAddr - SimuRISC_Constants.RAM_BASE_ADDR) / (SimuRISC_Constants.XLEN/8);
    else
        dataSectionBaseIndex = 0;
    end
    
    memoryPointer = 1;
    memoryBlocksInfo_keys = memoryBlocksInfo.keys();

    memoryLocations_keys = memoryLocations.keys();

    for iBlock = 1:memoryBlocksInfo.numEntries
        try
            memoryBlockStartOffset = str2double(memoryBlocksInfo_keys(iBlock));
            memoryBlockLength = str2double(memoryBlocksInfo(memoryBlockStartOffset));
            memoryBlockEndOffset = memoryBlockStartOffset + memoryBlockLength;

            % For each memory block, check if the code section is inside
            % that block
            for iSection = 1:memoryLocations.numEntries
                sectionAddress_key = memoryLocations_keys(iSection);
                sectionStartAddress = str2double(sectionAddress_key);

                if iSection < memoryLocations.numEntries
                    % this means that there is another section ahead in
                    % memory
                    sectionAddress_key_next = memoryLocations_keys(iSection+1);
                    sectionStartAddress_next = str2double(sectionAddress_key_next);
                    sectionEndAddress = sectionStartAddress_next - (SimuRISC_Constants.XLEN/8);
                else
                    % This is the last section
                    sectionEndAddress = memoryBlockEndOffset;
                end
                
                if (sectionStartAddress >= memoryBlockStartOffset && sectionEndAddress <= memoryBlockEndOffset)
                    sectionArraySize = (memoryBlockEndOffset-sectionStartAddress)/(SimuRISC_Constants.XLEN/8);
                    
                    sectionName = memoryLocations(sectionAddress_key);

                    sectionStartOffsetInBlock = (sectionStartAddress - memoryBlockStartOffset)/(SimuRISC_Constants.XLEN/8) + 1;

                    switch sectionName
                        case ".text"
                            vprintf(printOutput, 'Extracting .text memory dump...')
                            simulationOutput.codeMemory(textSectionBaseIndex+1:textSectionBaseIndex+sectionArraySize) = bytesToWords(memoryDump(sectionStartOffsetInBlock: sectionStartOffsetInBlock+sectionArraySize-1, :));
                        case ".data"
                            vprintf(printOutput, 'Extracting .data memory dump...')
                            simulationOutput.dataMemory(dataSectionBaseIndex+1:dataSectionBaseIndex+sectionArraySize) = bytesToWords(memoryDump(sectionStartOffsetInBlock: sectionStartOffsetInBlock+sectionArraySize-1, :));
                        otherwise
                            vprintf(printOutput, 'Unrecognized section: %s, ignoring...', sectionName)
                    end
                end
            end
        catch ME
            fprintf('Exception reading memory offset %s, skipping...\n', memoryBlockStartOffset)
        end
    end

    % Writing the correct value to the .tohost variable address, to take
    % account of the last instruction which is not dumped

    [~, ~, elfExtras] = parseELFFile(elfFilePath);
    simulationOutput.dataMemory(elfExtras.tohostVarInfo.address /(SimuRISC_Constants.XLEN/8) + 1) = 1;

end