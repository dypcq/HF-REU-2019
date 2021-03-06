% Monte-Carlo simulation block.
function MIMO_simulation
M = 2;
nTx = 4;
nRx = 2;
% Initialize initial data for plots
ITER=1000;
snr_range=0:5:30;
% channel transmit parameters
fd = 1; % Chosen maximum Doppler shift for simulation
ttlSymbols = 100; % total number of symbols to be transmitted at this time per antennas.
sGauss1 = 0.2;
fGauss1 = -0.5;
Rs=9600;
sGauss2 = 0.1;
fGauss2 = 0.4;
gGauss1 = 1.2;       % Power gain of first component
gGauss2 = 0.25;      % Power gain of second component
[chanComp3, chanComp4] = Watterson_channel(nTx, nRx, fd, sGauss1, sGauss2, fGauss1, fGauss2, Rs);
if ~exist('data','dir')
    mkdir('data')
end
if exist('parfor_wait_licensed','dir')
    addpath('parfor_wait_licensed');
end
if exist('permn_licensed','dir')
    addpath('permn_licensed');
end
WaitMessage = parfor_wait(ITER, 'Waitbar', true);
parfor iter=1:ITER
    disp(['Monte Carlo Iteration ', num2str(iter), ' of ', num2str(ITER)]);
    data = randi([0 M-1], ttlSymbols, nTx); % generated n-dimension random data.
    d_it = zeros(length(snr_range),1);
    d2_it = zeros(length(snr_range),1);
    d3_it = zeros(length(snr_range),1);
    d4_it = zeros(length(snr_range),1);
    for it = 1:length(snr_range)
        disp(['SNR ', num2str(snr_range(it)), ' of ', num2str(max(snr_range))]);
        tx = pskmod(data(:), M, pi/M); % Input Modulation.
        tx = reshape(tx, ttlSymbols, nTx); % Reshape to pass the signal into wattersonMIMO
        [rx,~] = Watterson_transmit(tx, snr_range(it),chanComp3,chanComp4,gGauss1,gGauss2);
        %% Default Setting for LS-Equalizers
        window_length=100;
        pilot_freq=2;
        var=0.1;
        %% LEAST SQUARE - ZERO FORCING
        [d, ~] = zf_fun(tx, rx, M, pilot_freq, window_length);
        d_it(it)=d;
        %% LEAST SQUARE - MLD DETECTOR
        [d2,~] = mld_fun(tx, rx, M, pilot_freq, window_length);
        d2_it(it)=d2;
        %% LEAST SQUARE - MMSE DETECTOR
        [d3,~] = mmse_fun(tx, rx, M, pilot_freq, window_length, var);
        d3_it(it)=d3;
        %% CE - GA
         [d4,~] = ber_ce_ga(tx, rx, M, pilot_freq, snr_range);
        d4_it(it)=d4;
    end
    parsave(sprintf('./data/testingoutput%d.mat',iter),d_it,d2_it,d3_it,d4_it);
    WaitMessage.Send;
    pause(0.002);
end
[d_it_tot, d2_it_tot, d3_it_tot, d4_it_tot] = loadall(ITER, snr_range);
legend = ["ZF", "MLD", "MMSE", "GA"];
bers = [d_it_tot;d2_it_tot;d3_it_tot;d4_it_tot];
graphing(legend, snr_range, bers, ttlSymbols, nTx, M);
WaitMessage.Destroy
end

% save variables calculated during parfor loop.
function parsave(fname, d_it, d2_it, d3_it, d4_it)
save(fname, 'd_it', 'd2_it', 'd3_it', 'd4_it')
end
