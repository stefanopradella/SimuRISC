function modelOutput = runTestCase(NameValueArgs)
% TODO Description
    arguments
        NameValueArgs.ElfFilePath (1,1) string = ''
    end

    if strcmp(NameValueArgs.ElfFilePath, "")
        [filename, filepath] = uigetfile('*');
        elfFilePath = [filepath, filename];
    else
        elfFilePath = NameValueArgs.ElfFilePath;
        [filepath, ~] = fileparts(elfFilePath);
    end

    [modelInput.instructionMemory, modelInput.dataMemory, elfExtras] = parseELFFile(elfFilePath);
    
    modelInput.entryPointAddress = elfExtras.entryPointAddress;
    modelInput.tohost_address = elfExtras.tohostVarInfo.address;

    % Set simulation inputs
    simIn = Simulink.SimulationInput('SimuRISC_tb');
    simIn = setVariable(simIn,'instructionMemory',modelInput.instructionMemory);
    simIn = setVariable(simIn,'dataMemory',modelInput.dataMemory);
    simIn = setVariable(simIn,'entryPointAddress',modelInput.entryPointAddress);
    simIn = setVariable(simIn,'tohost_address',modelInput.tohost_address);

    warning('off');                 % Turning off as the intended wrap on overflow will issue a warning
    simOut = sim(simIn);
    warning('on');

    % Get dump of data memory after model execution
    modelOutput.dataMemory = getRAMDump(simOut, modelInput.dataMemory);

    % Get the register status
    modelOutput.pc = find(simOut.logsout, "pc").Values.Data(end);
    modelOutput.registerFile = find(simOut.logsout, "registerFile").Values.Data(end, :);
end