clear;
close all;
bdclose all;

testList = ["cleanExit", ...
            "subset_v0_2_part3", ...
            "subset_v0_2_part2", ...
            "subset_v0_2_part1", ...
            "subset_v0_1", ...
            "memoryReadWrite", ...
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
    
    startTime = datetime('now');

    % Run test on model
    modelOutput = runTestCase("ElfFilePath", elfFilePath);
    
    % Simulate test and get RAM dump
    simulationOutput = whisperSimulateElf("ElfFilePath", elfFilePath);

    % Check results
    assert(isequal(simulationOutput.dataMemory, modelOutput.dataMemory));
    assert(isequal(simulationOutput.pc, modelOutput.pc));
    assert(isequal(simulationOutput.registerFile, modelOutput.registerFile));
    status = 'PASSED';

    endTime = datetime('now');
    
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