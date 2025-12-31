function RAMDump = getRAMDump(simulationOutput, RAMinitialValue)
    RAMDump = RAMinitialValue;
    dataMemory_wr_addr = squeeze(find(simulationOutput.logsout, 'dataMemory_addr').Values.Data);
    dataMemory_din = fi(squeeze(find(simulationOutput.logsout, 'dataMemory_din').Values.Data), 0, 32, 0);   % TODO parametric wlen for data
    dataMemory_we = squeeze(find(simulationOutput.logsout, 'dataMemory_we').Values.Data);

    dataMemory_nColumns = dataMemory_we.WordLength;                    
    dataMemory_columnSize = dataMemory_din.WordLength / dataMemory_nColumns;

    dataMemory_we_mask = fi(zeros(size(dataMemory_we)), dataMemory_din.Signed, dataMemory_din.WordLength, dataMemory_din.FractionLength);
    dataMemory_we_mask.bin = repelem(dataMemory_we.bin, 1, dataMemory_columnSize);

    writeAddr = dataMemory_wr_addr(dataMemory_we>0);
    writeData = bitand(dataMemory_din, dataMemory_we_mask);

    RAMDump(writeAddr+1) = writeData(dataMemory_we>0);
end