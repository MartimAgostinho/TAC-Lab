function [encodedMessage, dict, message]=huffman_encode(message)
    while true          % ── create padding until the Huffman bit-stream length is a multiple of 8
        msgCodes                = double(message);                 % numeric form of every character
        [symbols,~,sig]         = unique(msgCodes,'stable');        % “stable” keeps the first-seen order
        freq = accumarray(sig, 1);               % counts of every symbol
        prob                    = freq ./ numel(msgCodes);          % probabilities

        dict            = huffmandict(symbols,prob);                % build Huffman dictionary
        encodedMessage  = huffmanenco(msgCodes,dict);               % encode directly as ASCII values

        if mod(numel(encodedMessage),8)==0      % divisible by 8 bits?  yes → stop padding
            break;
        end

        message = [message ' '];                % otherwise append a space and try again
    end
end