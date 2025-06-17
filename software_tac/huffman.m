pkg load communications
message = 'polar codes are employed in 5g due better performance and simplicity';

while true %Create Padding

  symbols = unique(message);
  freq    = histc(message, symbols);
  prob    = freq / sum(freq);

  dict = huffmandict(symbols, prob);

  [~, sig] = ismember(message, symbols);

  encodedMessage = huffmanenco(sig, dict);

      % stop when bit-stream length is divisible by 8
    if mod(length(encodedMessage), 4) == 0
        break;
    endif

    % otherwise append one space and try again
    message = [message ' '];
endwhile

printf('New String with padding:\n');
printf("|%s|\n",message);

decodedSignal = huffmandeco(encodedMessage, dict);
decodedMessage = symbols(decodedSignal);

codeLengths = cellfun(@length, dict(:,2));
avglen = sum(prob .* codeLengths);

entropy = -sum(prob .* log2(prob));

printf('Original Message: %s\n', message);
printf('Integer Signal: ');
for i = 1:length(sig)
    printf('%d ', sig(i));
end
printf('\n');

printf('BitStream Lenght:%d \n\n',numel(encodedMessage))

printf('Encoded Bitstream: ');
for i = 1:length(encodedMessage)
    printf('%d', encodedMessage(i));
end
printf('\n');

printf('Decoded Message: |%s|\n', char(decodedMessage));
printf('Average Codeword Length: %.4f bits\n', avglen);
printf('Source Entropy: %.4f bits/symbol\n', entropy);

%Making a bitstream with more than 1e6 bits
BitStream = encodedMessage;
while length(BitStream) <= 1e6
  BitStream = [BitStream encodedMessage];

endwhile

printf("\n\nFinal BitStream Lenght: %d \n",length(BitStream));
printf('Final Encoded Bitstream: ');
for i = 1:length(encodedMessage)
    printf('%d', encodedMessage(i));
end

decodedSignal = huffmandeco(BitStream, dict);
decodedMessage = symbols(decodedSignal);
printf('\n\nFinal Decoded Message: |%s|\n', char(decodedMessage));

