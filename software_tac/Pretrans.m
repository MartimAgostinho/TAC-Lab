clear, clc

EbN0dB = -5:0.5:22;
EbN0   = 10.^(EbN0dB/10);

<<<<<<< Updated upstream

% ----- BER bruto sem FEC ----------------------------------
berRaw.QPSK_AWGN  = q_x(sqrt(2*EbN0));
berRaw.QPSK_Ray   = 0.5 * (1 - sqrt(EbN0 ./ (1+EbN0)));

berRaw.QAM16_AWGN = 0.75 * Qf( sqrt((4/5)*EbN0) );
=======


% ----- BER bruto sem FEC ----------------------------------
berRaw.QPSK_AWGN  = q_x( sqrt(2*EbN0) );
berRaw.QPSK_Ray   = 0.5 * (1 - sqrt(EbN0 ./ (1+EbN0)));
berRaw.QAM16_AWGN = 0.75 * q_x( sqrt(4/5*EbN0) );
>>>>>>> Stashed changes
berRaw.QAM16_Ray  = 0.75 * (1 - sqrt((4/5)*EbN0 ./ (1+4/5*EbN0)));

Pretx  = struct();
fields = fieldnames(berRaw);

for k = 1:numel(fields)
    p = berRaw.(fields{k});
    Pretx.(fields{k}) = 1 - (1-p).^15 - 15*p.*(1-p).^14;
end


styles = {'b-*', 'b--o', 'g-s', 'g:.'};
legendas = {'QPSK–AWGN','QPSK–Rayleigh','16QAM–AWGN','16QAM–Rayleigh'};
Pretx_arr = {Pretx.QPSK_AWGN, Pretx.QPSK_Ray, Pretx.QAM16_AWGN, Pretx.QAM16_Ray};

figure, hold on, grid on, set(gca,'YScale','log')
for k = 1:4
    plot(EbN0dB, Pretx_arr{k}, styles{k}, 'LineWidth', 1.5, 'MarkerSize',6)
end
xlabel('E_b/N_0  (dB)')
ylabel('P_{ret}')
title('P_{ret}  (Hamming 15,11)')
legend(legendas, 'Location','southwest')
axis([-5 13 1e-5 1])
