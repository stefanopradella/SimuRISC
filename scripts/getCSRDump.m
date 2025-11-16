function CSRDump = getCSRDump(simulationOutput)
    try
        CSRValue = squeeze(find(simulationOutput.logsout, 'CSR').Values.Data);
        CSRDump = double(CSRValue(end, :));
    catch Me
        if(strcmp(Me.identifier,'MATLAB:structRefFromNonStruct'))
            % Catches the case whan CSR is set to off
            CSRDump = [];
        end
    end
end