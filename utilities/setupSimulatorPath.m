[~,result]=system('echo -n $PATH');
if ~contains(result, SimuRISC_Environment.RISCV_SIMULATOR_PATH)
    setenv('PATH',[result ':' SimuRISC_Environment.RISCV_SIMULATOR_PATH])
end
clear result