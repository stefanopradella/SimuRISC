% Run the test cases from the riscv-tests suite
% https://github.com/riscv-software-src/riscv-tests

classdef RunRiscvTests < matlab.unittest.TestCase

    properties (MethodSetupParameter)
        TVMName = {"rv32ui"}
        targetEnvironment = {"p"}
        testName = {"add", ...        
            };
    end

    properties
        elfFilePath;
    end

    methods (TestMethodSetup)
        function getFilePath(testCase, TVMName, targetEnvironment, testName)
            testFolderPath = strcat(SimuRISC_Environment.RISCV_TESTS_PATH, filesep, "isa");
            testCase.elfFilePath = testFolderPath+filesep+TVMName+"-"+targetEnvironment+"-"+testName;
            
        end
    end

    methods (Test)
        function testExecution(testCase)

            % Run test on model
            modelOutput = runTestCase("ElfFilePath", testCase.elfFilePath, ...
                "StartSection","test_2", ...
                "StopCondition", "ecall");
        
            % Check results
            % x17 is 93 for syscall exit
            testCase.verifyEqual(modelOutput.registerFile(18), uint32(93))
            % x11 is the return code
            testCase.verifyEqual(modelOutput.registerFile(11), uint32(0))
        end
    end
end