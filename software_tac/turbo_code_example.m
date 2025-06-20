    %example from matworks for turbo code of UMTS with BPSK modulation and
    %AWGN channel
     noiseVar= 4;frmLen = 256;
    s = RandStream('mt19937ar', 'Seed', 11);
    intrlvrIndices = randperm(s, frmLen);
  
    hTEnc  = comm.TurboEncoder('TrellisStructure', poly2trellis(4, ...
             [13 15 17], 13), 'InterleaverIndices', intrlvrIndices);
    hMod   = comm.BPSKModulator;
    hChan  = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar);
    hTDec  = comm.TurboDecoder('TrellisStructure', poly2trellis(4, ...
             [13 15 17], 13), 'InterleaverIndices', intrlvrIndices, ...
             'NumIterations', 4);
    hError = comm.ErrorRate;
  
    for frmIdx = 1:8
        data = randi(s, [0 1], frmLen, 1);
        encodedData = step(hTEnc, data);
        %in a rayleigh channel it is necessary to interleave bits before modulation
        
        modSignal = step(hMod, encodedData);
        
        receivedSignal = step(hChan, modSignal);
        %in a rayleigh channel it is necessary to de-interleave demodulated bits before
        %decoding
  
        % Convert received signal to log-likelihood ratios for decoding
        receivedBits  = step(hTDec, (-2/(noiseVar/2))*real(receivedSignal));
      
        errorStats = step(hError, data, receivedBits);
    end
    fprintf('Error rate = %f\nNumber of errors = %d\nTotal bits = %d\n', ...
    errorStats(1), errorStats(2), errorStats(3)) 