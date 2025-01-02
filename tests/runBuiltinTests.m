clear;
close all;
bdclose all;

testList = ["cleanExit", ...
            "memoryReadWrite", ...
            "subset_v0_1"
    ];

%% Test run

fprintf("Loading model...")
load_system('SimuRISC_tb')
load_system('SimuRISC')
fprintf("Done!\n");

for iTest = 1:numel(testList)
    testName = char(testList(iTest));
    testFolderPath = char(strcat(getProjectRoot(), filesep, "tests", filesep, testName));
    sourceFilePath = [testFolderPath filesep testName '.s'];
    elfFilePath = [testFolderPath filesep testName '.elf'];

    % Compile test code
    compileSW('SourceFilePath', sourceFilePath);
    [instructionMemory, dataMemory, elfExtras] = parseELFFile(elfFilePath);
    
    entryPointAddress = elfExtras.entryPointAddress;

    startTime = datetime('now');

    warning('off');                 % Turning off as the intended wrap on overflow will issue a warning
    simout = sim('SimuRISC_tb');
    warning('on');

    endTime = datetime('now');

    % Get dump of data memory after model execution
    modelOutput.dataMemory = getRAMDump(simout, dataMemory);

    % Get the register status
    modelOutput.pc = find(simout.logsout, "pc").Values.Data(end);
    modelOutput.registerFile = find(simout.logsout, "registerFile").Values.Data(end, :);

    % Simulate test and get RAM dump
    simulationOutput = whisperSimulateElf("ElfFilePath", elfFilePath);

    % Check results
    assert(isequal(simulationOutput.dataMemory, modelOutput.dataMemory));
    assert(isequal(simulationOutput.pc, modelOutput.pc));
    assert(isequal(simulationOutput.registerFile, modelOutput.registerFile));
    status = 'PASSED';

    printTestSummary(testName, status, startTime, endTime)
end

function printTestSummary(testName, status, startTime, endTime)

    duration = seconds(endTime - startTime);

    % Output
    fprintf('===========================================\n');
    fprintf('TEST: %s\n', testName);
    fprintf('-------------------------------------------\n');
    fprintf('STATUS: %s\n', status);
    fprintf('-------------------------------------------\n');
    fprintf('START TIME: %s\n', datetime(startTime, 'Format', 'yyyy-MM-dd HH:mm:SS'));
    fprintf('END TIME: %s\n', datetime(endTime, 'Format', 'yyyy-MM-dd HH:mm:SS'));
    fprintf('DURATION: %.2f seconds\n', duration);
    fprintf('===========================================\n');
end