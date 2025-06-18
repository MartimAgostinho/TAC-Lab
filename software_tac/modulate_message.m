function [symbols_qpsk, symbols_16qam] = modulate_message(message)


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
            k = [0:3];
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
            %symbols = symbols / sqrt(10);
        otherwise
            error('fudeu');
    end
end
combinations = dec2bin(0:15) - '0'; % generate combinations
bits = reshape(combinations.', 1, []); % convert to bitstream

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

figure;


plot(real(symbols), imag(symbols), 'o', 'MarkerSize',8, 'MarkerFaceColor',[0 101/255 189/255]);
grid on;
axis equal;
xlabel('Imaginary');
ylabel('Real');
title('16-QAM Constellation');
hold on;
xlim([-4 4])
ylim([-4 4])
xl = xlim;                              % current x-axis limits
yl = ylim;                              % current y-axis limits
plot([xl(1) xl(2)], [0 0], 'k', 'LineWidth', 1)   % Q-axis (horizontal)
plot([0 0], [yl(1) yl(2)], 'k', 'LineWidth', 1)   % I-axis (vertical)
% Annotate each point with its corresponding bit combination
for k = 1:length(symbols)
    bit_label = num2str(combinations(k,:));
    text(real(symbols(k)) + 0.2, imag(symbols(k)), bit_label, 'FontSize', 8, 'Color', 'red');
end
