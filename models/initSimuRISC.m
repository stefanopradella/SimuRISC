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


%% CSR

numPMPEntries                   =   16; 
pmpaddr                         =   uint32(zeros(1, 16));
pmpcfg                          =   uint32(zeros(1, 4));

% Set first entry to mask addr out of RAM
% Second entry is for both text and data memory, use symbols from symbol
% table
pmpaddr(1)                      =   uint32(hex2dec(elfExtras.symbolTable{strcmp(elfExtras.symbolTable{:, "symbolName"}, "_start"), "st_value"}));
pmpaddr(2)                      =   uint32(hex2dec(elfExtras.symbolTable{strcmp(elfExtras.symbolTable{:, "symbolName"}, "_end"), "st_value"}));
pmpcfg(1)                       =   hex2dec('0F00');

% pmpaddr is shifted by 2 bits as from specifications
pmpaddr = bitshift(pmpaddr, -2);


%% Simulation time limit

simMaxTime                      =   1e4/clockFrequency;