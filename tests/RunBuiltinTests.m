classdef RunBuiltinTests < matlab.unittest.TestCase
    properties (MethodSetupParameter)
        testName = {"cleanExit", ...
                    "memoryReadWrite", ...
                    "subset_v0_2_part3", ...
                    "subset_v0_2_part2", ...
                    "subset_v0_2_part1", ...
                    "subset_v0_1", ...
                    "subset_v0_3", ...
                    "simpleLoad", ...
        
            };
    end

    properties
        elfFilePath;
    end

    methods (TestMethodSetup)
        function compileCode(testCase, testName)
            testFolderPath = strcat(getProjectRoot(), filesep, "tests", filesep, testName);
            sourceFilePath = testFolderPath+filesep+testName+".s";
            testCase.elfFilePath = testFolderPath+filesep+testName+".elf";

            % Compile test code
            compileSW('SourceFilePath', sourceFilePath);
        end
    end

    methods (Test)
        function testExecution(testCase)

            % Run test on model
            modelOutput = runTestCase("ElfFilePath", testCase.elfFilePath, ...
                "StopCondition", "tohost");
        
            % Simulate test and get RAM dump
            simulationOutput = whisperSimulateElf("ElfFilePath", testCase.elfFilePath);
        
            % Check results
            testCase.verifyEqual(simulationOutput.memoryData, modelOutput.memoryData);
            testCase.verifyEqual(modelOutput.registerFile, simulationOutput.registerFile);

            % Check that the number of retired instruciton is the same.
            % Take into account that the number of retired instruction in
            % whisper is 1 less because the exit instructions is not logged
            % in register dump
            testCase.verifyEqual(modelOutput.numRetiredInstructions - 1, uint32(simulationOutput.CSR{simulationOutput.CSR.name == "minstret", "value"}));
        end
    end
end