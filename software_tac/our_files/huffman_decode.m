function decodedMessage = huffman_decode(encodedMessage,dict)
    decodedSignal = huffmandeco(encodedMessage, dict);
    decodedMessage = symbols(decodedSignal);
end