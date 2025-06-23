function [BER_arr,SNR_arr] = channel(BitStream,CHANNEL,modulation,ErrorDetection)


    if nargin == 0          % self-test section — runs only when no inputs
        nBits      = 4096;
        BitStream  = randi([0 1], nBits, 1);
        CHANNEL    = 'AWGN';
        modulation = 'QPSK';
        [BER_arr, SNR_arr] = channel(BitStream, CHANNEL, modulation);
        return
    end

    %BitStream = BitStream';
    Stream_len = length(BitStream);
    n_it = ceil(1e8 / Stream_len); %Numero de mensagens enviadas

    EN=[-5:2:22]'+0*100; en = 10 .^(EN/10) ;
    NEN=length(EN);
    NErr=zeros(NEN,1);
    NSR= 1./(4*en); 

  
    L=1; % L-th order diversity
    Ts=4e-6; % Block duration
    Eb = 1;



    if strcmp(modulation,'QPSK') ~= 0
        sigma =sqrt(2 ./en); 
        N = Stream_len / 2 

    elseif strcmp(modulation,'16QAM') ~= 0
<<<<<<< Updated upstream
        Es = 4;
        sigma=sqrt(Es ./(en.*5))*3; 
=======
        Es = 10;   
        sigma=sqrt(Es ./(en.*5))*3/4; 
>>>>>>> Stashed changes
        N = Stream_len / 4
    else
        fprintf('ERRO: Wrong Modulation Value')
        return
    end
    Symb_Stream = modul8(BitStream, modulation).';


    NSlot = n_it;
    message_all = zeros(NEN,length(BitStream));
    for nn=1:NSlot


        if (CHANNEL=='RAYL')
            Hk=(randn(N,L)+j*randn(N,L))/sqrt(2);
        elseif (CHANNEL=='AWGN')
            Hk=ones(N,L).*exp(j*2*pi*rand(N,L));
        end;
        H2k=abs(Hk).^2;
        if (L==1) sH2k=H2k; else sH2k=sum(H2k')'; end;
        An_Tx = Symb_Stream;
        Ak_Tx=fftshift(fft(fftshift(An_Tx)));
        %an_Tx=fftshift(ifft(fftshift(Ak_Tx)));

        for nEN=1:NEN
            Yk=zeros(N,L);
            for l=1:L
                
                Yk(:,l)=Ak_Tx.*Hk(:,l)+(randn(N,1)+j*randn(N,1))*sigma(nEN) * sqrt(N);
            end;
            YIk=0;
            for l=1:L

                YIk = YIk +Yk(:,l).*(conj(Hk(:,l))./(sH2k + NSR(nEN)));
            end;
            Yin = fftshift(ifft(fftshift(YIk)));
            Ak_Rx=demodul8(Yin,modulation).';
            
            NErr(nEN,1)=NErr(nEN,1)+sum(BitStream ~=Ak_Rx);
        end;

        if (rem(nn,100)==0) nn, end;
    end;
    bitsPerSym=2+2*strcmpi(modulation,'16QAM');

    BER_arr =NErr./( NSlot*N*bitsPerSym);
    SNR_arr = EN;
end

% 
% figure;
% semilogy( EN, Pb     ,'g-*', ...   % simulated BER (green stars + solid line)
%           EN, PbAWGN ,'b:' , ...   % AWGN theory      (blue dotted line)
%           EN, Pb_tr  ,'b*:' )      % Rayleigh theory  (blue dotted line + stars)
% 
% xlabel('E_b/N_0 (dB)');
% ylabel('Bit Error Rate (BER)');
% title (sprintf('BER vs. E_b/N_0 with L = %d-branch MRC Diversity', L));
% 
% legend({'Simulation', 'AWGN theory', 'Rayleigh theory'}, ...
%        'Location', 'southwest');   % put the legend in the lower-left corner
% 
% axis([-5 20 1e-4 1]);  % keep your original zoom
% grid on;               % optional—but useful on a semilogy plot
