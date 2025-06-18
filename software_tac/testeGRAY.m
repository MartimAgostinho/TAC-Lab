EN = [-5:2:22]';
en = 10 .^(EN/10);
levels = [-3, -1, 1, 3];
message = 'polar codes are employed in 5g due better performance and simplicity';

% Huffman coding
[encodedMessage_huffman, dict_huffman, message_huffman] = huffmancode(message);
fprintf('Message after padding: |%s|\n', message_huffman);

% ASCII coding
ascii = uint8(message);
bitStream_ascii = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);

% 1e6 bits huffman
len_huffman = numel(encodedMessage_huffman);
n_huffman = ceil(1e6 / len_huffman);

% 1e6 bits ascii
len_ascii = numel(bitStream_ascii);
n_ascii = ceil(1e6 / len_ascii);

% Trabalhar com Huffman codificado
bitaux = reshape(encodedMessage_huffman, 4, []).';
bit1_huffman = bitaux(:, 1);
bit2_huffman = bitaux(:, 2);
bit3_huffman = bitaux(:, 3);
bit4_huffman = bitaux(:, 4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%GRAY(GAY)%%%%%%%%%%
% ✅ Mapeamento Gray (TX)
gray_map = [0 1 3 2];  % 00->0, 01->1, 11->3, 10->2
symI = gray_map(bit1_huffman*2 + bit2_huffman + 1);  % índice 0-based
symQ = gray_map(bit3_huffman*2 + bit4_huffman + 1);
B1 = 2 * symI - 3;  % Níveis I: -3, -1, 1, 3
B2 = 2 * symQ - 3;  % Níveis Q


An_Tx = B1 + 1j * B2;  %Sinal 16-QAM

Ak_Tx = fftshift(fft(fftshift(An_Tx)));

NSR = 1/2 ./ en;
Hk = (randn(len_huffman/4,1) + 1j*randn(len_huffman/4,1)) / sqrt(2);
H2k = abs(Hk).^2;
sH2k = H2k;

Yk(:,1) = Ak_Tx .* Hk(:,1);
YIk = Yk(:,1) .* (conj(Hk(:,1)) ./ (sH2k + NSR(14)));  % Canal com equalização MMSE

Yin = fftshift(ifft(fftshift(YIk)));

% Quantização
real_quant = arrayfun(@(x) levels(closest_level_idx(x, levels)), real(Yin));
im_quant = arrayfun(@(x) levels(closest_level_idx(x, levels)), imag(Yin));

% ✅ Demapeamento Gray (RX)
inv_gray = [0 1 3 2];  % índice Gray -> binário

idx_real = round((real_quant + 3)/2);  % 0 a 3
idx_im = round((im_quant + 3)/2);      % 0 a 3

sym_real = inv_gray(idx_real + 1);  % +1 para 1-based indexing
sym_im = inv_gray(idx_im + 1);

bit_real_aux = de2bi(sym_real, 2, 'left-msb');
bit_im_aux = de2bi(sym_im, 2, 'left-msb');

b1_Rx = bit_real_aux(:, 1);
b2_Rx = bit_real_aux(:, 2);
b3_Rx = bit_im_aux(:, 1);
b4_Rx = bit_im_aux(:, 2);

bits_matrix = [b1_Rx, b2_Rx, b3_Rx, b4_Rx];
message_received_huffman = reshape(bits_matrix.', 1, []);

% Decoding Huffman
decodedSignal_huffman = huffmandeco(message_received_huffman, dict_huffman);
decodedMessage_huffman = char(decodedSignal_huffman);
fprintf('\nFinal decoded Huffman message: |%s|\n', decodedMessage_huffman);

% Decoding ASCII
bytes_ascii = reshape(bitStream_ascii, 8, []).';  % one row per byte
ascii_decoded = bin2dec(char(bytes_ascii + '0'));  % double column
decodedMessage_ascii = char(ascii_decoded).';
