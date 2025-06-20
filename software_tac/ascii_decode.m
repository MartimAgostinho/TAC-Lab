
function decodedMessage = ascii_decode(bitStream)

    bytes            = reshape(bitStream, 8, []).';       % one row per byte
    ascii_decoded    = bin2dec(char(bytes + '0'));        % double column
    decodedMessage   = char(ascii_decoded).';

end
