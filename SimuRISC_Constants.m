classdef SimuRISC_Constants
    properties ( Constant = true )
        VERSION                     =   '0.1.0';
        XLEN                        =   32;
        ADDR_BUS_WIDTH              =   16;
        DATATYPE_MEMORY_ADDR        =   fixdt(0,SimuRISC_Constants.ADDR_BUS_WIDTH-log2(SimuRISC_Constants.XLEN/8),0);
        ARCH                        =   'rv32izicsr';
        ABI                         =   'ilp32';
        RAM_BASE_ADDR               =   hex2dec('80000000');
        DATA_SECTION_MAX_SIZE       =   hex2dec('1000');
    
        CSR_LUT = int32([...
            hex2dec('0B0'),  1;  % mnstatus
            hex2dec('140'),  2;  % satp
            hex2dec('300'),  3;  % mstatus
            hex2dec('302'),  4;  % medeleg
            hex2dec('303'),  5;  % mideleg
            hex2dec('304'),  6;  % mie
            hex2dec('305'),  7;  % mtvec
            hex2dec('340'),  8;  % mepc
            hex2dec('3A0'),  9;  % pmpcfg0
            hex2dec('3B0'), 10;  % pmpaddr0
            hex2dec('F14'), 11;  % mhartid
        ]);
    end
end