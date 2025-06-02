try
    hdlsetuptoolpath('ToolName','Xilinx Vivado','ToolPath', SimuRISC_Environment.VIVADO_PATH);
catch
    error('Error setting up Vivado path. Make sure Vivado is installed and the correct path is set into SimuRISC_Environment. Then run this script again.')
end