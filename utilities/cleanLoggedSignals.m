loggedSignals = {   'numRetiredInstructions', ...
                    'dataMemory_addr', ...
                    'dataMemory_din', ...
                    'dataMemory_we', ...
                    'pc', ...
                    'registerFile', ...
                    'debug_hex_WB'};

allPorts = find_system('SimuRISC', 'FindAll', 'on', 'Type', 'port', 'PortType', 'outport');

for i = 1:numel(allPorts)
    portHandle = allPorts(i);
    
    signalName = get_param(portHandle, 'Name');
    
    if strcmp(get_param(portHandle, 'DataLogging'), 'off') && ismember(signalName, loggedSignals)
        Simulink.sdi.markSignalForStreaming(portHandle, 'on');
        set_param(portHandle, 'DataLogging', 'on');
    elseif strcmp(get_param(portHandle, 'DataLogging'), 'on') && ~ismember(signalName, loggedSignals)
        Simulink.sdi.markSignalForStreaming(portHandle, 'off');
        set_param(portHandle, 'DataLogging', 'off');
    end
end