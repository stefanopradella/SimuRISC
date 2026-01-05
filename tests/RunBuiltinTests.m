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
            testCase.verifyEqual(simulationOutput.dataMemory, modelOutput.dataMemory)
            testCase.verifyEqual(simulationOutput.registerFile, modelOutput.registerFile)
        end
    end
end