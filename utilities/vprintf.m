function vprintf(shouldPrint, format, varargin)
    % VPRINTF - Conditional version of fprintf with a control flag.
    %
    % Syntax:
    %   vprintf(shouldPrint, format, varargin)
    %
    % Input:
    %   shouldPrint - Boolean flag (true to print, false to skip).
    %   format      - Format string as used in fprintf.
    %   varargin    - Additional arguments as used in fprintf.
    
    if shouldPrint
        fprintf(format, varargin{:});
    end
end