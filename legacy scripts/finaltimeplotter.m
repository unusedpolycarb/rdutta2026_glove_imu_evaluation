clear; clc;

fs = 200;
currentDir = pwd;

allFiles = dir(currentDir);
splices = allFiles(endsWith({allFiles.name}, {'.txt'}));
fileNames = {splices.name};

colors = [
    0.0000    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840
    0.25      0.25      0.25
    0.6       0.6       0.6
];

numPitchers = numel(fileNames);
pitchColsPerPitcher = zeros(1, numPitchers);
nonpitchColsPerPitcher = zeros(1, numPitchers);
pitcherLabelsActual = strings(1, numPitchers);

% -------------------------------------------------
% Recover how many columns in final CSV belong to each pitcher
% using the same logic as your original scripts
% -------------------------------------------------
for k = 1:numPitchers
    dateArr = split(fileNames{k}, "-times.txt");
    splitStr = split(dateArr{1}, '-');

    datePart = strcat(splitStr{1}, '-', splitStr{2});
    pitcherPart = splitStr{3};

    pitcherLabelsActual(k) = "Pitcher 0" + k;

    % Pitch file logic
    pitchDir = fullfile(currentDir, sprintf("PITCH ANALYSIS %s/Pitcher %s", datePart, pitcherPart));
    pitchFilesAll = dir(pitchDir);
    pitchCsvFiles = pitchFilesAll(endsWith({pitchFilesAll.name}, {'.csv'}));

    pitchMat = table2array(readtable(fullfile(pitchCsvFiles(1).folder, pitchCsvFiles(1).name)));
    pitchDatapoints = pitchMat(:, 2:2:end);
    pitchColsPerPitcher(k) = size(pitchDatapoints, 2);

    % Non-pitch file logic
    nonpitchDir = fullfile(currentDir, sprintf("NONPITCH ANALYSIS %s/Pitcher %s", datePart, pitcherPart));
    nonpitchFilesAll = dir(nonpitchDir);
    nonpitchCsvFiles = nonpitchFilesAll(endsWith({nonpitchFilesAll.name}, {'.csv'}));

    nonpitchMat = table2array(readtable(fullfile(nonpitchCsvFiles(2).folder, nonpitchCsvFiles(2).name)));
    nonpitchDatapoints = nonpitchMat(:, 2:2:end);
    nonpitchColsPerPitcher(k) = size(nonpitchDatapoints, 2);
end

% -------------------------------------------------
% Load final datasets
% -------------------------------------------------
timePitchFinal = readmatrix(fullfile(currentDir, 'timepfinal.csv'));
timeNonPitchFinal = readmatrix(fullfile(currentDir, 'timenpfinal.csv'));

% If needed, uncomment these:
% timePitchFinal = timePitchFinal(:, 2:end);
% timeNonPitchFinal = timeNonPitchFinal(:, 2:end);

if sum(pitchColsPerPitcher) ~= size(timePitchFinal, 2)
    error('Pitch column counts do not match timepfinal.csv');
end

if sum(nonpitchColsPerPitcher) ~= size(timeNonPitchFinal, 2)
    error('Non-pitch column counts do not match timenpfinal.csv');
end

% -------------------------------------------------
% Compute mean trace for each pitcher
% -------------------------------------------------
pitcherMeansPitch = nan(size(timePitchFinal, 1), numPitchers);
pitcherMeansNonPitch = nan(size(timeNonPitchFinal, 1), numPitchers);

startCol = 1;
for k = 1:numPitchers
    endCol = startCol + pitchColsPerPitcher(k) - 1;
    pitcherMeansPitch(:, k) = mean(timePitchFinal(:, startCol:endCol), 2, 'omitnan');
    startCol = endCol + 1;
end

startCol = 1;
for k = 1:numPitchers
    endCol = startCol + nonpitchColsPerPitcher(k) - 1;
    pitcherMeansNonPitch(:, k) = mean(timeNonPitchFinal(:, startCol:endCol), 2, 'omitnan');
    startCol = endCol + 1;
end

% Time vector
t = (1:size(timePitchFinal, 1))' / fs;

% Common y-limits
allY = [pitcherMeansPitch(:); pitcherMeansNonPitch(:)];
ymin = min(allY, [], 'omitnan');
ymax = max(allY, [], 'omitnan');

% -------------------------------------------------
% Figure
% -------------------------------------------------
fig = figure('Units', 'inches', 'Position', [1 1 10.5 3.5], ...
             'Color', 'w', 'InvertHardcopy', 'off');

fsize = 9;

% ---------------- Left subplot: Pitch ----------------
ax1 = subplot(1,2,1);
hold(ax1, 'on');

for k = 1:numPitchers
    plot(ax1, t, pitcherMeansPitch(:, k), 'LineWidth', 1.5, 'Color', colors(k, :));
end

xlabel(ax1, 'Time (s)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');
ylabel(ax1, 'Acceleration Magnitude (g)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');

ax1.Color = 'w';
ax1.FontName = 'Times New Roman';
ax1.FontSize = 8;
ax1.LineWidth = 0.75;
ax1.Box = 'on';
ax1.TickDir = 'out';
ax1.XColor = 'k';
ax1.YColor = 'k';
grid(ax1, 'on');

set(get(ax1, 'Title'), 'Color', 'k');
set(get(ax1, 'XLabel'), 'Color', 'k');
set(get(ax1, 'YLabel'), 'Color', 'k');
set(findobj(ax1, 'Type', 'Text'), 'Color', 'k');


% ---------------- Right subplot: Non-pitch ----------------
ax2 = subplot(1,2,2);
hold(ax2, 'on');

for k = 1:numPitchers
    plot(ax2, t, pitcherMeansNonPitch(:, k), 'LineWidth', 1.5, 'Color', colors(k, :));
end

xlabel(ax2, 'Time (s)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');
ylabel(ax2, 'Acceleration Magnitude (g)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');

ax2.Color = 'w';
ax2.FontName = 'Times New Roman';
ax2.FontSize = 8;
ax2.LineWidth = 0.75;
ax2.Box = 'on';
ax2.TickDir = 'out';
ax2.XColor = 'k';
ax2.YColor = 'k';
grid(ax2, 'on');

set(get(ax2, 'Title'), 'Color', 'k');
set(get(ax2, 'XLabel'), 'Color', 'k');
set(get(ax2, 'YLabel'), 'Color', 'k');
set(findobj(ax2, 'Type', 'Text'), 'Color', 'k');


% ---------------- Legend ----------------
% Make room for a bottom legend
ax1.Position = [0.08 0.28 0.38 0.62];
ax2.Position = [0.54 0.28 0.38 0.62];

% Bottom legend across figure
lgd = legend(ax1, cellstr(pitcherLabelsActual), ...
    'Orientation', 'horizontal', ...
    'FontSize', 8, ...
    'NumColumns', numPitchers);

lgd.Units = 'normalized';
lgd.Position = [0.08 0.03 0.84 0.08];   % [left bottom width height]
lgd.Color = 'w';
lgd.EdgeColor = 'k';
lgd.TextColor = 'k';
lgd.Box = 'on';
drawnow;

% ---------------- Save ----------------
outDir = fullfile(currentDir, 'finalimages');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

exportgraphics(fig, fullfile(outDir, 'mean_pitch_nonpitch_each_pitcher_subplot.png'), 'Resolution', 600);