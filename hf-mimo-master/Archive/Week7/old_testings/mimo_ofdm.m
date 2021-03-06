bpskMod = comm.QPSKModulator;
bpskDemod = comm.QPSKDemodulator;
ofdmMod = comm.OFDMModulator('FFTLength',128,'PilotInputPort',true,...
    'PilotCarrierIndices',cat(3,[12; 40; 54; 76; 90; 118],...
    [13; 39; 55; 75; 91; 117]),'InsertDCNull',true,...
    'NumTransmitAntennas',2);
ofdmDemod = comm.OFDMDemodulator(ofdmMod);
ofdmDemod.NumReceiveAntennas = 2;
ofdmModDim = info(ofdmMod);

numData = ofdmModDim.DataInputSize(1);   % Number of data subcarriers
numSym = ofdmModDim.DataInputSize(2);    % Number of OFDM symbols
numTxAnt = ofdmModDim.DataInputSize(3);  % Number of transmit antennas
nframes = 100;
data = randi([0 1],nframes*numData,numSym,numTxAnt);
modData = bpskMod(data(:));
modData = reshape(modData,nframes*numData,numSym,numTxAnt);
errorRate = comm.ErrorRate;
for k = 1:nframes
    
    % Find row indices for kth OFDM frame
    indData = (k-1)*ofdmModDim.DataInputSize(1)+1:k*numData;
    
    % Generate random OFDM pilot symbols
    pilotData = complex(rand(ofdmModDim.PilotInputSize), ...
        rand(ofdmModDim.PilotInputSize));
    
    % Modulate QPSK symbols using OFDM
    dataOFDM = ofdmMod(modData(indData,:,:),pilotData);
    
    % Create flat, i.i.d., Rayleigh fading channel
    chGain = complex(randn(2,2),randn(2,2))/sqrt(2); % Random 2x2 channel
    
    % Pass OFDM signal through Rayleigh and AWGN channels
    receivedSignal = awgn(dataOFDM*chGain,30);
    
    eqlms = comm.LinearEqualizer(...
        'Algorithm','LMS','NumTaps',4,'StepSize',0.001,...
        'ReferenceTap', 1);
    % Apply least squares solution to remove effects of fading channel
    rxSigMF = chGain.' \ receivedSignal.';
    rxSigMF = rxSigMF.';
    %rxSigMF = eqlms(receivedSignal, rxSigMF);
    %rxSigMF = reshape(rxSigMF, 144,2);  
    
    % Demodulate OFDM data
    receivedOFDMData = ofdmDemod(rxSigMF);
    
    % Demodulate QPSK data
    receivedData = bpskDemod(receivedOFDMData(:));
    
    % Compute error statistics
    dataTmp = data(indData,:,:);
    errors = errorRate(dataTmp(:),receivedData);
end
fprintf('\nSymbol error rate = %d from %d errors in %d symbols\n',errors)