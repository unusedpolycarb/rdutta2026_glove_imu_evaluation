clear; clc;
S = load('p5_all_outcomes.mat');

TP_choice = 1;
FP_choice = 1;
FN_choice = 1;

TN_candidates = double(S.TN_indices(:));

TN_ranges = max(S.waveforms(:, TN_candidates), [], 1) ...
          - min(S.waveforms(:, TN_candidates), [], 1);

[~, ranked] = sort(TN_ranges, 'descend');

TN_choice = ranked(1);

categories = {'TP', 'FN', 'FP', 'TN'};
choices = [TP_choice, FN_choice, FP_choice, TN_choice];

names = {'(a) True positive (TP)', ...
         '(b) False negative (FN)', ...
         '(c) False positive (FP)', ...
         '(d) True negative (TN)'};

fig = figure('Units', 'inches', ...
    'Position', [1 1 9.2 6.0], ...
    'Color', 'white', ...
    'InvertHardcopy', 'off');

theme(fig, 'light');


tl = tiledlayout(fig, 2, 2, ...
    'TileSpacing', 'compact', ...
    'Padding', 'loose');

axs = gobjects(1, 4);

for j = 1:4

    label = categories{j};
    candidates = double(S.([label '_indices'])(:));
    choice = choices(j);

    assert(choice >= 1 && choice <= numel(candidates), ...
        '%s_choice must be between 1 and %d', ...
        label, numel(candidates));

    testIdx = candidates(choice);

    axs(j) = nexttile(tl);
    ax = axs(j);

    plot(ax, S.time_s(:), S.waveforms(:, testIdx), ...
        'Color', [0 0 0], ...
        'LineWidth', 1.5);

    xlabel(ax, 'Time (s)', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 10, ...
        'Color', 'black');

    ylabel(ax, 'Acceleration Magnitude (g)', ...
        'FontName', 'Times New Roman', ...
        'FontSize', 10, ...
        'Color', 'black');

    title(ax, names{j}, ...
        'FontName', 'Times New Roman', ...
        'FontSize', 11, ...
        'FontWeight', 'normal', ...
        'Color', 'black');

    xlim(ax, [0 1.5]);
    ylim(ax, [0 12]);

    xticks(ax, 0:0.5:1.5);
    yticks(ax, 0:2:12);

    ax.Color = 'white';
    ax.XColor = 'black';
    ax.YColor = 'black';

    ax.FontName = 'Times New Roman';
    ax.FontSize = 9;
    ax.FontWeight = 'normal';

    ax.LineWidth = 0.8;
    ax.Box = 'on';

    ax.TickDir = 'out';
    ax.TickLength = [0 0];

    ax.XAxis.Color = 'black';
    ax.YAxis.Color = 'black';

    grid(ax, 'off');
    axtoolbar(ax, {});
end

title(tl, ...
    {'Classification Outcomes for Held-Out Pitcher P5', ...
     'Using Frequency-Domain Logistic Regression'}, ...
    'FontName', 'Times New Roman', ...
    'FontSize', 13, ...
    'FontWeight', 'normal', ...
    'Color', 'black');

print(fig, 'figure5.png', '-dpng', '-r600');
