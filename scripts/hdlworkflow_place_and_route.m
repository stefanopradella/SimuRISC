%--------------------------------------------------------------------------
% HDL Workflow Script
% Generated with MATLAB 24.2 (R2024b) at 20:19:40 on 02/01/2025
% This script was generated using the following parameter values:
%     Filename  : '/home/stefano/Projects/SimuRISC/scripts/hdlworkflow_place_and_route.m'
%     Overwrite : true
%     Comments  : true
%     Headers   : true
%     DUT       : 'SimuRISC_tb/SimuRISC'
% To view changes after modifying the workflow, run the following command:
% >> hWC.export('DUT','SimuRISC_tb/SimuRISC');
%--------------------------------------------------------------------------

%% Load the Model
load_system('SimuRISC_tb');

%% Restore the Model to default HDL parameters
%hdlrestoreparams('SimuRISC_tb/SimuRISC');

%% Model HDL Parameters
%% Set Model 'SimuRISC_tb' HDL parameters
hdlset_param('SimuRISC_tb', 'HDLSubsystem', 'SimuRISC_tb/SimuRISC');
hdlset_param('SimuRISC_tb', 'ProjectFolder', 'hdl_prj');
hdlset_param('SimuRISC_tb', 'SynthesisTool', 'Xilinx Vivado');
hdlset_param('SimuRISC_tb', 'SynthesisToolChipFamily', 'Zynq');
hdlset_param('SimuRISC_tb', 'SynthesisToolDeviceName', 'xc7z020');
hdlset_param('SimuRISC_tb', 'SynthesisToolPackageName', 'clg484');
hdlset_param('SimuRISC_tb', 'SynthesisToolSpeedValue', '-1');
hdlset_param('SimuRISC_tb', 'TargetDirectory', 'hdl_prj/hdlsrc');
hdlset_param('SimuRISC_tb', 'TargetFrequency', clockFrequency / 1e6);

% Set ModelReference HDL parameters
hdlset_param('SimuRISC_tb/SimuRISC', 'BalanceDelays', 'off');

%% Set Referenced Model 'SimuRISC' HDL parameters
load_system('SimuRISC');

% Set Inport HDL parameters
hdlset_param('SimuRISC/rst', 'IOInterface', 'External Port');
hdlset_param('SimuRISC/rst', 'IOInterfaceMapping', '');

% Set Outport HDL parameters
hdlset_param('SimuRISC/stopCondition', 'IOInterface', 'External Port');
hdlset_param('SimuRISC/stopCondition', 'IOInterfaceMapping', '');


%% Workflow Configuration Settings
% Construct the Workflow Configuration Object with default settings
hWC = hdlcoder.WorkflowConfig('SynthesisTool','Xilinx Vivado','TargetWorkflow','Generic ASIC/FPGA');

% Specify the top level project directory
hWC.ProjectFolder = 'hdl_prj';
hWC.AllowUnsupportedToolVersion = true;

% Set Workflow tasks to run
hWC.RunTaskGenerateRTLCodeAndTestbench = true;
hWC.RunTaskVerifyWithHDLCosimulation = false;
hWC.RunTaskCreateProject = true;
hWC.RunTaskRunSynthesis = true;
hWC.RunTaskRunImplementation = true;
hWC.RunTaskAnnotateModelWithSynthesisResult = true;

% Set properties related to 'RunTaskGenerateRTLCodeAndTestbench' Task
hWC.GenerateRTLCode = true;
hWC.GenerateTestbench = false;
hWC.GenerateValidationModel = false;

% Set properties related to 'RunTaskCreateProject' Task
hWC.Objective = hdlcoder.Objective.None;
hWC.AdditionalProjectCreationTclFiles = '';

% Set properties related to 'RunTaskRunSynthesis' Task
hWC.SkipPreRouteTimingAnalysis = false;

% Set properties related to 'RunTaskRunImplementation' Task
hWC.IgnorePlaceAndRouteErrors = false;

% Set properties related to 'RunTaskAnnotateModelWithSynthesisResult' Task
hWC.CriticalPathSource = 'pre-route';
hWC.CriticalPathNumber =  1;
hWC.ShowAllPaths = false;
hWC.ShowDelayData = true;
hWC.ShowUniquePaths = false;
hWC.ShowEndsOnly = false;
hWC.AnnotateModel = 'generated';

% Validate the Workflow Configuration Object
hWC.validate;

%% Run the workflow
hdlcoder.runWorkflow('SimuRISC_tb/SimuRISC', hWC);
