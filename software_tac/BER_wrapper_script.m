
% ===============================================================
%  BER Wrapper Script  -  Runs 4 channel/modulation combinations
% ===============================================================

clear; clc;
addpath(pwd);      % make sure modul8 / demodul8 / channel etc. are visible

% ---------------- common parameters ----------------------------
EN  = (-5:2:22).';            % Eb/No grid   (column vector)
NEN = numel(EN);

% store results here:   rows = SNR points, cols = four cases
BERconv         = zeros(NEN,4);     % convolutional only
BERblock        = zeros(NEN,4);     % Hamming only
BERblockConv    = zeros(NEN,4);     % Hamming + conv

PretxBlock      = zeros(NEN,4);     % retrans prob (block)
PretxBlockConv  = zeros(NEN,4);     % retrans prob (block+conv)

qamMod = comm.GeneralQAMModulator(constellation');
qamdemod = comm.GeneralQAMDemodulator('Constellation',constellation', ...
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
    BERconv(:,c) = runConvBlock(CHANNEL, modulation, EN);

    % ========= call your existing code block B (Hamming) ==========
    [BERblock(:,c), PretxBlock(:,c)] = runBlock(CHANNEL, modulation, EN);

    % ========= call your existing code block C (Block + Conv) =====
    [BERblockConv(:,c), PretxBlockConv(:,c)] = ...
                                runBlockConv(CHANNEL, modulation, EN);
end

% ---------------------------------------------------------------
%  FIGURE 1 : convolutional code only
% ---------------------------------------------------------------
figure(1); clf; hold on; grid on;
style = {'b-*','b--o','g-s','g:.'};
for c = 1:4
    semilogy( EN , BERconv(:,c) , style{c} , 'LineWidth',1.4 );
end
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
    semilogy( EN , PretxBlock(:,c) , [style{c}(1) '--'] , 'LineWidth',1.0);
end
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
    semilogy( EN , PretxBlockConv(:,c) , [style{c}(1) '--'] , 'LineWidth',1.0);
end
xlabel('E_b/N_0  (dB)'); ylabel('BER / P_{re-tx}');
title('BER and re-tx probability – block + convolutional');
legend([labels , strcat({'P_{re-}'},labels)],'Location','southwest');
axis([-5 22 1e-7 1]);

% ===============================================================
%  === Helper routines: paste your existing code blocks inside ===
% ===============================================================

function BER = runConvBlock(CHANNEL,modulation,EN)
    % ---- paste your original convolutional loop here ----
    % must output vector BER (length = length(EN))
    
    for nEN=1:NEN
    hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
    h = (randn(frmLen * 3 / 4, 1) + 1j * randn(frmLen * 3 / 4, 1)) / sqrt(2);
    
    reset(hError);
    reset(hconvde);
        for frmIdx = 1:10000
            data = randi(s, [0 1], frmLen, 1);

            encodedData = step(hconv, data);
            interData = intrlv(encodedData, intrlvrIndices);
            if(strcmp(modulation, '16QAM') == 0)
                encodedDataMatrix = reshape(interData, 4, []).';        % Cada linha: 4 bits
                symbols = bi2de(encodedDataMatrix, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignal = step(qamMod, symbols);
            elseif(strcmp(modulation, 'QPSK') == 0)
                encodedDataMatrix = reshape(interData, 2, []).';        % Cada linha: 4 bits
                symbols = bi2de(encodedDataMatrix, 'left-msb');
                %in a rayleigh channel it is necessary to interleave bits before modulation

                modSignal = step(modQPSK, symbols);
            end
            
            if (strcmp(CHANNEL, 'AWGN') == 0)
                channelSignal = step(hChanAWGN, modSignal);
                eqSignal = channelSignal;
            elseif(strcmp(CHANNEL, 'RAYL') == 0)
                channelSignalRayl = modSignal .* h;
                channelSignal = step(hChanAWGN, channelSignalRayl);
                eqSignal = channelSignal ./ h;
            end
            

            %in a rayleigh channel it is necessary to de-interleave demodulated bits before

            %decoding
            if(strcmp(modulation, '16QAM') == 0)
                receivedSignal = step(qamdemod, eqSignal);
            elseif(strcmp(modulation, 'QPSK') == 0)
                receivedSignal = step(demodQPSK, eqSignal);
            end
            

            % Convert received signal to log-likelihood ratios for decoding
            deinterSignal = deintrlv(receivedSignal, intrlvrIndices);
            receivedBits  = step(hconvde, deinterSignal);

            errorStats = step(hError, data, receivedBits);


        end
    NErr1(nEN,1)=errorStats(1);
    NErr2(nEN,1)=errorStats(2);
    NErr3(nEN,1)=errorStats(3);
    end

    BER=NErr1;
    Nerros=NErr2;
    bitsTotal=NErr3;
        error('runConvBlock not yet implemented');
end

function [BER,Pretx] = runBlock(CHANNEL,modulation,EN)
    % ---- paste your original Hamming-only loop here ----
    % Pretx must be computed with block length = 11
    error('runBlock not yet implemented');
end

function [BER,Pretx] = runBlockConv(CHANNEL,modulation,EN)
    % ---- paste your original block+conv loop here ----
    % Pretx computed with block length = 11
    error('runBlockConv not yet implemented');
end
