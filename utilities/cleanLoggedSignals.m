loggedSignals = {   'numRetiredInstructions', ...
                    'dataMemory_addr', ...
                    'dataMemory_din', ...
                    'dataMemory_we', ...
                    'pc', ...
                    'registerFile', ...
                    'debug_hex_WB'};

% Turn logs off for all signals
signalList = find_system('SimuRISC', 'FindAll', 'on', 'Type', 'port', 'PortType', 'outport', 'DataLogging', 'on');
for i = 1:numel(signalList)
    signalHandle = signalList(i);
    Simulink.sdi.markSignalForStreaming(signalHandle,'off')
end

% Turn logs on for signals that are used to check asserts and to get RAM
% dump

for j = 1:length(loggedSignals)
    % Find lines matching the name in the array
    targetLines = find_system('SimuRISC', 'FindAll', 'on', 'Type', 'line', 'Name', loggedSignals{j});
    
    for k = 1:length(targetLines)
        % Get the source port handle for the named line
        srcPort = get_param(targetLines(k), 'SrcPortHandle');
        
        if srcPort ~= -1
            Simulink.sdi.markSignalForStreaming(srcPort, 'on');
            % Optional: Also enable standard Data Logging (logsout)
            set_param(srcPort, 'DataLogging', 'on');
        end
    end
end