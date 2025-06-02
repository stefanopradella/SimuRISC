function CSRDump = getCSRDump(simulationOutput)
    CSRValue = squeeze(find(simulationOutput.logsout, 'CSR').Values.Data);
    CSRDump = double(CSRValue(end, :));
end