message = 'polar codes are employed in 5g due better performance and simplicity';

%huffman coding
[encodedMessage_huffman, dict_huffman, message_huffman]=huffmancode(message);

%ascii coding
ascii = uint8(message);
bitStream_ascii  = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);


%1e6 bits hufman
BitStream_huffman = repmat(encodedMessage_huffman,1,ceil(1e6 / numel(encodedMessage_huffman)));

%1e6 bits ascii
BitStream_ascii = bitStream_ascii;
while length(BitStream_ascii) <= 1e6
  BitStream_ascii = [BitStream_ascii bitStream_ascii];

end

%meter 16qam, ofdm, passar pelo canal e sacar tudo de fora


%decoding 1e6 huffman
decodedSignal_huffman   = huffmandeco(BitStream_huffman,dict_huffman);
decodedMessage_huffman  = char(decodedSignal_huffman);
%fprintf('\nFinal decoded message: |%s|\n',decodedMessage_huffman);

%decoding 1e6 ascii
bytes_ascii = reshape(BitStream_ascii, 8, []).';       % one row per byte
ascii_decoded = bin2dec(char(bytes_ascii + '0'));        % double column
decodedMessage_ascii = char(ascii_decoded).';