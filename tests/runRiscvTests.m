% Run the test cases from the riscv-tests suite
% https://github.com/riscv-software-src/riscv-tests

testList = jsondecode(fileread('RISCVTestList.json'));

tvmNameList = fieldnames(testList.TVMs);
tgtEnvNameList = testList.TargetEnvironments;

% Set model variants for this test run

modelStopCondition          =   "ecall";

for iTVM = 1:numel(testList.TVMs)
    tvmName = tvmNameList{iTVM};
    tvmTests = testList.TVMs.(tvmName);
    fprintf("TVM: %s\n", tvmName);
    for iTgtEnv = 1:numel(testList.TargetEnvironments)
        tgtEnvName = tgtEnvNameList{iTgtEnv};
        fprintf("Target Environment: %s\n", tgtEnvName);
        for iTest = 1:numel(tvmTests)
            testName = tvmTests{iTest};
            fprintf("Test: %s\n", testName);
            testFolderPath = [SimuRISC_Environment.RISCV_TESTS_PATH filesep 'isa'];
            elfFilePath = [testFolderPath filesep tvmName '-' tgtEnvName '-' testName ];

            % Set stop condition value
            [~, ~, elfExtras] = parseELFFile(elfFilePath);
            pass_section_addr = hex2dec(elfExtras.symbolTable.st_value(strcmp(elfExtras.symbolTable.symbolName,"pass")));

            % Run test on model
            modelOutput = runTestCase("ElfFilePath", elfFilePath, 'StartSection',"test_2");
            
            % Check results
            
            % x17 is 93 for syscall exit
            assert(isequal(modelOutput.registerFile(18), 93));
            % x11 is the return code
            assert(isequal(modelOutput.registerFile(11), 0));
            status = 'PASSED';
            
        end
    end
end