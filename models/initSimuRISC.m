variant                         =   'RVI32';
registerDataType                =   ['uint' num2str(SimuRISC_Constants.XLEN)];
addrTranslationMask             =   bitcmp(SimuRISC_Constants.RAM_BASE_ADDR, registerDataType);

clockFrequency                  =   45e6;
modelStopCondition              =   "tohost";

%% Initialize CSR
CSRInitialValue = int32(zeros(size(SimuRISC_Constants.CSR_LUT, 1),1));

% misa
misaValue = uint32(0);

CSRInitialValue(SimuRISC_Constants.CSR_LUT(:, 1) == hex2dec('300'))         =   hex2dec('0x1800');      %  Only m-mode is supported