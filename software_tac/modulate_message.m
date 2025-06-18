function [symbols_qpsk, symbols_16qam] = modulate_message(message)

%%COMANDOS Para a consola:
%%msg = 'polar codes are employed in 5g due better performance and simplicity';
%%[sym_qpsk, sym_16qam] = modulate_message(msg);


    % 1. Converte mensagem para ASCII bits (8 bits por caractere)
    ascii = uint8(message);
    bitStream = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);
    
    % 2. Modula QPSK
    bits_len_qpsk = length(bitStream);
    % Trunca para múltiplo de 2 bits
    bits_qpsk = bitStream(1:2*floor(bits_len_qpsk/2));
    symbols_qpsk = modulate(bits_qpsk, 'QPSK');
    
    % 3. Modula 16-QAM
    bits_len_16qam = length(bitStream);
    % Trunca para múltiplo de 4 bits
    bits_16qam = bitStream(1:4*floor(bits_len_16qam/4));
    symbols_16qam = modulate(bits_16qam, '16QAM');
    
end

% Função auxiliar genérica para modulação
function symbols = modulate(bits, mode)
    bits = bits(:).'; % line vect
    switch upper(mode)
        case 'QPSK'
            if mod(length(bits), 2) ~= 0
                error('bitStream length must be multiple of 2 for QPSK');
            end
            b = reshape(bits, 2, []).';
            k = [0 1 3 2];
            gray_map = exp(1i*(pi/2)*(k+0.5))
            %gray_map = [1+1j, -1+1j, -1-1j, 1-1j];
            idx = b(:,1)*2 + b(:,2) + 1;
            symbols = gray_map(idx).';
            
            
            %symbols = symbols / sqrt(2);
        case '16QAM'
            if mod(length(bits), 4) ~= 0
                error('bitStream length must be multiple of 4 for 16-QAM');
            end
            b = reshape(bits, 4, []).';
            gray_map = [0 1 3 2];
            idxI = b(:,1)*2 + b(:,2) + 1;
            idxQ = b(:,3)*2 + b(:,4) + 1;
            symI = gray_map(idxI);
            symQ = gray_map(idxQ);
            B1 = 2*symI - 3;
            B2 = 2*symQ - 3;
            symbols = B1 + 1j*B2;

        otherwise
            error('Error: not divisable by 4');
    end
end
