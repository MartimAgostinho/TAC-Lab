function bits = demodul8(symbols, mode)

    symbols = symbols(:);  
    switch upper(mode)

    case 'QPSK'

        ang  = angle(symbols) - pi/4;                % centre sectors on axes
        khat = mod( round( ang / (pi/2) ), 4 );      % 0…3

        persistent k2bits
        if isempty(k2bits)
            fwd = [0 1 3 2];
            k2bits = zeros(4,2);
            for idx = 0:3
                bits2 = de2bi(idx,2,'left-msb');
                k2bits(fwd(idx+1)+1,:) = bits2;
            end
        end
        bits = reshape(k2bits(khat+1,:).',[],1);

    case '16QAM'
        I = real(symbols);
        Q = imag(symbols);
      
        b0 = I > 0;          % sign of I  (MSB on I-axis)
        b1 = abs(I) < 2;     % |I| < 2    (LSB on I-axis)
        b2 = Q > 0;          % sign of Q  (MSB on Q-axis)
        b3 = abs(Q) < 2;     % |Q| < 2    (LSB on Q-axis)

        bits = reshape([b0 b1 b2 b3].',[],1);

    otherwise
        error('Unsupported mode "%s"',mode);
    end
end
