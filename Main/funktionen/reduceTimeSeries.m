function reduceTimeSeries(fileIn, fileOut)
%REDUCETIMESERIES Copy of a TimeSeries_RLxx.mat file with 25 channels
%   reduceTimeSeries(fileIn, fileOut) stores the time series of fileIn
%   (written by optimizeIPC_PI_RateLimits with 'SaveTimeSeries', true, about
%   70 MB) with only the channels needed for the plots (wind, pitch, rotor
%   and generator speed, blade root, yaw bearing and tower base moments,
%   nacelle acceleration, power, torque) at the full sample time in fileOut
%   (about 12 MB), so that it can be committed.

S = load(fileIn, 'TimeSeries');
names = string(S.TimeSeries.Optimum.OutList(:));
keep = names == "Time" | startsWith(names, ["Wind1Vel", "BldPitch", "RotSpeed", "GenSpeed", ...
    "GenTq", "GenPwr", "RootMyc", "RootMxc", "TwrBsM", "YawBrM", "NcIMUTA"]);
for f = ["Baseline", "Optimum"]
    if ~isequal(string(S.TimeSeries.(f).OutList(:)), names)
        error('Baseline and optimum of %s have different channels.', fileIn);
    end
    TimeSeries.(f) = struct('OutData', S.TimeSeries.(f).OutData(:, keep), ...
        'OutList', {S.TimeSeries.(f).OutList(keep)});
end
outDir = fileparts(fileOut);
if ~isempty(outDir) && ~isfolder(outDir), mkdir(outDir); end
save(fileOut, 'TimeSeries', '-v7');
end
