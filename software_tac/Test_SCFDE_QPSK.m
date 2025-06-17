% Simulates OFDM
EN=[-5:2:22]'+0*100; 
en = 10 .^(EN/10);
%NoQAM=10.^((EN+10*log10(4))/10);
N=512;
NSlot=1000;
CHANNEL='RAYL';
L=1; % L-th order diversity
Ts=4e-6; % Block duration
Tg=0.2*Ts; % Cyclic prefix durration
f=[-N/2:N/2-1]'/Ts; % frequencies

NRay=1;
Eb=1;
Eb_qpsk=N;          %Energia de bit QPSK
Es_qam=10;         %Energia de bit 16-QAM

sigma_qpsk=sqrt(Eb_qpsk/2 ./en);
sigma_qam=sqrt(Es_qam/4/2 ./en); 
NoQAM=2*sigma_qam.^2;
NSR=1/2 ./(en); 
NEN=length(EN);
NErr=zeros(NEN,1);
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
                end;
            end;
       elseif (CHANNEL=='RAYL')
        Hk=(randn(N,L)+j*randn(N,L))/sqrt(2);
    elseif (CHANNEL=='AWGN')
        Hk=ones(N,L).*exp(j*2*pi*rand(N,L));       
    end;        
    H2k=abs(Hk).^2;
    if (L==1) sH2k=H2k; else sH2k=sum(H2k')'; end;
    
       % Generate some random bits
        bit1  = round(rand(N,1));
        bit2  = round(rand(N,1));
       
        % Generates poar representation of the bits
        B1 = 2*bit1-1;
        B2 = 2*bit2-1;
        
           
        An_Tx = B1+j*B2;%SINAL QPSK
       
        
       
        Ak_Tx=fftshift(fft(fftshift(An_Tx)));
    

    for nEN=1:NEN
        Yk=zeros(N,L);
        for l=1:L
            Yk(:,l)=Ak_Tx.*Hk(:,l)+(randn(N,1)+j*randn(N,1))*sigma_qpsk(nEN); % Ak_NL
        end;
        YIk=0;
        for l=1:L
            YIk = YIk +Yk(:,l).*(conj(Hk(:,l))./(sH2k + NSR(nEN)));
        end;
        %YIk=YIk./(sH2k + NSR(nEN));
        Yin = fftshift(ifft(fftshift(YIk))) ;
        b1_Rx=real(Yin)>0;
        b2_Rx =imag(Yin)>0;
        %Ak_Rx=sign(real(YIk))+j*sign(imag(YIk));
        aux = sum(abs(bit1 - b1_Rx) + abs(bit2 - b2_Rx));
        NErr(nEN,1)=NErr(nEN,1)+aux;
    end;

    if (rem(nn,100)==0) nn, end;
end;

% BER in Rayleigh channel and L-branch diversity [Proakis]
aux=sqrt(en./(1+en));Pb_tr=0;
for l=0:L-1
    Pb_tr=Pb_tr+combin(L-1+l,l)*((1+aux)/2).^l;
end;
Pb_tr=Pb_tr.*((1-aux)/2).^L;

% BER in AWGN channel
%PbAWGN=q_x(sqrt(2*L*en));
PbAWGN=q_x(sqrt(2*L*en));

Pb=NErr/NSlot/N/2;

%figure;
semilogy(EN,Pb,'k-*',EN,PbAWGN,'b-',EN,Pb_tr,'b*:')
xlabel('E_b/N_0(dB)'),ylabel('BER')
axis([0 20 1e-4 1])
%pause,clf;
