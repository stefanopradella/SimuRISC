[~,systemPath]=system('echo -n $PATH');
[~,simulatorPath]=system(['echo ' SimuRISC_Environment.RISCV_SIMULATOR_PATH]);
simulatorPath = strip(simulatorPath);
if ~contains(systemPath, simulatorPath)
    setenv('PATH',[simulatorPath ':' systemPath])
end
clear systemPath simulatorPath