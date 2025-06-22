
% ===============================================================
%  BER Wrapper Script  -  Runs 4 channel/modulation combinations
% ===============================================================
clear; clc;
addpath(pwd);      % make sure modul8 / demodul8 / channel etc. are visible

global NEN;
global frmLen;
global nBlocks;
global blockSize;
global wordSize;
global intrlvrIndices_block;
global intrlvrIndices_blockconv;
global intrlvrIndices;
global n_excess;
global hconv;
global hconvde;
global qamMod;
global qamdemod;
global modQPSK;
global demodQPSK;
global s;
global NSlot;
global tail;
global tailqam;
global data;
global tailblock;

% ---------------- common parameters ----------------------------
EN  = (-5:2:22).';            % Eb/No grid   (column vector)
NEN = numel(EN);
en = 10 .^(EN/10);
noiseVar = 1 ./ (1/3 * 4 .* en);

message = 'polar codes are employed in 5g due better performance and simplicity';

[datahuff, dict, messagepadd] = huffman_encode(message);

data = datahuff';

frmLen = length(data);

NSlot = ceil(1e8 / frmLen)

s = RandStream('mt19937ar', 'Seed', 11);

blockSize = 11;
wordSize = 15;
nBlocks = ceil(frmLen / blockSize);
n_excess = nBlocks * blockSize -frmLen ;
intrlvrIndices_block = randperm(nBlocks * wordSize +3);

intrlvrIndices_blockconv = randperm(3*(nBlocks * wordSize + 6 + 3));

intrlvrIndices = randperm((frmLen + 6)*3);
trellis = poly2trellis(7,[165 171 133]);

tail = zeros(6,1);

tailqam = zeros(ceil((frmLen + 6)*3/4)*4 - (frmLen + 6)*3, 1);

tailblock = zeros(3, 1);

combinations = dec2bin(0:15) - '0';
bits = reshape(combinations.', 1, []);
constellationQAM = modul8(bits,'16QAM')';

combinations = dec2bin(0:3) - '0';
bits = reshape(combinations.', 1, []);
constellationQPSK = modul8(bits,'QPSK')';


hconv = comm.ConvolutionalEncoder('TrellisStructure', trellis);
hconvde = comm.ViterbiDecoder('TrellisStructure', trellis,'InputFormat', 'Hard', 'TerminationMethod','Terminated','TracebackDepth', 30);
hError = comm.ErrorRate;

% store results here:   rows = SNR points, cols = four cases
BERconv         = zeros(NEN,4);     % convolutional only
BERblock        = zeros(NEN,4);     % Hamming only
BERblockConv    = zeros(NEN,4);     % Hamming + conv

PretxBlock      = zeros(NEN,4);     % retrans prob (block)
PretxBlockConv  = zeros(NEN,4);     % retrans prob (block+conv)

PtxBlock = zeros(NEN, 4);
PtxBlockConv = zeros(NEN, 4);

qamMod = comm.GeneralQAMModulator(constellationQAM);
qamdemod = comm.GeneralQAMDemodulator('Constellation',constellationQAM, ...
    'BitOutput', 1,'DecisionMethod','Hard decision');

modQPSK = comm.GeneralQAMModulator('Constellation', constellationQPSK);

demodQPSK = comm.GeneralQAMDemodulator( ...
    'Constellation', constellationQPSK, ...
    'BitOutput', 1, ...
    'DecisionMethod', 'Hard decision');


labels  = { 'AWGN  +  QPSK' , 'AWGN  + 16QAM' , ...
            'RAYL  +  QPSK' , 'RAYL  + 16QAM' };

% ---------------- loop over the 4 cases ------------------------
channels    = {'AWGN','AWGN','RAYL','RAYL'};
modulations = {'QPSK','16QAM','QPSK','16QAM'};

for c = 1:4

    CHANNEL    = channels{c};
    modulation = modulations{c};
    fprintf('\n=== %s  |  %s ===\n', CHANNEL, modulation);

    % ========= call your existing code block A (Convolutional) ====
    BERconv(:,c) = runConvBlock(CHANNEL, modulation, noiseVar);

    % ========= call your existing code block B (Hamming) ==========
    [BERblock(:,c), PretxBlock(:,c), PtxBlock(:,c)] = runBlock(CHANNEL, modulation, noiseVar);

    % ========= call your existing code block C (Block + Conv) =====
    [BERblockConv(:,c), PretxBlockConv(:,c),PtxBlockConv(:,c)] = ...
                                runBlockConv(CHANNEL, modulation, noiseVar);
end

% ---------------------------------------------------------------
%  FIGURE 1 : convolutional code only
% ---------------------------------------------------------------
figure(1); clf; hold on; grid on;
style = {'b-*','b--o','g-s','g:.'};
for c = 1:4
    semilogy( EN , BERconv(:,c) , style{c} , 'LineWidth',1.4 );
end
set(gca, 'YScale', 'log');
xlabel('E_b/N_0  (dB)'); ylabel('BER');
title('BER – convolutional code only');
legend(labels,'Location','southwest');
axis([-5 22 1e-7 1]);

% ---------------------------------------------------------------
%  FIGURE 2 : Hamming block code
% ---------------------------------------------------------------
figure(2); clf; grid on; hold on;
for c = 1:4
    semilogy( EN , BERblock(:,c) , style{c} , 'LineWidth',1.4 );
end
for c = 1:4
    semilogy( EN , PtxBlock(:,c) , [style{c}(1) '--'] , 'LineWidth',1.0);
end
set(gca, 'YScale', 'log');
xlabel('E_b/N_0  (dB)'); ylabel('BER / P_{re-tx}');
title('BER and re-tx probability – Hamming block');
legend([labels , strcat({'P_{re-}'},labels)],'Location','southwest');
axis([-5 22 1e-7 1]);

% ---------------------------------------------------------------
%  FIGURE 3 : Block + Convolutional
% ---------------------------------------------------------------
figure(3); clf; grid on; hold on;
for c = 1:4
    semilogy( EN , BERblockConv(:,c) , style{c} , 'LineWidth',1.4 );
end
for c = 1:4
    semilogy( EN , PtxBlockConv(:,c) , [style{c}(1) '--'] , 'LineWidth',1.0);
end
set(gca, 'YScale', 'log');
xlabel('E_b/N_0  (dB)'); ylabel('BER / P_{re-tx}');
title('BER and re-tx probability – block + convolutional');
legend([labels , strcat({'P_{re-}'},labels)],'Location','southwest');
axis([-5 22 1e-7 1]);

% ===============================================================
%  === Helper routines: paste your existing code blocks inside ===
% ===============================================================

function BER = runConvBlock(CHANNEL,modulation,noiseVar)
    % ---- paste your original convolutional loop here ----
    % must output vector BER (length = length(EN))
    global NEN;
    global frmLen;
    global intrlvrIndices;
    global hconv;
    global hconvde;
    global qamMod;
    global qamdemod;
    global modQPSK;
    global demodQPSK;
    global s;
    global NSlot;
    global tail;
    global tailqam;
    global data;
    hError = comm.ErrorRate;
    NErr1=zeros(NEN,1);
    NErr2=zeros(NEN,1);
    NErr3=zeros(NEN,1);
    for nEN=1:NEN
        hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
        if(strcmp(modulation, '16QAM') == 1)
            h = (randn(ceil((frmLen+6) * 3 / 4), 1) + 1j * randn(ceil((frmLen+6) * 3 / 4), 1)) / sqrt(2);
        elseif(strcmp(modulation, 'QPSK') == 1)
            h = (randn((frmLen+6) * 3 / 2, 1) + 1j * randn((frmLen+6) * 3 / 2, 1)) / sqrt(2);
        end
        reset(hError);
        reset(hconvde);
        for frmIdx = 1:NSlot
            encodedData = step(hconv, [data; tail]);
            interData = intrlv(encodedData, intrlvrIndices);
            if(strcmp(modulation, '16QAM') == 1)
                
                encodedDataMatrix = reshape([interData;tailqam], 4, []).';        % Cada linha: 4 bits
                symbols = bi2de(encodedDataMatrix, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignal = step(qamMod, symbols);
            elseif(strcmp(modulation, 'QPSK') == 1)
                encodedDataMatrix = reshape(interData, 2, []).';        % Cada linha: 4 bits
                symbols = bi2de(encodedDataMatrix, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignal = step(modQPSK, symbols);
            end
            
            if (strcmp(CHANNEL, 'AWGN') == 1)
                channelSignal = step(hChanAWGN, modSignal);
                eqSignal = channelSignal;
            elseif(strcmp(CHANNEL, 'RAYL') == 1)
                channelSignalRayl = modSignal .* h;
                channelSignal = step(hChanAWGN, channelSignalRayl);
                eqSignal = channelSignal ./ h;
            end
            

            %in a rayleigh channel it is necessary to de-interleave demodulated bits before

            %decoding
            if(strcmp(modulation, '16QAM') == 1)
                receivedSignal = step(qamdemod, eqSignal);
            elseif(strcmp(modulation, 'QPSK') == 1)
                receivedSignal = step(demodQPSK, eqSignal);
            end
            

            % Convert received signal to log-likelihood ratios for decoding
            deinterSignal = deintrlv(receivedSignal(1:length(interData)), intrlvrIndices);
            decodedBits  = step(hconvde, deinterSignal);
            receivedBits  = decodedBits(1:length(data));

            errorStats = step(hError, data, receivedBits);


        end
        NErr1(nEN,1)=errorStats(1);
        NErr2(nEN,1)=errorStats(2);
        NErr3(nEN,1)=errorStats(3);
    end

    BER=NErr1;
    Nerros=NErr2;
    bitsTotal=NErr3;
    %error('runConvBlock not yet implemented');
end

function [BERBlock,PretxBlock, PtxBlock] = runBlock(CHANNEL,modulation,noiseVar)
    % ---- paste your original Hamming-only loop here ----
    % Pretx must be computed with block length = 11
    global NEN;
    global nBlocks;
    global intrlvrIndices_block;
    global blockSize;
    global wordSize;
    global n_excess;
    global hconvde;
    global qamMod;
    global qamdemod;
    global modQPSK;
    global demodQPSK;
    global NSlot;
    global data;
    global tailblock;
    NErrBlock=zeros(NEN,1);
    NErr1Block=zeros(NEN,1);
    NErr2Block=zeros(NEN,1);
    NErr3Block=zeros(NEN,1);
    hError = comm.ErrorRate;
    for nEN=1:NEN
        hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
        if(strcmp(modulation, '16QAM') == 1)
            hBlock = (randn(ceil((nBlocks*15 +3)/4), 1) + 1j * randn(ceil((nBlocks*15 +3)/4), 1)) / sqrt(2);
        elseif(strcmp(modulation, 'QPSK') == 1)
            hBlock = (randn(ceil((nBlocks*15 +3)/2), 1) + 1j * randn(ceil((nBlocks*15 +3)/2), 1)) / sqrt(2);
        end
        reset(hError);
        reset(hconvde);
        for frmIdx = 1:NSlot
            dataPadded = [data; zeros(n_excess,1)];
            dataMatrix = reshape(dataPadded, blockSize, []).';
            codedMatrix = zeros(nBlocks, wordSize);
            for i = 1:nBlocks
                codedMatrix(i, :) = encode(dataMatrix(i, :)', wordSize, blockSize, 'hamming/binary')';
            end

            % Vetor codificado completo
            encodedDataBlock = reshape(codedMatrix.', [], 1);
            
            dataMatrixCode = reshape(encodedDataBlock, wordSize, []).';

            interDataBlock = intrlv([encodedDataBlock;tailblock], intrlvrIndices_block);

            if(strcmp(modulation, '16QAM') == 1)
                encodedDataMatrixBlock = reshape(interDataBlock, 4, []).';        % Cada linha: 4 bits
                symbolsBlock = bi2de(encodedDataMatrixBlock, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignalBlock = step(qamMod, symbolsBlock);
            elseif(strcmp(modulation, 'QPSK') == 1)
                encodedDataMatrixBlock = reshape(interDataBlock, 2, []).';        % Cada linha: 4 bits
                symbolsBlock = bi2de(encodedDataMatrixBlock, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignalBlock = step(modQPSK, symbolsBlock);
            end


            if (strcmp(CHANNEL, 'AWGN') == 1)
                channelSignalBlock = step(hChanAWGN, modSignalBlock);
                eqSignalBlock = channelSignalBlock;
            elseif(strcmp(CHANNEL, 'RAYL') == 1)
                channelSignalRaylBlock = modSignalBlock .* hBlock;
                channelSignalBlock = step(hChanAWGN, channelSignalRaylBlock);
                eqSignalBlock = channelSignalBlock ./ hBlock;
            end

            %in a rayleigh channel it is necessary to de-interleave demodulated bits before

            %decoding
            if(strcmp(modulation, '16QAM') == 1)
                receivedSignalBlock = step(qamdemod, eqSignalBlock);
            elseif(strcmp(modulation, 'QPSK') == 1)
                receivedSignalBlock = step(demodQPSK, eqSignalBlock);
            end        
            % Convert received signal to log-likelihood ratios for decoding
            deinterSignalBlock = deintrlv(receivedSignalBlock, intrlvrIndices_block);
            receivedBitsBlock  = decode(deinterSignalBlock(1:length(encodedDataBlock)),wordSize,blockSize,'hamming/binary');
            
            dataMatrixBlockdec = reshape(deinterSignalBlock(1:length(encodedDataBlock)), wordSize, []).';
            errCountsBlock = sum(dataMatrixCode ~= dataMatrixBlockdec, 2);
            
            aux = (errCountsBlock == 2) | (errCountsBlock == 3);
            
            NErrBlock(nEN,1)=NErrBlock(nEN,1)+sum(aux);
            errorStatsBlock = step(hError, dataPadded, receivedBitsBlock);


        end
        NErr1Block(nEN,1)=errorStatsBlock(1);
        NErr2Block(nEN,1)=errorStatsBlock(2);
        NErr3Block(nEN,1)=errorStatsBlock(3);
    end
    
    PtxBlock = NErrBlock/nBlocks/NSlot;
    BERBlock=NErr1Block;
    NerrosBlock=NErr2Block;
    bitsTotalBlock=NErr3Block;

    P0Block = (1 - BERBlock).^blockSize;
    P1Block = blockSize .* BERBlock .* (1 - BERBlock).^(blockSize - 1);

    PretxBlock = 1 - (P0Block + P1Block);
    %error('runBlock not yet implemented');
end

function [BERBlockConv,PretxBlockConv, PtxBlockConv] = runBlockConv(CHANNEL,modulation,noiseVar)
    % ---- paste your original block+conv loop here ----
    % Pretx computed with block length = 11
    global NEN;
    global nBlocks;
    global intrlvrIndices_blockconv;
    global blockSize;
    global wordSize;
    global hconv;
    global hconvde;
    global n_excess;
    global qamMod;
    global qamdemod;
    global modQPSK;
    global demodQPSK;
    global NSlot;
    global tail;
    global tailqam;
    global data;
    global tailblock;
    hError = comm.ErrorRate;
    NErrBlockConv=zeros(NEN,1);
    NErr1BlockConv=zeros(NEN,1);
    NErr2BlockConv=zeros(NEN,1);
    NErr3BlockConv=zeros(NEN,1);
    for nEN=1:NEN
        hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
        if(strcmp(modulation, '16QAM') == 1)
            hBlockConv = (randn(ceil((nBlocks*15+6 +3)*3/4), 1) + 1j * randn(ceil((nBlocks*15+6 +3)*3/4), 1)) / sqrt(2);
        elseif(strcmp(modulation, 'QPSK') == 1)
            hBlockConv = (randn(ceil((nBlocks*15+6 +3)*3/2), 1) + 1j * randn(ceil((nBlocks*15+6 +3)*3/2), 1)) / sqrt(2);
        end
        reset(hError);
        reset(hconvde);
        for frmIdx = 1:NSlot
            dataPaddedConv = [data; zeros(n_excess,1)];
            dataMatrixConv = reshape(dataPaddedConv, blockSize, []).';
            codedMatrixConv = zeros(nBlocks, wordSize);
            for i = 1:nBlocks
                codedMatrixConv(i, :) = encode(dataMatrixConv(i, :)', wordSize, blockSize, 'hamming/binary')';
            end

            % Vetor codificado completo
            encodedDataBlockConv = reshape(codedMatrixConv.', [], 1);
            
            dataMatrixConvCode = reshape(encodedDataBlockConv, wordSize, []).';
            
            tailblockconv = [tailblock;tail];
            %conv
            encodedDataBlockConvFinal = step(hconv, [encodedDataBlockConv;tailblockconv]);
            interDataBlockConv = intrlv(encodedDataBlockConvFinal, intrlvrIndices_blockconv);
            if(strcmp(modulation, '16QAM') == 1)
                encodedDataMatrixBlockConv = reshape([interDataBlockConv;tailqam], 4, []).';        % Cada linha: 4 bits
                symbolsBlockConv = bi2de(encodedDataMatrixBlockConv, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignalBlockConv = step(qamMod, symbolsBlockConv);
            elseif(strcmp(modulation, 'QPSK') == 1)
                encodedDataMatrixBlockConv = reshape(interDataBlockConv, 2, []).';        % Cada linha: 4 bits
                symbolsBlockConv = bi2de(encodedDataMatrixBlockConv, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignalBlockConv = step(modQPSK, symbolsBlockConv);
            end



            if (strcmp(CHANNEL, 'AWGN') == 1)
                channelSignalBlockConv = step(hChanAWGN, modSignalBlockConv);
                eqSignalBlockConv = channelSignalBlockConv;
            elseif(strcmp(CHANNEL, 'RAYL') == 1)
                channelSignalRaylBlockConv = modSignalBlockConv .* hBlockConv;
                channelSignalBlockConv = step(hChanAWGN, channelSignalRaylBlockConv);
                eqSignalBlockConv = channelSignalBlockConv ./ hBlockConv;
            end
            %in a rayleigh channel it is necessary to de-interleave demodulated bits before

            %decoding;
            if(strcmp(modulation, '16QAM') == 1)
                receivedSignalBlockConv = step(qamdemod, eqSignalBlockConv);
            elseif(strcmp(modulation, 'QPSK') == 1)
                receivedSignalBlockConv = step(demodQPSK, eqSignalBlockConv);
            end   
            % Convert received signal to log-likelihood ratios for decoding
            deinterSignalBlockConv = deintrlv(receivedSignalBlockConv(1:length(interDataBlockConv)), intrlvrIndices_blockconv);
            decodedBitsBlockConv  = step(hconvde, deinterSignalBlockConv);
            receivedBitsBlockConv  = decodedBitsBlockConv(1:length(encodedDataBlockConv)+3);
            receivedBitsBlockConvFinal  = decode(receivedBitsBlockConv(1:length(encodedDataBlockConv)),wordSize,blockSize,'hamming/binary');
            
            dataMatrixBlockConvdec = reshape(receivedBitsBlockConv(1:length(encodedDataBlockConv)), wordSize, []).';
            errCountsBC = sum(dataMatrixConvCode ~= dataMatrixBlockConvdec, 2);
            
            auxbc = (errCountsBC == 2) | (errCountsBC == 3);
            
            NErrBlockConv(nEN,1)=NErrBlockConv(nEN,1)+sum(auxbc);
            
            errorStatsBlockConv = step(hError, dataPaddedConv, receivedBitsBlockConvFinal);


        end
        NErr1BlockConv(nEN,1)=errorStatsBlockConv(1);
        NErr2BlockConv(nEN,1)=errorStatsBlockConv(2);
        NErr3BlockConv(nEN,1)=errorStatsBlockConv(3);
    end

    PtxBlockConv = NErrBlockConv/nBlocks/NSlot;
    BERBlockConv=NErr1BlockConv;
    NerrosBlockConv=NErr2BlockConv;
    bitsTotalBlockConv=NErr3BlockConv;

    P0BlockConv = (1 - BERBlockConv).^blockSize;
    P1BlockConv = blockSize .* BERBlockConv .* (1 - BERBlockConv).^(blockSize - 1);

    PretxBlockConv = 1 - (P0BlockConv + P1BlockConv);  % vetor da probabilidade de retransmissão

    %error('runBlockConv not yet implemented');
end
