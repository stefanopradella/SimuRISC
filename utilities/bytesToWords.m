function wordsOut = bytesToWords(bytesIn, endianness)
%   BYTESTOWORDS - Converts an m by n matrix of bytes into an array of m words, reading bytes along the first dimension.
%   supports word lengths of 16, 32, 64 bits
    arguments
        bytesIn (:,:) {mustBeNumeric}
        endianness (1,1) string {mustBeMember(endianness, ["little-endian", "big-endian"])} = "big-endian"
    end
    
    if strcmp(endianness, "big-endian")
        bytesIn = fliplr(bytesIn);
    end

    wordLength = size(bytesIn, 2)*8;
    if ~ismember(wordLength, [16, 32,64])
        error("unsupported word length, see help")
    end

    wordsOut = zeros(size(bytesIn, 1), 1);
    for i = 1:size(bytesIn, 1)
        wordsOut(i) = typecast(uint8(bytesIn(i, :)),['uint', num2str(wordLength)]);
    end
    
end