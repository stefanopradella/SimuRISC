[~,result]=system('echo -n $PATH');
if ~contains(result, SimuRISC_Environment.RISCV_COMPILER_PATH)
    setenv('PATH',[result ':' SimuRISC_Environment.RISCV_COMPILER_PATH])
end
clear result