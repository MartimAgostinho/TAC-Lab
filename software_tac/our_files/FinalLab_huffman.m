EN=[-5:2:22]'+0*100; 
en = 10 .^(EN/10);
CHANNEL='AWGN';
L=1; % L-th order diversity
Ts=4e-6; % Block duration
Tg=0.2*Ts; % Cyclic prefix durration
levels = [-3, -1, 1, 3];

NRay=1;
Eb=1;
Eb_qpsk=1;          %Energia de bit QPSK
Es_qam=10;         %Energia de simbolo 16-QAM

sigma_qpsk=sqrt(Eb_qpsk/2 ./en); 
sigma_qam=sqrt(Es_qam/2/4 ./en); 
NoQAM=2*sigma_qam.^2;
NSR= 1./(4*en); 
NEN=length(EN);
NErr=zeros(NEN,1);

message = 'polar codes are employed in 5g due better performance and simplicity';

%huffman coding
[encodedMessage_huffman, dict_huffman, message_huffman]=huffman_encode(message);
fprintf('Message after padding: |%s|\n',message_huffman);
% %ascii coding
% ascii = uint8(message);
% bitStream_ascii  = reshape(de2bi(ascii, 8, 'left-msb').', 1, []);


%1e6 bits hufman
len_huffman = numel(encodedMessage_huffman);
n_huffman = ceil(1e6 / len_huffman);

% --- Cálculo do ritmo de transmissão ---
num_sym = numel(message_huffman);           % símbolos originais
l_bar = len_huffman / num_sym;            % comprimento médio (bits/símbolo)

N = len_huffman / 4;                      % subportadoras OFDM por slot
T_symbol = Ts + Tg;                         % duração total OFDM
Rs = N / T_symbol;                          % símbolos/s
Rb = l_bar * Rs;                            % bits/s

fprintf('Comprimento médio Huffman: %.2f bits/símbolo\n', l_bar);
fprintf('Taxa de símbolos Rs = %.2f sym/s, taxa de bits Rb = %.2f bits/s\n', Rs, Rb);
% %1e6 bits ascii
% len_ascii = numel(bitStream_ascii);
% n_ascii = ceil(1e6 / len_ascii);


%meter 16qam, ofdm, passar pelo canal e sacar tudo de fora
N = len_huffman/4
NSlot = n_huffman;
f=[-N/2:N/2-1]'/Ts; % frequencies
for nn=1:NSlot
    
    %rand('state',nn*1234567); randn('state',nn*1234567);
    % This means the same channel for each slot
    if (CHANNEL=='RRND')
        Hk=zeros(N,L); 
        tau=rand(NRay,1)*Tg;
            for l=1:L
                alpha=ones(NRay,1).*(randn(NRay,1)+j*randn(NRay,1))/sqrt(2*NRay);
                for nRay=1:NRay
                    Hk(:,l)=Hk(:,l)+alpha(nRay)*exp(-j*2*pi*f*tau(nRay));
                end
            end
       elseif (strcmp(CHANNEL,'RAYL'))
        Hk=(randn(N,L)+j*randn(N,L))/sqrt(2);
    elseif (strcmp(CHANNEL,'AWGN'))
        Hk=ones(N,L).*exp(j*2*pi*rand(N,L))     
    end        
    H2k=abs(Hk).^2;
    if (L==1) sH2k=H2k; else sH2k=sum(H2k')'; end
    % 16-QAM
    bitaux = reshape(encodedMessage_huffman, 4, []).';
    bit1 = bitaux(:, 1);
    bit2 = bitaux(:, 2);
    bit3 = bitaux(:, 3);
    bit4 = bitaux(:, 4);


    B1 = 2*(2*bit1 + bit2) -3 ;
    B2 = 2*(2*bit3 + bit4) -3;

    An_Tx = B1+j*B2;

    Ak_Tx=fftshift(fft(fftshift(An_Tx)));

    message_all = zeros(NEN,length(encodedMessage_huffman));
    for nEN=1:NEN
        Yk=zeros(N,L);
        for l=1:L
            Yk(:,l)=Ak_Tx.*Hk(:,l)+(randn(N,1)+j*randn(N,1))*sigma_qam(nEN); % Ak_NL
        end
        YIk=0;
        for l=1:L
            YIk = YIk +Yk(:,l).*(conj(Hk(:,l))./(sH2k + NSR(nEN)));
        end
        %Received signal
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
        message_received = reshape(bits_matrix.', 1, []);
        message_all(nEN, :) = message_received;
        
        aux = sum(abs(bit1 - b1_Rx) + abs(bit2 - b2_Rx) + abs(bit3 - b3_Rx) + abs(bit4 - b4_Rx));
        NErr(nEN,1)=NErr(nEN,1)+aux;
    end

    if (rem(nn,100)==0) nn, end
end

% BER in Rayleigh channel and L-branch diversity [Proakis]
aux=sqrt(en./(1+en));Pb_tr=0;
for l=0:L-1
    Pb_tr=Pb_tr+Combin(L-1+l,l)*((1+aux)/2).^l;
end
Pb_tr=Pb_tr.*((1-aux)/2).^L;

% BER in AWGN channel
%PbAWGN=q_x(sqrt(2*L*en));
PbAWGN=q_x(sqrt(2*L*en));

Pb=NErr/NSlot/N/4;

%figure;
semilogy(EN,Pb,'k-*',EN,PbAWGN,'b-',EN,Pb_tr,'b*:')
xlabel('E_b/N_0(dB)'),ylabel('BER')
axis([0 20 1e-4 1])
%pause,clf;



%decoding 1e6 huffman
decodedSignal_huffman   = huffmandeco(message_received,dict_huffman);
decodedMessage_huffman  = char(decodedSignal_huffman);
%fprintf('\nFinal decoded message: |%s|\n',decodedMessage_huffman);

for nEN=1:NEN
    decodedSignal_huffman_all = huffmandeco(message_all(nEN, :),dict_huffman);
    decodedMessage_huffman  = char(decodedSignal_huffman_all);
    fprintf('\n %d SNR --> Message decoded :|%s|\n', EN(nEN), decodedMessage_huffman);
end
% %decoding 1e6 ascii
% bytes_ascii = reshape(bitStream_ascii, 8, []).';       % one row per byte
% ascii_decoded = bin2dec(char(bytes_ascii + '0'));        % double column
% decodedMessage_ascii = char(ascii_decoded).';