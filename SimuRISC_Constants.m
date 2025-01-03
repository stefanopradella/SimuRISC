classdef SimuRISC_Constants
    properties ( Constant = true )
        VERSION                     =   '0.1.0';
        XLEN                        =   32;
        ADDR_BUS_WIDTH              =   16;
        DATATYPE_MEMORY_ADDR        =   fixdt(0,SimuRISC_Constants.ADDR_BUS_WIDTH-log2(SimuRISC_Constants.XLEN/8),0);
    end
end