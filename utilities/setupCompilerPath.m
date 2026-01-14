[~,systemPath]=system('echo -n $PATH');
[~,compilerPath]=system(['echo ' SimuRISC_Environment.RISCV_COMPILER_PATH]);
compilerPath = strip(compilerPath);
if ~contains(systemPath, compilerPath)
    setenv('PATH',[compilerPath ':' systemPath])
end
clear systemPath simulatorPath compilerPath