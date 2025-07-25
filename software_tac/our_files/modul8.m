function symbols = modul8(bits, mode)
    bits = bits(:).'; % line vect
    switch upper(mode)
        case 'QPSK'
            if mod(length(bits), 2) ~= 0
                error('bitStream length must be multiple of 2 for QPSK');
            end
            b = reshape(bits, 2, []).';
            k = [0 1 3 2];
            gray_map = exp(1i*(pi/2)*(k+0.5));
            %gray_map = [1+1j, -1+1j, -1-1j, 1-1j];
            idx = b(:,1)*2 + b(:,2) + 1;
            symbols = gray_map(idx);
            
            
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
            error('Error: Wrong Modulation');
    end
end
