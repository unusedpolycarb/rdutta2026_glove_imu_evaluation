clear; clc;

fs = 200;
currentDir = pwd;

allFiles = dir(currentDir);
splices = allFiles(endsWith({allFiles.name}, {'.txt'}));
trainingDataChunks = [];
testingDataChunks = [];

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

fileNames = {splices.name};
pitcherMeans = [];
pitcherLabels = strings(1, numel(fileNames));

for k = 1:length(fileNames)
    dateArr = split(fileNames{k}, "-times.txt");
    years = {'2023', '2024'};

    for i = 1:length(years)
        fileName = sprintf('Glove IMU_%s-%s.csv', years{i}, dateArr{1});
        if exist(fileName, 'file')
            break;
        else
            fileName = "";
        end
    end

    splitStr = split(dateArr{1}, '-');
    datePart = strcat(splitStr{1}, '-', splitStr{2});
    pitcherPart = splitStr{3};

    dirCheck = fullfile(currentDir, sprintf("PITCH ANALYSIS %s/Pitcher %s", datePart, pitcherPart));
    allPitchFiles = dir(dirCheck);
    csvFiles = allPitchFiles(endsWith({allPitchFiles.name}, {'.csv'}));
    dataMat = table2array(readtable(fullfile(csvFiles(1).folder, csvFiles(1).name)));
    datapoints = dataMat(:, 2:2:end);
    mu_pitcher = mean(datapoints, 2, 'omitnan');

    if isempty(pitcherMeans)
        pitcherMeans = nan(length(mu_pitcher), length(fileNames));
    end
    pitcherMeans(:, k) = mu_pitcher;
    pitcherLabels(k) = "P " + pitcherPart;
    if k <= 6
        trainingDataChunks = [trainingDataChunks, datapoints];
    else    
        testingDataChunks = [testingDataChunks, datapoints];
    end
end

% Time vector
t = (1:size(pitcherMeans,1))' / fs;

% Create figure
fig = figure('Units', 'inches', 'Position', [1 1 6.8 3.6], ...
             'Color', 'w', 'InvertHardcopy', 'off');

hold on;

for k = 1:size(pitcherMeans, 2)
    plot(t, pitcherMeans(:, k), 'LineWidth', 1.8, 'Color', colors(k, :));
    pitcherLabelsActual(k) = "Pitcher 0" + k;
end

xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', 10, 'Color', 'k');
ylabel('Acceleration Magnitude (g)', 'FontName', 'Times New Roman', 'FontSize', 10, 'Color', 'k');
title('Mean Pitch in a 1.5s Window For Each Pitcher', ...
      'FontName', 'Times New Roman', 'FontSize', 10, ...
      'FontWeight', 'normal', 'Color', 'k');

ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 9;
ax.LineWidth = 0.8;
ax.Box = 'on';
ax.TickDir = 'out';
ax.Color = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
grid on;

h = findobj(gca);
lgd = legend(cellstr(pitcherLabelsActual), 'Location', 'eastoutside', 'FontSize', 8);

lgd.Color = 'w';        
lgd.EdgeColor = 'k';   
lgd.TextColor = 'k';    
lgd.Box = 'on';         

outDir = fullfile(currentDir, 'final tables and figures');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

exportgraphics(fig, fullfile(outDir, 'figure1.png'), 'Resolution', 600);
