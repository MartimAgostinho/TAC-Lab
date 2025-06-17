% Requires the Communications Toolbox
% (MATLAB loads the toolbox functions automatically – no "pkg load" line)

%message = 'polar codes are employed in 5g due better performance and simplicity';

function [encodedMessage, dict, message]=huffmancode(message)
    while true          % ── create padding until the Huffman bit-stream length is a multiple of 8
        msgCodes                = double(message);                 % numeric form of every character
        [symbols,~,sig]         = unique(msgCodes,'stable');        % “stable” keeps the first-seen order
        freq = accumarray(sig, 1);               % counts of every symbol
        prob                    = freq ./ numel(msgCodes);          % probabilities

        dict            = huffmandict(symbols,prob);                % build Huffman dictionary
        encodedMessage  = huffmanenco(msgCodes,dict);               % encode directly as ASCII values

        if mod(numel(encodedMessage),4)==0      % divisible by 8 bits?  yes → stop padding
            break;
        end

        message = [message ' '];                % otherwise append a space and try again
    end

    %fprintf('New string with padding:\n|%s|\n\n',message);

    %decodedSignal   = huffmandeco(encodedMessage,dict);
    %decodedMessage  = char(decodedSignal);

    %codeLengths     = cellfun(@length,dict(:,2));
    %avglen          = sum(prob .* codeLengths);
    %entropyVal      = -sum(prob .* log2(prob));

    %fprintf('Original message: %s\n',message);
    %fprintf('Integer signal:   ');  fprintf('%d ',msgCodes);  fprintf('\n');
    %fprintf('Bit-stream length: %d bits\n\n',numel(encodedMessage));

    %fprintf('Encoded bit-stream: ');
    %fprintf('%d',encodedMessage);  fprintf('\n');

    %fprintf('Decoded message: |%s|\n',decodedMessage);
    %fprintf('Average codeword length: %.4f bits\n',avglen);
    %fprintf('Source entropy:          %.4f bits/symbol\n',entropyVal);

    % -------- Make a ≥ 1 000 000-bit stream -------------------------------
    %BitStream   = repmat(encodedMessage,1,ceil(1e6/numel(encodedMessage)));
    %BitStream   = BitStream(1:1e6);           % exact length: 1 000 000 bits

    %fprintf('\n\nFinal bit-stream length: %d bits\n',numel(BitStream));
    %fprintf('First copy of encoded bit-stream: ');
    %fprintf('%d',encodedMessage);  fprintf('\n');
end
