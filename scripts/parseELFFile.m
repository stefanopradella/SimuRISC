function [instructionMemory, dataMemory, elfExtras] = parseELFFile(filename, printOutput)
%   PARSEELFFILE - Reads a ELF file and returns the memory data variables.
%   Reference: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
% 
%   [instructionMemory, dataMemory, elfExtras] = parseELFFile();
%   [instructionMemory, dataMemory, elfExtras] = parseELFFile('/home/path/to/file.elf');
%   [instructionMemory, dataMemory, elfExtras] = parseELFFile('/home/path/to/file.elf', 'printOutput');

    arguments
        filename (1,1) string = "";
        printOutput (1,1) string = "";
    end

    if strcmp(filename, "")
        [filename, filepath] = uigetfile('*');
        elfFilePath = strcat(filepath, filename);
    else
        elfFilePath = filename;
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


    switch e_ident(6)
        % this affects interpretation of multi-byte fields starting with offset 0x10. 
        case 1
            endianness = 'l';
        case 2
            endianness = 'b';
        otherwise
            throw(parseMExc)
    end

    if e_ident(7) ~= 1
        throw(parseMExc)
    end

    % Bytes 9-15 padding -> ignored

    e_type = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    e_machine = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);

    % Bytes 20-24 ELF Version
    e_version = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);

    e_entry = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    elfExtras.entryPointAddress = hex2dec(e_entry);
    e_phoff = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    e_shoff = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
    e_flags = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
    e_ehsize =  reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    e_phentsize = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    e_phnum = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    e_shentsize = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    e_shnum = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);
    e_shstrndx = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);

    % Read program header
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

    % Read section header
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


    % Look in .symtab and .strtab for the address of the .tohost variable

    fseek(fileId,hex2dec(sectionHeader{".strtab","sh_offset"}),'bof');
    strtab = char(fread(fileId, hex2dec(sectionHeader{".strtab","sh_size"})))';

    % TODO: implement complete parsing of symbols table, different between
    % 32 and 64 bit ELFs
    if contains(strtab, 'tohost')
        fseek(fileId,hex2dec(sectionHeader{".symtab","sh_offset"}),'bof');
        nEntries = hex2dec(sectionHeader{".symtab","sh_entsize"});

        for i = 1:nEntries

            % Extract fields
            st_name = reshape(dec2hex(fread(fileId, 1, '*ubit32', endianness))', 1, []);
            st_value = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
            st_size = reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []);
            st_info = dec2hex(fread(fileId, 1));
            st_other = dec2hex(fread(fileId, 1));
            st_shndx = reshape(dec2hex(fread(fileId, 1, '*ubit16', endianness))', 1, []);

            % Get symbol name from .strtab
            nameIdx = hex2dec(st_name);
            if nameIdx > 0
                strtab_split = split(strtab(nameIdx+1:end), char(0));
                symbolName = strtab_split{1};
                if isempty(symbolName)
                    symbolName = '<no name>';
                end
            else
                symbolName = '<no name>';
            end

            if strcmp(symbolName, 'tohost')
                elfExtras.tohostVarInfo.address = hex2dec(st_value) - SimuRISC_Constants.RAM_BASE_ADDR;
            end
        end
    end

    % Reading .text section
    instructionMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));
    fseek(fileId,hex2dec(sectionHeader{".text","sh_offset"}),'bof');
    address = (hex2dec(sectionHeader{".text","sh_addr"}) - SimuRISC_Constants.RAM_BASE_ADDR)/(SimuRISC_Constants.XLEN/8) + 1;                % array index is one-based
    for i = 1:hex2dec(sectionHeader{".text","sh_size"})/(SimuRISC_Constants.XLEN/8)
        instructionMemory(address) = hex2dec(reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []));
        address = address + 1;
    end
    
    % Reading .data section
    dataMemory = uint32(zeros(2^SimuRISC_Constants.ADDR_BUS_WIDTH/(SimuRISC_Constants.XLEN/8), 1));
    fseek(fileId,hex2dec(sectionHeader{".data","sh_offset"}),'bof');
    address = (hex2dec(sectionHeader{".data","sh_addr"}) - SimuRISC_Constants.RAM_BASE_ADDR)/(SimuRISC_Constants.XLEN/8) + 1;                % array index is one-based
    for i = 1:hex2dec(sectionHeader{".data","sh_size"})/(SimuRISC_Constants.XLEN/8)
        dataMemory(address) = hex2dec(reshape(dec2hex(fread(fileId, 1, formatVarType, endianness))', 1, []));
        address = address + 1;
    end

    if strcmp(printOutput, "printOutput")
        fprintf('Format: %s\n', format);
        fprintf('Endianness: %s\n', endianness);
        fprintf('ABI ID: 0x%s\n', dec2hex(e_ident(8)));
        fprintf('ABI Version: 0x%s\n', dec2hex(e_ident(9)));
        fprintf('Object type ID: 0x%s\n', e_type);
        fprintf('Target ISA ID: 0x%s\n', e_machine);
        fprintf('Entry point address: 0x%s\n', e_entry);
        fprintf('Program header address: 0x%s\n', e_phoff);
        fprintf('Section header address: 0x%s\n', e_shoff);
        fprintf('Flags: 0x%s\n', e_flags);
        fprintf('Header size: 0x%s\n', e_ehsize);
        fprintf('Program header entries size: 0x%s\n', e_phentsize);
        fprintf('Program header entries number: 0x%s\n', e_phnum);
        fprintf('Section header entry size: 0x%s\n', e_shentsize);
        fprintf('Section header entries number: 0x%s\n', e_shnum);
        fprintf('Section header names entry index: 0x%s\n', e_shstrndx);

        fprintf('=== Program Header ===')
        disp(programHeader)

        fprintf('=== Section Header ===')
        disp(sectionHeader)


    end
end

function typeString = getSymbolType(st_info)
    % Extract the lower 4 bits (symbol type) from st_info
    symbolType = bitand(st_info, 15); % 15 = 0x0F

    % Map the symbol type to a string
    switch symbolType
        case 0
            typeString = 'NOTYPE';
        case 1
            typeString = 'OBJECT';
        case 2
            typeString = 'FUNC';
        case 3
            typeString = 'SECTION';
        case 4
            typeString = 'FILE';
        case 13
            typeString = 'COMMON';
        case 14
            typeString = 'TLS';
        case 15
            typeString = 'LOOS+0'; % OS-specific
        otherwise
            typeString = 'RESERVED';
    end
end
