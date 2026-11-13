clear; clc;

maxfreq = 20;
numBins = 10;   % adjust as needed
fsize = 9;

currentDir = pwd;

% Load CSV files
pitch_data    = readmatrix(fullfile(currentDir, 'freqpitchfinal.csv'));
nonpitch_data = readmatrix(fullfile(currentDir, 'freqnppitchfinal.csv'));

% Frequency vector based on number of rows
frequencies = linspace(0, maxfreq, size(pitch_data,1) + 2);
frequencies = frequencies(2:end-1)';

% Bin edges and centers
binEdges = linspace(0, maxfreq, numBins + 1);
binLabels = strings(numBins,1);
for b = 1:numBins
    binLabels(b) = sprintf('%.1f–%.1f', binEdges(b), binEdges(b+1));
end
binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;

% Initialize binned matrices
pitch_binned = nan(numBins, size(pitch_data, 2));
nonpitch_binned = nan(numBins, size(nonpitch_data, 2));

% Compute mean within each frequency bin
for b = 1:numBins
    if b < numBins
        idx = frequencies >= binEdges(b) & frequencies < binEdges(b+1);
    else
        % include right edge for last bin
        idx = frequencies >= binEdges(b) & frequencies <= binEdges(b+1);
    end
    
    pitch_binned(b, :) = mean(pitch_data(idx, :), 1, 'omitnan');
    nonpitch_binned(b, :) = mean(nonpitch_data(idx, :), 1, 'omitnan');
end

% Log transform after binning
pitch_log = log(pitch_binned(:) + eps);
nonpitch_log = log(nonpitch_binned(:) + eps);

% Group labels for boxplot
groupings_pitch = repmat(binCenters(:), 1, size(pitch_binned, 2));
groupings_pitch = groupings_pitch(:);

groupings_nonpitch = repmat(binCenters(:), 1, size(nonpitch_binned, 2));
groupings_nonpitch = groupings_nonpitch(:);

% Figure
fig = figure('Units', 'inches', 'Position', [1 1 7.0 2.8], ...
             'Color', 'w', 'InvertHardcopy', 'off');

% ---------------- Left subplot: Pitch ----------------
subplot(1,2,1);
boxplot(pitch_log, groupings_pitch, 'Symbol', '', 'Whisker', 1.5);

xlabel('Frequency (Hz)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');
ylabel('Log(Magnitude)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');

ax1 = gca;
ax1.Color = 'w';
ax1.FontName = 'Times New Roman';
ax1.FontSize = 8;
ax1.LineWidth = 0.75;
ax1.Box = 'on';
ax1.TickDir = 'out';
grid off;

set(findobj(gca, 'Type', 'Line'), 'Color', 'k', 'LineWidth', 1.2);
set(findobj(gca, 'Type', 'Patch'), 'EdgeColor', 'k');
set(findobj(gca, 'Type', 'Text'), 'Color', 'k');
set(findobj(gca, 'Tag', 'Median'), 'LineWidth', 1.5);

drawnow;
xticks(ax1.XTick);
xticklabels(binLabels(1:numel(ax1.XTick)));
xtickangle(45);  
ax1.XColor = 'k';
ax1.YColor = 'k';
ylim([-5.5 6.2]);

% ---------------- Right subplot: Non-pitch ----------------
subplot(1,2,2);
boxplot(nonpitch_log, groupings_nonpitch, 'Symbol', '', 'Whisker', 1.5);

xlabel('Frequency (Hz)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');
ylabel('Log(Magnitude)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');

ax2 = gca;
ax2.Color = 'w';
ax2.FontName = 'Times New Roman';
ax2.FontSize = 8;
ax2.LineWidth = 0.75;
ax2.Box = 'on';
ax2.TickDir = 'out';
grid off;

set(findobj(gca, 'Type', 'Line'), 'Color', 'k', 'LineWidth', 1.2);
set(findobj(gca, 'Type', 'Patch'), 'EdgeColor', 'k');
set(findobj(gca, 'Type', 'Text'), 'Color', 'k');
set(findobj(gca, 'Tag', 'Median'), 'LineWidth', 1.5);

drawnow;
xticks(ax2.XTick);
xticklabels(binLabels(1:numel(ax2.XTick)));
xtickangle(45);  
ax2.XColor = 'k';
ax2.YColor = 'k';
ylim([-5.5 6.2]);

% Output
outDir = fullfile(currentDir, 'finalimages');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

ax1.ActivePositionProperty = 'position';
ax2.ActivePositionProperty = 'position';

drawnow;

exportgraphics(fig, fullfile(outDir, 'freq_boxplot_subplot.png'), 'Resolution', 600);