variant                         =   'RVI32';
registerDataType                =   ['uint' num2str(SimuRISC_Constants.XLEN)];
addrTranslationMask             =   bitcmp(SimuRISC_Constants.RAM_BASE_ADDR, registerDataType);

clockFrequency                  =   45e6;
modelStopCondition              =   "tohost";