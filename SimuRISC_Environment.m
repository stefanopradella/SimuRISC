classdef SimuRISC_Environment
    properties ( Constant = true )
        RISCV_COMPILER_PATH = '/home/stefano/riscv/bin';                    % Location of the compiler binary
        RISCV_SIMULATOR_PATH = '/home/stefano/riscv/whisper';               % Location of the whisper binary
        VIVADO_PATH = '';
        DEFAULT_LINKER_FILE = 'link.ld';
        DEFAULT_WHISPER_CONFIG_FILE = 'whisperConfiguration.cfg'
    end
end