function RAMDump = getRAMDump(simulationOutput, RAMinitialValue)
    RAMDump = RAMinitialValue;
    dataMemory_wr_addr = squeeze(find(simulationOutput.logsout, 'dataMemory_wr_addr').Values.Data);
    dataMemory_din = squeeze(find(simulationOutput.logsout, 'dataMemory_din').Values.Data);
    dataMemory_we = squeeze(find(simulationOutput.logsout, 'dataMemory_we').Values.Data);

    writeAddr = dataMemory_wr_addr(dataMemory_we);
    writeData = dataMemory_din(dataMemory_we);

    RAMDump(writeAddr+1) = writeData;
end