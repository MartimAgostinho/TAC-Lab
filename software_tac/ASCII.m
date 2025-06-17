pkg load communications
message = 'polar codes are employed in 5g due better performance and simplicity';

ascii = uint8(message);
bitStream  = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);

%Recovering message
bytes            = reshape(bitStream, 8, []).';       % one row per byte
ascii_decoded    = bin2dec(char(bytes + '0'));        % double column
decodedMessage   = char(ascii_decoded).';

printf('BitStream Lenght:%d \n\n',length(bitStream))
printf("Encoded: ");
printf('%c',char(bitStream + '0'));

printf('\n\nDecoded Message: |%s|\n', char(decodedMessage));


%Making a bitstream with more than 1e6 bits
BitStream = bitStream;
while length(BitStream) <= 1e6
  BitStream = [BitStream bitStream];

endwhile

printf("\n\nFinal BitStream Lenght: %d \n",length(BitStream));

bytes            = reshape(BitStream, 8, []).';       % one row per byte
ascii_decoded    = bin2dec(char(bytes + '0'));        % double column
decodedMessage   = char(ascii_decoded).';
#printf('\n\nFinal Decoded Message: |%s|\n', char(decodedMessage));
