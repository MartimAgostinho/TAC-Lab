EN=[-5:2:22]'+0*100; 
en = 10 .^(EN/10);
levels = [-3, -1, 1, 3];
message = 'polar codes are employed in 5g due better performance and simplicity';

%huffman coding
[encodedMessage_huffman, dict_huffman, message_huffman]=huffmancode(message);

%ascii coding
ascii = uint8(message);
bitStream_ascii  = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);


%1e6 bits hufman
len_huffman = numel(encodedMessage_huffman);
n_huffman = ceil(1e6 / len_huffman);

%1e6 bits ascii
len_ascii = numel(encodedMessage_huffman);
n_ascii = ceil(1e6 / len_ascii);

%meter 16qam, ofdm, passar pelo canal e sacar tudo de fora

bitaux = reshape(encodedMessage_huffman, 4, []).';
bit1_huffman = bitaux(:, 1);
bit2_huffman = bitaux(:, 2);
bit3_huffman = bitaux(:, 3);
bit4_huffman = bitaux(:, 4);


B1 = 2*(2*bit1_huffman + bit2_huffman) -3 ;
B2 = 2*(2*bit3_huffman + bit4_huffman) -3;
                 
An_Tx = B1+j*B2;%SINAL QPSK
 

Ak_Tx=fftshift(fft(fftshift(An_Tx)));

NSR=1/2 ./(en);
Hk=(randn(len_huffman/4,1)+j*randn(len_huffman/4,1))/sqrt(2);
H2k=abs(Hk).^2;
sH2k=H2k;
Yk(:,1)=Ak_Tx.*Hk(:,1);
YIk = 0;
YIk = YIk +Yk(:,1).*(conj(Hk(:,1))./(sH2k + NSR(14)));

Yin = fftshift(ifft(fftshift(YIk)));


real_quant = arrayfun(@(x) levels(closest_level_idx(x, levels)), real(Yin));
im_quant   = arrayfun(@(x) levels(closest_level_idx(x, levels)), imag(Yin));

real_aux = round((real_quant + 3)/2);
im_aux = round((im_quant + 3)/2);
bit_real_aux = de2bi(real_aux, 2, 'left-msb');
bit_im_aux = de2bi(im_aux, 2, 'left-msb');
b1_Rx=bit_real_aux(:, 1);
b2_Rx=bit_real_aux(:, 2);
b3_Rx=bit_im_aux(:, 1);
b4_Rx=bit_im_aux(:, 2);

bits_matrix = [b1_Rx, b2_Rx, b3_Rx, b4_Rx];
message_received_huffman = reshape(bits_matrix.', 1, []);
%decoding 1e6 huffman
decodedSignal_huffman   = huffmandeco(message_received_huffman,dict_huffman);
decodedMessage_huffman  = char(decodedSignal_huffman);
fprintf('\nFinal decoded message: |%s|\n',decodedMessage_huffman);

%decoding 1e6 ascii
bytes_ascii = reshape(bitStream_ascii, 8, []).';       % one row per byte
ascii_decoded = bin2dec(char(bytes_ascii + '0'));        % double column
decodedMessage_ascii = char(ascii_decoded).';