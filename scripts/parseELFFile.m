function [instructionMemory, dataMemory, entryPointAddress] = parseELFFile(varargin)
%   PARSEELFFILE - Reads a ELF file and returns the memory data variables.
%   Reference: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
% 
%   [instructionMemory, dataMemory, entryPointAddress]=parseELFFile('/home/path/to/file.elf');

    if nargin == 0
        [filename, filepath] = uigetfile('*');
        elfFilePath = [filepath, filename];
    else
        elfFilePath = varargin{1};
    end

    fileId = fopen(elfFilePath);

    parseMExc = MException('parseELFFile:infalidELFFile', ...
        'Parsing failed, invalid ELF File');

    e_ident = fread(fileId, 16);

    magicNumber = e_ident(1:4);
    if magicNumber ~= [127; 69; 76; 70]
        throw(parseMExc)
    end

    switch e_ident(5)
        case 1
            format = '32-bit';
            formatVarType = '*ubit32';                                      % Sets the size for the format-dependent fields
        case 2
            format = '64-bit';
            formatVarType = '*ubit64'; 
        otherwise
            throw(parseMExc)
    end
    disp(['Format: ' format])

    switch e_ident(6)
        % this affects interpretation of multi-byte fields starting with offset 0x10. 
        case 1
            endianness = 'l';
        case 2
            endianness = 'b';
        otherwise
            throw(parseMExc)
    end
    disp(['Endianness: ' endianness])

    if e_ident(7) ~= 1
        throw(parseMExc)
    end

    disp(['ABI ID: 0x' dec2hex(e_ident(8))])
    disp(['ABI Version: 0x' dec2hex(e_ident(9))])

    % Bytes 9-15 padding -> ignored

    e_type = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Object type ID: 0x' e_type])
    e_machine = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Target ISA ID: 0x' e_machine])

    % Bytes 20-24 ELF Version
    e_version = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);

    e_entry = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    disp(['Entry point address: 0x' e_entry])
    entryPointAddress = hex2dec(e_entry);
    e_phoff = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    disp(['Program header address: 0x' e_phoff])
    e_shoff = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    disp(['Section header address: 0x' e_shoff])

    e_flags = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
    disp(['Flags: 0x' e_flags])
    e_ehsize =  reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Header size: 0x' e_ehsize])
    e_phentsize = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Program header entries size: 0x' e_phentsize])
    e_phnum = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Program header entries number: 0x' e_phnum])
    e_shentsize = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Section header entry size: 0x' e_shentsize])
    e_shnum = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Section header entries number: 0x' e_shnum])
    e_shstrndx = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    disp(['Section header names entry index: 0x' e_shstrndx])

    % Read program header
    disp('=== Program Header ===')
    fseek(fileId, hex2dec(e_phoff),'bof');
    p_type = strings(hex2dec(e_phnum), 1);
    p_flags = strings(hex2dec(e_phnum), 1);
    p_offset = strings(hex2dec(e_phnum), 1);
    p_vaddr = strings(hex2dec(e_phnum), 1);
    p_paddr = strings(hex2dec(e_phnum), 1);
    p_filesz = strings(hex2dec(e_phnum), 1);
    p_memsz = strings(hex2dec(e_phnum), 1);
    p_align = strings(hex2dec(e_phnum), 1);

    for iPHeader = 1:hex2dec(e_phnum)
        p_type(iPHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        if strcmp(format, '64-bit')
            p_flags(iPHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        end
        p_offset(iPHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        p_vaddr(iPHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        p_paddr(iPHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        p_filesz(iPHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        p_memsz(iPHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        if strcmp(format, '32-bit')
            p_flags(iPHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        end
        p_align(iPHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    end
    programHeader  = table(p_type,p_flags,p_offset,p_vaddr,p_paddr,p_filesz, p_memsz, p_align);
    disp(programHeader)

    % Read section header
    disp('=== Section Header ===')
    fseek(fileId, hex2dec(e_shoff),'bof');
    Name = strings(hex2dec(e_shnum), 1);
    sh_name = strings(hex2dec(e_shnum), 1);
    sh_type = strings(hex2dec(e_shnum), 1);
    sh_flags = strings(hex2dec(e_shnum), 1);
    sh_addr = strings(hex2dec(e_shnum), 1);
    sh_offset = strings(hex2dec(e_shnum), 1);
    sh_size = strings(hex2dec(e_shnum), 1);
    sh_link = strings(hex2dec(e_shnum), 1);
    sh_info = strings(hex2dec(e_shnum), 1);
    sh_addralign = strings(hex2dec(e_shnum), 1);
    sh_entsize = strings(hex2dec(e_shnum), 1);

    for iSHeader = 1:hex2dec(e_shnum)
        sh_name(iSHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        sh_type(iSHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        sh_flags(iSHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        sh_addr(iSHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        sh_offset(iSHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        sh_size(iSHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        sh_link(iSHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        sh_info(iSHeader) = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
        sh_addralign(iSHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
        sh_entsize(iSHeader) = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    end
    sectionHeader  = table(sh_name,sh_type,sh_flags,sh_addr,sh_offset,sh_size,sh_link,sh_info,sh_addralign,sh_entsize);

    % Look in .shstrtab for the section name
    fseek(fileId,hex2dec(sectionHeader{hex2dec(e_shstrndx)+1,"sh_offset"}),'bof');
    shstrtab = fread(fileId, hex2dec(sectionHeader{hex2dec(e_shstrndx)+1,"sh_size"}));

    for iSHeader = 1:hex2dec(e_shnum)
        startIdx = hex2dec(sectionHeader{iSHeader,"sh_name"});
        sectionName = [];
        for i = 1:64
            nextChar = shstrtab(startIdx + i);
            if nextChar==0
                break
            else
                sectionName = [sectionName, char(nextChar)];
            end
        end

        if isempty(sectionName)
            Name(iSHeader) = "<empty>";
        else
            Name(iSHeader) = string(sectionName);
        end
    end
    sectionHeader.Properties.RowNames=Name;

    disp(sectionHeader)

    % Reading .text section
    instructionMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));
    fseek(fileId,hex2dec(sectionHeader{".text","sh_offset"}),'bof');
    address = hex2dec(sectionHeader{".text","sh_addr"})/(SimuRISC_Constants.XLEN/8);
    for i = 1:hex2dec(sectionHeader{".text","sh_size"})
        instructionMemory(address) = hex2dec(reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []));
        address = address + 1;
    end
    
    % Reading .data section
    dataMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));
    fseek(fileId,hex2dec(sectionHeader{".data","sh_offset"}),'bof');
    address = hex2dec(sectionHeader{".data","sh_addr"})/(SimuRISC_Constants.XLEN/8);
    for i = 1:hex2dec(sectionHeader{".data","sh_size"})
        dataMemory(address) = hex2dec(reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []));
        address = address + 1;
    end
end