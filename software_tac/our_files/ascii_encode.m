function bitStream = ascii_encode(message)
    ascii = uint8(message);
    bitStream  = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);
end
