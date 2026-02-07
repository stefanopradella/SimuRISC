function modelOutput = runTestCase(NameValueArgs)
% TODO Description
    arguments
        NameValueArgs.ElfFilePath (1,1) string = ''
        NameValueArgs.StartSection (1,1) string = ''
        NameValueArgs.StopCondition (1,1) string = ''
    end

    if strcmp(NameValueArgs.ElfFilePath, "")
        [filename, filepath] = uigetfile('*');
        elfFilePath = [filepath, filename];
    else
        elfFilePath = NameValueArgs.ElfFilePath;
        [filepath, ~] = fileparts(elfFilePath);
    end

    [modelInput.memoryData, elfExtras] = parseELFFile(elfFilePath);
    
    if strcmp(NameValueArgs.StartSection, "")
        modelInput.entryPointAddress = elfExtras.entryPointAddress;
    else
        % Find the entry in symbol table and load the address of the
        % section
        modelInput.entryPointAddress = hex2dec(elfExtras.symbolTable.st_value(strcmp(elfExtras.symbolTable.symbolName,NameValueArgs.StartSection)));
    end
    
    modelInput.tohost_address = elfExtras.tohostVarInfo.address;

    % Set simulation inputs
    simIn = Simulink.SimulationInput('SimuRISC_tb');
    simIn = setVariable(simIn,'memoryData',modelInput.memoryData);
    simIn = setVariable(simIn,'entryPointAddress',modelInput.entryPointAddress);
    simIn = setVariable(simIn,'tohost_address',modelInput.tohost_address);
    if ~isempty(NameValueArgs.StopCondition)
        simIn = setVariable(simIn,'modelStopCondition',NameValueArgs.StopCondition);
    end

    warning('off');                 % Turning off as the intended wrap on overflow will issue a warning
    simOut = sim(simIn);
    warning('on');

    % Get dump of data memory after model execution
    modelOutput.memoryData = getRAMDump(simOut, modelInput.memoryData);

    % Get the register status
    modelOutput.pc = find(simOut.logsout, "pc").Values.Data(end);
    modelOutput.registerFile = find(simOut.logsout, "registerFile").Values.Data(end, :);

    % Get other params
    modelOutput.numRetiredInstructions = find(simOut.logsout, "numRetiredInstructions").Values.Data(end, :);
end