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
    if mod(length(encodedMessage), 8) == 0
        break;
    endif

    % otherwise append one space and try again
    message = [message ' '];
endwhile

printf('New String with padding:\n');
printf("|%s|\n",message);

printf("Char|Prob|Code|Code Lenght \n");
avglen = 0;
entropy = 0;
for k = 1:length(symbols)
  printf("    \\midrule\n");
  printf("    \'%c\' & %f & ",symbols(k),prob(k))
  printf("%d",dict{1,k})
  printf(" & %d\\\\\n",length(dict{1,k}));
  avglen += length(dict{1,k})*prob(k);
  entropy -= prob(k)*log2(prob(k));
end

printf("Average Code Length: %f\n",avglen);
printf("Source Entropy: %f\n",entropy);
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


