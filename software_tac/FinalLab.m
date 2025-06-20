% message = 'polar codes are employed in 5g due better performance and simplicity';
% 
% BitStream = huffman_encode(message);
% 
% [BER_arr,SNR_arr] = channel(BitStream,'AWGN','QPSK');
% 
% figure;
% semilogy(SNR_arr,BER_arr  ,'b*:' );      % Rayleigh theory  (blue dotted line + stars)
% 
% xlabel('E_b/N_0 (dB)');
% ylabel('Bit Error Rate (BER)');
% title (sprintf('BER vs. E_b/N_0 with L = %d-branch MRC Diversity', 1));
% 
% 
% axis([-5 20 1e-4 1]);  % keep your original zoom
% grid on;               % optional—but useful on a semilogy plot
% 
% 

message = 'polar codes are employed in 5g due better performance and simplicity';
BitStream = huffman_encode(message);

configs = { ...
    {'AWGN', 'QPSK'}, ...
    {'AWGN', '16QAM'}, ...
    {'RAYL', 'QPSK'}, ...
    {'RAYL', '16QAM'} ...
};
styles = {'b-*', 'b--o', 'g-s', 'g:.'};

figure; hold on; grid on;
h = gobjects(numel(configs),1);
legendEntries = cell(numel(configs),1);

for k = 1:numel(configs)
    ch = configs{k}{1};
    modstr = configs{k}{2};
    [BER, SNR] = channel(BitStream, ch, modstr);
    h(k)=semilogy(SNR, BER, styles{k}, 'LineWidth', 1.5);
    legendEntries{k} = sprintf('%s + %s', ch, modstr);
end

xlabel('E_b/N_0 (dB)');
ylabel('Bit Error Rate (BER)');
set(gca, 'YScale', 'log');  % Or use newer syntax: yscale log

title('BER vs E_b/N_0 for Channel & Modulation Combinations');
legend(h, legendEntries, 'Location', 'southwest');
axis([-5 20 1e-6 1]);
grid on;
