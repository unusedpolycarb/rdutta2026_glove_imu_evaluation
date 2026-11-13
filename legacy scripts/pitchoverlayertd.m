clear all;
clc;

load("processed_pitch_data.mat")
%constants

% data is 300x10 (each row = one pitcher)

pitcher_data = cell(3, length(total_pitch_accel_data));  % Preallocate

for i = 1:length(total_pitch_accel_data)
    data = total_pitch_accel_data{i};
    % Compute row-wise statistics
    row_min  = min(data, [], 2);
    row_max  = max(data, [], 2);
    row_mean = mean(data, 2);
    
    % X axis (pitcher index)
    x = (1:size(data,1))';
    pitcher_data{1, i} = row_min;
    pitcher_data{2, i} = row_mean;
    pitcher_data{3, i} = row_max;
end

pitcher_data = pitcher_data';
minMatrix = cell2mat(pitcher_data(:,1)');
meanMatrix = cell2mat(pitcher_data(:,2)');
maxMatrix = cell2mat(pitcher_data(:,3)');

[minPitches, minIdx] = sort(minMatrix, 2, 'ascend');
[maxPitches, maxIdx] = sort(maxMatrix, 2, 'ascend');

t = linspace(0, 1.5, 300)';

% Pick what you want to slice
% Pick what you want to slice
M = meanMatrix;  % or minMatrix / maxMatrix

% Sort per time point
[Ms, idx] = sort(M, 2, 'ascend');   % Ms: 300xN, idx: 300xN

N = size(Ms,2);

% Build a surface grid (single graphics object)
X = repmat(t, 1, N);               % 300xN
Z = zeros(size(Ms));               % 300xN (flat surface)

figure; hold on
set(gcf,'Renderer','opengl');      % good for this

% One surface that spans between ranks; color by idx
hSurf = surf(X, Ms, Z, idx, ...
    'FaceColor','flat', ...
    'EdgeColor','none');

view(2);                           % look from top (2D)
shading flat                       % important: no interpolation between colors

% Colormap (optionally shuffled)
cmap = hsv(N);                     % separated hues
cmap = cmap(randperm(N),:);        % optional shuffle so neighbors aren't similar
colormap(cmap);
caxis([1 N]);

% Overlay the mean curve
hMean = plot(t, mean(M,2), 'k', 'LineWidth', 3);

% Labels / title
plotTitle = "Temporal Slices of IMU Acceleration";
xlabel("Elapsed Time on Pitch Window (s)");
ylabel("Acceleration Magnitude (g)");
title(plotTitle);
box on

% ---- Legend handles (mean + one colored patch per pitcher)
legendHandles = gobjects(N+1,1);
legendHandles(1) = hMean;

cmapCurrent = colormap;  % after shuffle, this is what's actually used
for j = 1:N
    legendHandles(j+1) = patch(nan, nan, cmapCurrent(j,:), 'EdgeColor','none');
end

labels = ["Mean Pitch Acceleration", "Pitcher " + (1:N)];
legend(legendHandles, labels, 'Location','northeast');
% compute mean min max for each pitcher and overall
% take the overall and plot mean min and max and then 
% each individual pitcher's individual spot on that 