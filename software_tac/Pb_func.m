% ======================================================================
%  BER TEÓRICA PÓS-FEC – 4 COMBINAÇÕES DE CANAL+MODULAÇÃO
%     • Modulação : QPSK | 16-QAM
%     • Canal     : AWGN | Rayleigh plano
%     • FEC       : Hamming (15,11)  &  Convolucional (7,1/3)  (Viterbi hard)
% ----------------------------------------------------------------------
%  Fórmulas  • Hamming  : eq. (1) da sebenta   Pp = Σ_{i=2}^{15} C(n,i)p^i(1-p)^{n-i}
%            • Conv.    : Carlson&Crilly 13.3-11
%                Pb ≤ M(df)/(k) · 2^{df} /(4πRγ_b)^{df/4} · e^{-R df γ_b}
%              Rayleigh: média de e^{-Rdfγ}  ⇒  e→1/(1+Rdfγ_b)
% ======================================================================

clear, clc
EbN0dB = 0:0.5:12;                        % vetor Eb/N0 em dB
EbN0   = 10.^(EbN0dB/10);                 % linear
Qf     = @(x) 0.5*erfc(x./sqrt(2));       % função Q

%% 1 ───────── BER BRUTO (SEM FEC) ─────────────────────────────────────
Pb.QPSK_AWGN  = Qf( sqrt(2*EbN0) );
Pb.QPSK_Ray   = 0.5*(1 - sqrt(EbN0./(1+EbN0)));

Pb.QAM16_AWGN = 0.75 * Qf( sqrt(4/5*EbN0) );
Pb.QAM16_Ray  = 0.75 * (1 - sqrt((4/5*EbN0)./(1+4/5*EbN0)));

%% 2 ───────── Hamming (15,11)  ───────────────────────────────────────
n=15; k_blk=11;
for f = fieldnames(Pb).'
    p  = Pb.(f{1});
    Pp = 0;
    for i=2:n
        Pp = Pp + nchoosek(n,i)*p.^i.*(1-p).^(n-i);
    end
    BER_Hamm.(f{1}) = Pp/k_blk;           % Pb ≈ Pp/k
end

%% 3 ───────── Conv. (7,1/3)  Carlson-Crilly 13.3-11 ──────────────────
R   = 1/3;                                % taxa
trel = poly2trellis(7,[165 171 133]);     
ds   = distspec(trel,30);                 % espectro
df   = ds.dfree;                          % 15
Mdf  = ds.weight(1);                      % já é Σ_i i·A(df,i)
k_conv = 1;

% AWGN fórmula (exp)   • Rayleigh = parte prefactor × 1/(1+Rdfγ)
prefactor = (Mdf*2^df) ./ (k_conv*(4*pi*R*EbN0).^(df/4));

BER_CC.QPSK_AWGN  = prefactor .* exp(-R*df*EbN0);
BER_CC.QAM16_AWGN = BER_CC.QPSK_AWGN;     % depende só de Eb/N0

BER_CC.QPSK_Ray   = prefactor ./ (1 + R*df*EbN0);
BER_CC.QAM16_Ray  = BER_CC.QPSK_Ray;      % idem

%% 4 ───────── TABELA DE RESULTADOS ───────────────────────────────────
comb = {'QPSK_AWGN','QPSK_Ray','QAM16_AWGN','QAM16_Ray'};
fprintf('\n  Eb/N0 | --- QPSK-AWGN --- | --- QPSK-Ray --- | -- 16QAM-AWGN -- | -- 16QAM-Ray --\n');
fprintf(  '  (dB)  | Hamm      CC     | Hamm      CC     | Hamm      CC     | Hamm      CC\n');
for s = 1:numel(EbN0dB)
    fprintf('%6.1f |',EbN0dB(s));
    for c = 1:numel(comb)
        fprintf(' %7.2e %7.2e |', BER_Hamm.(comb{c})(s), BER_CC.(comb{c})(s));
    end
    fprintf('\n');
end

%% 5 ───────── GRÁFICO OPCIONAL ───────────────────────────────────────
figure, hold on, grid on, set(gca,'YScale','log')
cores = lines(4);
for c = 1:4
    plot(EbN0dB, BER_Hamm.(comb{c}),'-','LineWidth',1.5,'Color',cores(c,:));
    plot(EbN0dB, BER_CC.(comb{c}),'--','LineWidth',1.5,'Color',cores(c,:));
end
xlabel('E_b/N_0  (dB)'), ylabel('BER pós-FEC')
title('Teoria: Hamming (—)  vs  Convolucional (--)')
legend({'QPSK-AWGN Hamm','QPSK-AWGN CC', ...
        'QPSK-Ray Hamm','QPSK-Ray CC', ...
        '16QAM-AWGN Hamm','16QAM-AWGN CC', ...
        '16QAM-Ray Hamm','16QAM-Ray CC'}, ...
        'Interpreter','none','Location','southwest')
