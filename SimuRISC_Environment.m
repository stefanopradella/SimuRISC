classdef SimuRISC_Environment
    properties ( Constant = true )
        RISCV_COMPILER_PATH = '/home/stefano/riscv/bin';                    % This is where the assembler is installed
        VIVADO_PATH = '';
        DEFAULT_LINKER_FILE = 'link.ld';
    end
end