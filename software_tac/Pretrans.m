% =========================================================
%  Probabilidade de retransmissão  –  Hamming (15,11)
% =========================================================
clear, clc

EbN0dB = -5:0.5:13;
EbN0   = 10.^(EbN0dB/10);

Qf  = @(x) 0.5*erfc(x./sqrt(2));     % função Q (define já aqui)

% ----- BER bruto sem FEC ----------------------------------
berRaw.QPSK_AWGN  = Qf( sqrt(2*EbN0) );
berRaw.QPSK_Ray   = 0.5 * (1 - sqrt(EbN0 ./ (1+EbN0)));

berRaw.QAM16_AWGN = 0.75 * Qf( sqrt(4/5*EbN0) );
berRaw.QAM16_Ray  = 0.75 * (1 - sqrt((4/5)*EbN0 ./ (1+4/5*EbN0)));

% ----- P_retx  (falha quando ≥2 erros num bloco de 15) ----
Pretx  = struct();
fields = fieldnames(berRaw);

for k = 1:numel(fields)
    p           = berRaw.(fields{k});
    Pretx.(fields{k}) = 1 - (1-p).^15 - 15*p.*(1-p).^14;
end

% ----- gráfico -------------------------------------------
figure, hold on, grid on, set(gca,'YScale','log')
plot(EbN0dB, Pretx.QPSK_AWGN , 'b-' ,'LineWidth',1.5)
plot(EbN0dB, Pretx.QPSK_Ray  , 'b--','LineWidth',1.5)
plot(EbN0dB, Pretx.QAM16_AWGN, 'r-' ,'LineWidth',1.5)
plot(EbN0dB, Pretx.QAM16_Ray , 'r--','LineWidth',1.5)
xlabel('E_b/N_0  (dB)')
ylabel('P_{ret} ')
title('P_{ret}  (Hamming 15,11)')
legend({'QPSK–AWGN','QPSK–Rayleigh','16QAM–AWGN','16QAM–Rayleigh'}, ...
       'Location','southwest')
axis([-5 13 1e-5 1])
