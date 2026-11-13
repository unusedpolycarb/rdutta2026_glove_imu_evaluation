clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(scriptDir, '..', 'data', 'matlab DATA files');

S = load(fullfile(dataDir, 'processed_pitch_data.mat'), ...
    'frequencies', 'total_pitch_freq_data', 'total_non_pitch_freq_data');

freq = S.frequencies(:);
numBins = 10;

binEdges = linspace(0, 20, numBins + 1);
binLabels = arrayfun(@(k) sprintf('%.1f-%.1f', binEdges(k), binEdges(k+1)), ...
    1:numBins, 'UniformOutput', false);

pitchLog = cat(2, S.total_pitch_freq_data{:});
nonpitchLog = cat(2, S.total_non_pitch_freq_data{:});

assert(size(pitchLog,1) == numel(freq) && ...
       size(nonpitchLog,1) == numel(freq));

pitchBinned = zeros(numBins, size(pitchLog,2));
nonpitchBinned = zeros(numBins, size(nonpitchLog,2));

for k = 1:numBins
    if k < numBins
        idx = freq >= binEdges(k) & freq < binEdges(k+1);
    else
        idx = freq >= binEdges(k) & freq <= binEdges(k+1);
    end

    if ~any(idx)
        error('Empty frequency bin %d', k);
    end

    pitchBinned(k,:) = log(mean(exp(pitchLog(idx,:)), 1, 'omitnan') + eps);
    nonpitchBinned(k,:) = log(mean(exp(nonpitchLog(idx,:)), 1, 'omitnan') + eps);
end

% Create figure
fig = figure('Units', 'inches', ...
    'Position', [1 1 7.0 3.2], ...
    'Color', 'w', 'InvertHardcopy', 'off');

ax = gobjects(1,2);

for panel = 1:2

    ax(panel) = subplot(1,2,panel);

    if panel == 1
        vals = pitchBinned;
    else
        vals = nonpitchBinned;
    end

    group = repmat((1:numBins)', 1, size(vals,2));

    boxplot(ax(panel), vals(:), group(:), ...
        'Symbol', '', 'Whisker', 1.5);

    xlabel(ax(panel), 'Frequency (Hz)', ...
        'FontName', 'Times New Roman', 'FontSize', 9);

    ylabel(ax(panel), 'Log(Magnitude)', ...
        'FontName', 'Times New Roman', 'FontSize', 9);

    xticks(ax(panel), 1:numBins);
    xticklabels(ax(panel), binLabels);
    xtickangle(ax(panel), 45);

    ylim(ax(panel), [-5.5 6.2]);

    ax(panel).FontName = 'Times New Roman';
    ax(panel).FontSize = 8;
    ax(panel).LineWidth = 0.75;
    ax(panel).Box = 'on';
    ax(panel).TickDir = 'out';
    ax(panel).Color = 'w';
    ax(panel).XColor = 'k';
    ax(panel).YColor = 'k';

    grid(ax(panel), 'off');

    set(findobj(ax(panel), 'Type', 'Line'), ...
        'Color', 'k', 'LineWidth', 1.2);

    set(findobj(ax(panel), 'Tag', 'Median'), ...
        'LineWidth', 1.5);
end

ax(1).PositionConstraint = 'innerposition';
ax(2).PositionConstraint = 'innerposition';

ax(1).Position = [0.09 0.30 0.38 0.62];
ax(2).Position = [0.58 0.30 0.38 0.62];
theme(fig, 'light');
ax(1).Position = [0.09 0.30 0.38 0.62];
ax(2).Position = [0.58 0.30 0.38 0.62];

exportgraphics(fig, 'figure4.png', ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');
