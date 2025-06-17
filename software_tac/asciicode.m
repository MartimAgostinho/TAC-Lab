
%message = 'polar codes are employed in 5g due better performance and simplicity';
function bitStream = asciicode(message)
    ascii = uint8(message);
    bitStream  = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);

    %Recovering message
    bytes            = reshape(bitStream, 8, []).';       % one row per byte
    ascii_decoded    = bin2dec(char(bytes + '0'));        % double column
    decodedMessage   = char(ascii_decoded).';

    fprintf('BitStream Lenght:%d \n\n',length(bitStream));
    fprintf("Encoded: ");
    fprintf('%c',char(bitStream + '0'));

    fprintf('\n\nDecoded Message: |%s|\n', char(decodedMessage));

end
%Making a bitstream with more than 1e6 bits
%BitStream = bitStream;
%while length(BitStream) <= 1e6
%  BitStream = [BitStream bitStream];

%end

%fprintf("\n\nFinal BitStream Lenght: %d \n",length(BitStream));

%bytes            = reshape(BitStream, 8, []).';       % one row per byte
%ascii_decoded    = bin2dec(char(bytes + '0'));        % double column
%decodedMessage   = char(ascii_decoded).';
%fprintf('\n\nFinal Decoded Message: |%s|\n', char(decodedMessage));
