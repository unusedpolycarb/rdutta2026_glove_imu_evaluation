clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
dataDir = "../data/matlab DATA files"; 
S = load(fullfile(dataDir, 'processed_pitch_data.mat'), ...
    'total_pitch_accel_data', 'total_non_pitch_accel_data');

fs = 200;
numPitchers = numel(S.total_pitch_accel_data);
assert(numPitchers == 9 && numel(S.total_non_pitch_accel_data) == 9, ...
    'Expected nine pitchers in each set.');

colors = [
    0.0000 0.4470 0.7410;
    0.8500 0.3250 0.0980;
    0.9290 0.6940 0.1250;
    0.4940 0.1840 0.5560;
    0.4660 0.6740 0.1880;
    0.3010 0.7450 0.9330;
    0.6350 0.0780 0.1840;
    0.2500 0.2500 0.2500;
    0.6000 0.6000 0.6000];

pitcherMeans = zeros(300, numPitchers);
nonpitcherMeans = zeros(300, numPitchers);
for k = 1:numPitchers
    pitchData = S.total_pitch_accel_data{k};
    nonpitchData = S.total_non_pitch_accel_data{k};
    assert(size(pitchData,1) == 300 && size(nonpitchData,1) == 300, ...
        'Expected 300 samples (1.5 s at 200 Hz).');
    pitcherMeans(:,k) = mean(pitchData, 2, 'omitnan');
    nonpitcherMeans(:,k) = mean(nonpitchData, 2, 'omitnan');
end

t = (0:299)' / fs;
fig = figure('Units','inches', 'Position',[1 1 9.2 3.5], ...
    'Color','w', 'InvertHardcopy','off');
tl = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

for panel = 1:2
    ax = nexttile(tl);
    hold(ax,'on');
    if panel == 1
        curves = pitcherMeans;
        ylim(ax,[0 12]);
    else
        curves = nonpitcherMeans;
        ylim(ax,[0 1.5]);
    end
    h = gobjects(1,numPitchers);
    for k = 1:numPitchers
        h(k) = plot(ax,t,curves(:,k),'LineWidth',1.5,'Color',colors(k,:));
    end
    xlim(ax,[0 1.5]);
    xticks(ax,0:0.5:1.5);
    xlabel(ax,'Time (s)', 'FontName','Times New Roman','FontSize',10);
    ylabel(ax,'Acceleration Magnitude (g)', 'FontName','Times New Roman','FontSize',10);
    ax.FontName = 'Times New Roman';
    ax.FontSize = 9;
    ax.LineWidth = 0.8;
    ax.Box = 'on';
    ax.TickDir = 'out';
    grid(ax,'on');
    if panel == 2
        labels = arrayfun(@(k) sprintf('Pitcher %02d',k), ...
            1:numPitchers,'UniformOutput',false);
        lgd = legend(ax,h,labels, 'Orientation','horizontal', ...
            'NumColumns',numPitchers,'FontSize',7, 'Box','on');
        lgd.Layout.Tile = 'south';
    end
end

theme(fig, 'light')
exportgraphics(fig,fullfile('figure1.png'),'Resolution',600);
