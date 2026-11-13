clear; clc;

fs = 200;
maxfreq = 20;
currentDir = pwd;

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

    dirCheck = fullfile(currentDir, sprintf("PITCH ANALYSIS %s/Pitcher %s", datePart, pitcherPart));
    allPitchFiles = dir(dirCheck);
    csvFiles = allPitchFiles(endsWith({allPitchFiles.name}, {'.csv'}));

    dataToAppend = table2array(readtable(fullfile(csvFiles(2).folder, csvFiles(2).name)));
    pitch_data = [pitch_data, dataToAppend];
    if k <= 6
        trainingDataChunks = [trainingDataChunks, dataToAppend];
    else    
        testingDataChunks = [testingDataChunks, dataToAppend];
    end
end

boxplotData = log(pitch_data(:) + eps);

frequencies = linspace(0, maxfreq, height(pitch_data) + 2);
frequencies = frequencies(2:end-1)';

frequencies_repeated = repmat(frequencies(:), 1, width(pitch_data));
groupings = frequencies_repeated(:);

freqStep = 3;
selectedFreqs = frequencies(1:freqStep:end);

tol = 1e-10;
keepIdx = false(size(groupings));
for i = 1:length(selectedFreqs)
    keepIdx = keepIdx | abs(groupings - selectedFreqs(i)) < tol;
end

boxplotData_sel = boxplotData(keepIdx);
groupings_sel = groupings(keepIdx);

fsize = 9;

fig = figure('Units', 'inches', 'Position', [1 1 3.5 2.6], ...
             'Color', 'w', 'InvertHardcopy', 'off');

boxplot(boxplotData_sel, groupings_sel, 'Symbol', '', 'Whisker', 1.5);

xlabel('Frequency (Hz)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');
ylabel('Log(Magnitude)', 'FontName', 'Times New Roman', 'FontSize', fsize, 'Color', 'k');
title('Frequency-Domain Power Distribution Across Pitch Events', ...
    'FontName', 'Times New Roman', 'FontSize', fsize, ...
    'FontWeight', 'normal', 'Color', 'k');

ax = gca;
ax.Color = 'w';
ax.FontName = 'Times New Roman';
ax.FontSize = 8;
ax.LineWidth = 0.75;
ax.Box = 'on';
ax.TickDir = 'out';
ax.XColor = 'k';
ax.YColor = 'k';
xtickangle(0);
grid off;
set(findobj(gca, 'Type', 'Line'), 'Color', 'k', 'LineWidth', 1.2);
set(findobj(gca, 'Type', 'Patch'), 'EdgeColor', 'k');
set(findobj(gca, 'Type', 'Text'), 'Color', 'k');
set(findobj(gca, 'Tag', 'Median'), 'LineWidth', 1.5);
drawnow;
xticks(ax.XTick);
xticklabels(compose('%.1f', selectedFreqs(1:numel(ax.XTick))));
ylim([-8.5 6.2]);
set(fig, 'Color', 'w');
set(gca, 'LooseInset', get(gca, 'TightInset'));

outDir = fullfile(currentDir, 'finalimages');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

exportgraphics(fig, fullfile(outDir, 'freq_boxplot_pitch.png'), 'Resolution', 600);
