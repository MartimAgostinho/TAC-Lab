function [symbols_qpsk, symbols_16qam] = modulate_message(bitStream)

%%COMANDOS Para a consola:
%%msg = 'polar codes are employed in 5g due better performance and simplicity';
%%[sym_qpsk, sym_16qam] = modulate_message(msg);

    %ascii = uint8(message);
    %bitStream = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);
    
    % 2. Modula QPSK
    bits_len_qpsk = length(bitStream);
    % Trunca para múltiplo de 2 bits
    bits_qpsk = bitStream(1:2*floor(bits_len_qpsk/2));
    symbols_qpsk = modul8(bits_qpsk, 'QPSK');
    
    % 3. Modula 16-QAM
    bits_len_16qam = length(bitStream);
    % Trunca para múltiplo de 4 bits
    bits_16qam = bitStream(1:4*floor(bits_len_16qam/4));
    symbols_16qam = modul8(bits_16qam, '16QAM');
    
end
