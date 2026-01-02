variant                         =   'RVI32';
registerDataType                =   ['uint' num2str(SimuRISC_Constants.XLEN)];
addrTranslationMask             =   bitcmp(SimuRISC_Constants.RAM_BASE_ADDR, registerDataType);

clockFrequency                  =   45e6;

if ~exist('modelStopCondition', 'var')
    modelStopCondition          =   "tohost";
end

if ~exist('enableCSR', 'var')
    enableCSR                   =   false;
end


%% Initialize model to fix datatypes and allow compilation
if ~exist('instructionMemory', 'var')
    instructionMemory           =   uint32(zeros(2^SimuRISC_Constants.DATATYPE_MEMORY_ADDR.WordLength , 1));
    dataMemory                  =   uint32(zeros(2^SimuRISC_Constants.DATATYPE_MEMORY_ADDR.WordLength, 1));
    entryPointAddress           =   hex2dec('80000000');
    tohost_address              =   hex2dec('1000');
end


%% Initialize CSR
CSRInitialValue = int32(zeros(size(SimuRISC_Constants.CSR_LUT, 1),1));
valid_csrs = uint32(SimuRISC_Constants.CSR_LUT(:, 1));

% misa
misaValue = uint32(0);

CSRInitialValue(SimuRISC_Constants.CSR_LUT(:, 1) == hex2dec('300'))         =   hex2dec('0x1800');      %  Only m-mode is supported


%% Simulation time limit
simMaxTime                      =   1e3/clockFrequency;