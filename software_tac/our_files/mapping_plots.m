
%QPSK
bits =[0 0 0 1 1 0 1 1];
b = reshape(bits, 2, []).';
k = [0 1 3 2];
gray_map = exp(1i*(pi/2)*(k+0.5));
idx = b(:,1)*2 + b(:,2) + 1;
symbols = gray_map(idx).';

figure
plot(real(symbols), imag(symbols), 'o', ...
     'MarkerSize', 8, 'MarkerFaceColor' , [0 101/255 189/255])
grid on;  axis equal
xlim([-1.5 1.5]);  ylim([-1.5 1.5])
xlabel('Real');  ylabel('Imaginary')
title('QPSK')
hold on

% eixos I/Q
plot([-1.5 1.5], [0 0], 'k', 'LineWidth', 1)   % eixo Q (horizontal)
plot([0 0], [-1.5 1.5], 'k', 'LineWidth', 1)   % eixo I (vertical)

% anota cada símbolo com o par de bits
for n = 1:numel(symbols)
    text(real(symbols(n))+0.12, imag(symbols(n)), ...
         num2str(b(n,:)), 'Color','red', 'FontSize',8, ...
         'HorizontalAlignment','left')
end
hold off

%16-QAM
combinations = dec2bin(0:15) - '0'; % generate combinations
bits = reshape(combinations.', 1, []); % convert to bitstream

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

figure;


plot(real(symbols), imag(symbols), 'o', 'MarkerSize',8, 'MarkerFaceColor',[0 101/255 189/255]);
grid on;
axis equal;
xlabel('Real');
ylabel('Imaginary');
title('16-QAM Constellation');
hold on;
xlim([-4 4])
ylim([-4 4])
xl = xlim;                              % current x-axis limits
yl = ylim;                              % current y-axis limits
plot([xl(1) xl(2)], [0 0], 'k', 'LineWidth', 1)   % Q-axis (horizontal)
plot([0 0], [yl(1) yl(2)], 'k', 'LineWidth', 1)   % I-axis (vertical)
% Annotate each point with its corresponding bit combination
for k = 1:length(symbols)
    bit_label = num2str(combinations(k,:));
    text(real(symbols(k)) + 0.2, imag(symbols(k)), bit_label, 'FontSize', 8, 'Color', 'red');
end