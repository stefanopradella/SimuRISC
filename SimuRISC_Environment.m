classdef SimuRISC_Environment
    properties ( Constant = true )
        RISCV_COMPILER_PATH = '~/riscv/bin';                    % Location of the compiler binary
        RISCV_SIMULATOR_PATH = '~/riscv/whisper';               % Location of the whisper binary
        RISCV_TESTS_PATH = '~/riscv/riscv-tests';               % Location of the riscv-tests folder
        VIVADO_PATH = '/opt/Xilinx/Vivado/2024.2/bin';
        DEFAULT_LINKER_FILE = 'link.ld';
        DEFAULT_WHISPER_CONFIG_FILE = 'whisperConfiguration.cfg'
    end
end