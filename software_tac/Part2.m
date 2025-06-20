EN=[-5:2:22]'+0*100; 
en = 10 .^(EN/10);

NEN=length(EN);
NErr1=zeros(NEN,1);
NErr2=zeros(NEN,1);
NErr3=zeros(NEN,1);

s = RandStream('mt19937ar', 'Seed', 11);
noiseVar = 1 ./ (1/3 * 4 .* en);

frmLen = 256;

blockSize = 11;
wordSize = 15;
nBlocks = ceil(frmLen / blockSize);
n_excess = nBlocks * blockSize -frmLen ;
intrlvrIndices_block = randperm(nBlocks * wordSize);

intrlvrIndices_blockconv = randperm(3*nBlocks * wordSize);

intrlvrIndices = randperm(frmLen*3);
trellis = poly2trellis(7,[165 171 133]);

constellation = reshape([-3 -1 1 3] + 1j*[3 1 -1 -3].', [], 1);


hconv = comm.ConvolutionalEncoder('TrellisStructure', trellis);
qamMod = comm.GeneralQAMModulator(constellation');
qamdemod = comm.GeneralQAMDemodulator('Constellation',constellation', ...
    'BitOutput', 1,'DecisionMethod','Hard decision');
hconvde = comm.ViterbiDecoder('TrellisStructure', trellis,'InputFormat', 'Hard', 'TerminationMethod','Truncated');
hError = comm.ErrorRate;


% -------------- Conv -------------
for nEN=1:NEN
    hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
    %hChanRAYL  = comm.RayleighChannel('PathDelays',0, 'AveragePathGains',0,'NormalizePathGains',1, 'MaximumDopplerShift',0);
    % Canal Rayleigh plano (flat-fading) gerado manualmente
    h = (randn(192, 1) + 1j * randn(192, 1)) / sqrt(2);
    
    reset(hError);
    reset(hconvde);
    for frmIdx = 1:10000
        data = randi(s, [0 1], frmLen, 1);
        
        encodedData = step(hconv, data);
        interData = intrlv(encodedData, intrlvrIndices);
        encodedDataMatrix = reshape(interData, 4, []).';        % Cada linha: 4 bits
        symbols = bi2de(encodedDataMatrix, 'left-msb');
        %in a rayleigh channel it is necessary to interleave bits before modulation

        modSignal = step(qamMod, symbols);
        
        channelSignalRayl = modSignal .* h;
        channelSignal = step(hChanAWGN, channelSignalRayl);

        %in a rayleigh channel it is necessary to de-interleave demodulated bits before

        %decoding
        eqSignal = channelSignal ./ h;
        receivedSignal = step(qamdemod, eqSignal);
        
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

fprintf('\n\n\n ######## Conv Codes ######### \n\n\n')
for nEN=1:NEN
    
    fprintf('\n\n----- SNR %d ----\n\n', EN(nEN))
    fprintf('Error rate = %f\nNumber of errors = %d\nTotal bits = %d\n', ...
    BER(nEN), Nerros(nEN), bitsTotal(nEN)) 
    
end

figure()
semilogy(EN,BER,'k-*')
xlabel('E_b/N_0(dB)'),ylabel('BER')
axis([-5 20 1e-7 1])

% -------------- Blocks -------------

for nEN=1:NEN
    hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
    %hChanRAYL  = comm.RayleighChannel('PathDelays',0, 'AveragePathGains',0,'NormalizePathGains',1, 'MaximumDopplerShift',0);
    % Canal Rayleigh plano (flat-fading) gerado manualmente
    hBlock = (randn(90, 1) + 1j * randn(90, 1)) / sqrt(2);
    
    reset(hError);
    reset(hconvde);
    for frmIdx = 1:10000
        dataBlock = randi(s, [0 1], frmLen, 1);
        dataPadded = [dataBlock; zeros(n_excess,1)];
        dataMatrix = reshape(dataPadded, blockSize, []).';
        codedMatrix = zeros(nBlocks, wordSize);
        for i = 1:nBlocks
            codedMatrix(i, :) = encode(dataMatrix(i, :)', wordSize, blockSize, 'hamming/binary')';
        end

        % Vetor codificado completo
        encodedDataBlock = reshape(codedMatrix.', [], 1);
        
        interDataBlock = intrlv(encodedDataBlock, intrlvrIndices_block);
        encodedDataMatrixBlock = reshape(interDataBlock, 4, []).';        % Cada linha: 4 bits
        symbolsBlock = bi2de(encodedDataMatrixBlock, 'left-msb');
        %in a rayleigh channel it is necessary to interleave bits before modulation

        modSignalBlock = step(qamMod, symbolsBlock);
        
        channelSignalRaylBlock = modSignalBlock .* hBlock;
        channelSignalBlock = step(hChanAWGN, channelSignalRaylBlock);

        %in a rayleigh channel it is necessary to de-interleave demodulated bits before

        %decoding
        eqSignalBlock = channelSignalBlock ./ hBlock;
        receivedSignalBlock = step(qamdemod, eqSignalBlock);
        
        % Convert received signal to log-likelihood ratios for decoding
        deinterSignalBlock = deintrlv(receivedSignalBlock, intrlvrIndices_block);
        receivedBitsBlock  = decode(deinterSignalBlock,wordSize,blockSize,'hamming/binary');

        errorStatsBlock = step(hError, dataPadded, receivedBitsBlock);


    end
    NErr1Block(nEN,1)=errorStatsBlock(1);
    NErr2Block(nEN,1)=errorStatsBlock(2);
    NErr3Block(nEN,1)=errorStatsBlock(3);
end


BERBlock=NErr1Block;
NerrosBlock=NErr2Block;
bitsTotalBlock=NErr3Block;

P0Block = (1 - BERBlock).^blockSize;
P1Block = blockSize .* BERBlock .* (1 - BERBlock).^(blockSize - 1);

PretransBlock = 1 - (P0Block + P1Block);  % vetor da probabilidade de retransmissão

fprintf('\n\n\n ######## Block Codes ######### \n\n\n')
for nEN=1:NEN
    
    fprintf('\n\n----- SNR %d ----\n\n', EN(nEN))
    fprintf('Error rate = %f\nNumber of errors = %d\nTotal bits = %d\n', ...
    BERBlock(nEN), NerrosBlock(nEN), bitsTotalBlock(nEN)) 
    
end


figure()
semilogy(EN,BERBlock,'k-*', EN,PretransBlock,'b-*')
xlabel('E_b/N_0(dB)'),ylabel('BER')
axis([-5 20 1e-7 1])


% -------------- Blocks and Conv -------------

for nEN=1:NEN
    hChanAWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar(nEN));
    %hChanRAYL  = comm.RayleighChannel('PathDelays',0, 'AveragePathGains',0,'NormalizePathGains',1, 'MaximumDopplerShift',0);
    % Canal Rayleigh plano (flat-fading) gerado manualmente
    hBlockConv = (randn(270, 1) + 1j * randn(270, 1)) / sqrt(2);
    
    reset(hError);
    reset(hconvde);
    for frmIdx = 1:10000
        dataBlockConv = randi(s, [0 1], frmLen, 1);
        dataPaddedConv = [dataBlockConv; zeros(n_excess,1)];
        dataMatrixConv = reshape(dataPaddedConv, blockSize, []).';
        codedMatrixConv = zeros(nBlocks, wordSize);
        for i = 1:nBlocks
            codedMatrixConv(i, :) = encode(dataMatrixConv(i, :)', wordSize, blockSize, 'hamming/binary')';
        end

        % Vetor codificado completo
        encodedDataBlockConv = reshape(codedMatrixConv.', [], 1);
        
        %conv
        encodedDataBlockConvFinal = step(hconv, encodedDataBlockConv);
        
        interDataBlockConv = intrlv(encodedDataBlockConvFinal, intrlvrIndices_blockconv);
        encodedDataMatrixBlockConv = reshape(interDataBlockConv, 4, []).';        % Cada linha: 4 bits
        symbolsBlockConv = bi2de(encodedDataMatrixBlockConv, 'left-msb');
        %in a rayleigh channel it is necessary to interleave bits before modulation

        modSignalBlockConv = step(qamMod, symbolsBlockConv);
        
        channelSignalRaylBlockConv = modSignalBlockConv .* hBlockConv;
        channelSignalBlockConv = step(hChanAWGN, channelSignalRaylBlockConv);

        %in a rayleigh channel it is necessary to de-interleave demodulated bits before

        %decoding
        eqSignalBlockConv = channelSignalBlockConv ./ hBlockConv;
        receivedSignalBlockConv = step(qamdemod, eqSignalBlockConv);
        
        % Convert received signal to log-likelihood ratios for decoding
        deinterSignalBlockConv = deintrlv(receivedSignalBlockConv, intrlvrIndices_blockconv);
        receivedBitsBlockConv  = step(hconvde, deinterSignalBlockConv);
        receivedBitsBlockConvFinal  = decode(receivedBitsBlockConv,wordSize,blockSize,'hamming/binary');

        errorStatsBlockConv = step(hError, dataPaddedConv, receivedBitsBlockConvFinal);


    end
    NErr1BlockConv(nEN,1)=errorStatsBlockConv(1);
    NErr2BlockConv(nEN,1)=errorStatsBlockConv(2);
    NErr3BlockConv(nEN,1)=errorStatsBlockConv(3);
end


BERBlockConv=NErr1BlockConv;
NerrosBlockConv=NErr2BlockConv;
bitsTotalBlockConv=NErr3BlockConv;

P0BlockConv = (1 - BERBlockConv).^blockSize;
P1BlockConv = blockSize .* BERBlockConv .* (1 - BERBlockConv).^(blockSize - 1);

PretransBlockConv = 1 - (P0BlockConv + P1BlockConv);  % vetor da probabilidade de retransmissão

fprintf('\n\n\n ######## Block Codes ######### \n\n\n')
for nEN=1:NEN
    
    fprintf('\n\n----- SNR %d ----\n\n', EN(nEN))
    fprintf('Error rate = %f\nNumber of errors = %d\nTotal bits = %d\n', ...
    BERBlockConv(nEN), NerrosBlockConv(nEN), bitsTotalBlockConv(nEN)) 
    
end


figure()
semilogy(EN,BERBlockConv,'k-*', EN,PretransBlockConv,'b-*')
xlabel('E_b/N_0(dB)'),ylabel('BER')
axis([-5 20 1e-7 1])
%fprintf('Error rate = %f\nNumber of errors = %d\nTotal bits = %d\n', ...
%errorStats(1), errorStats(2), errorStats(3))   