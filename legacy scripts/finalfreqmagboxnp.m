clear; clc;

fs = 200;
maxfreq = 20;
currentDir = pwd;

% Force white export defaults
set(groot, 'defaultFigureColor', 'w');

allFiles = dir(currentDir);
splices = allFiles(endsWith({allFiles.name}, {'.txt'}));
pitch_data = [];
trainingDataChunks = [];
testingDataChunks = [];

fileNames = {splices.name};

for k = 1:length(fileNames)
    dataFile = fullfile(currentDir, fileNames{k}); %#ok<NASGU>
    dateArr = split(fileNames{k}, "-times.txt");
    years = {'2023', '2024'};
    fileName = "";

    for i = 1:length(years)
        testName = sprintf('Glove IMU_%s-%s.csv', years{i}, dateArr{1});
        if exist(testName, 'file')
            fileName = testName;
            break;
        end
    end

    splitStr = split(dateArr{1}, '-');
    datePart = strcat(splitStr{1}, '-', splitStr{2});
    pitcherPart = splitStr{3};

    dirCheck = fullfile(currentDir, sprintf("NONPITCH ANALYSIS %s/Pitcher %s", datePart, pitcherPart));
    allPitchFiles = dir(dirCheck);
    csvFiles = allPitchFiles(endsWith({allPitchFiles.name}, {'.csv'}));

    % Match your original use of the 3rd CSV file
    dataToAppend = table2array(readtable(fullfile(csvFiles(3).folder, csvFiles(3).name)));
    pitch_data = [pitch_data, dataToAppend];
    if k <= 6
        trainingDataChunks = [trainingDataChunks, dataToAppend];
    else    
        testingDataChunks = [testingDataChunks, dataToAppend];
    end
end

% Frequency vector
frequencies = linspace(0, maxfreq, height(pitch_data) + 2);
frequencies = frequencies(2:end-1)';

% Select every 3rd frequency bin by index
freqStep = 3;
selectedIdx = 1:freqStep:length(frequencies);
selectedFreqs = frequencies(selectedIdx);

% Select those frequency rows directly
pitch_data_sel = pitch_data(selectedIdx, :);

% Flatten selected data for boxplot
boxplotData_sel = log(pitch_data_sel(:));

% Use integer positions so ticks align exactly with boxes
numGroups = numel(selectedFreqs);
groupings_sel = repelem(1:numGroups, size(pitch_data_sel, 2))';
groupings_sel = groupings_sel(:);

% Create output folder
outDir = fullfile(currentDir, 'finalimages');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% Create publication-style figure
fig = figure('Units', 'inches', 'Position', [1 1 3.5 2.6], ...
             'Color', 'w', 'InvertHardcopy', 'off');

boxplot(boxplotData_sel, groupings_sel, 'Symbol', '', 'Whisker', 1.5);

xlabel('Frequency (Hz)', 'FontName', 'Times New Roman', 'FontSize', 9, 'Color', 'k');
ylabel('Log(Magnitude)', 'FontName', 'Times New Roman', 'FontSize', 9, 'Color', 'k');
title('Frequency-Domain Power Distribution Across Non-Pitch Events', ...
    'FontName', 'Times New Roman', 'FontSize', 9, ...
    'FontWeight', 'normal', 'Color', 'k');

ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 8;
ax.LineWidth = 0.75;
ax.Box = 'on';
ax.TickDir = 'out';
ax.Color = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
xtickangle(0);
grid off;

% Make visible plot elements black while keeping background white
set(findobj(gca, 'Type', 'Line'), 'Color', 'k', 'LineWidth', 1.2);
set(findobj(gca, 'Type', 'Patch'), 'EdgeColor', 'k');
set(findobj(gca, 'Type', 'Text'), 'Color', 'k');

% Make median slightly thicker
set(findobj(gca, 'Tag', 'Median'), 'LineWidth', 1.5);

% Set exact tick positions and labels
xticks(1:numGroups);
xticklabels(compose('%.1f', selectedFreqs));

% Force same y-axis scale for pitch and non-pitch plots
ylim([-8.5 6.2]);

% Tighten layout a bit
set(fig, 'Color', 'w');
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Export
exportgraphics(fig, fullfile(outDir, 'freq_boxplot_nonpitch.png'), 'Resolution', 600);
