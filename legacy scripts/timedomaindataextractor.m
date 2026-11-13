clear; clc;

fs = 200;

fileList = {
    'tnp_test.csv'
    'tnp_train.csv'
    'tp_test.csv'
    'tp_train.csv'
};

for f = 1:numel(fileList)

    data = readmatrix(fileList{f});
    numSignals = size(data, 2);

    Peak1 = nan(numSignals,1);
    Peak2 = nan(numSignals,1);
    PeakDistance_s = nan(numSignals,1);

    for i = 1:numSignals
        signal = data(:, i);

        [pks, locs] = findpeaks(signal, ...
            'SortStr','descend');

        if numel(pks) >= 2
            % top 2 peaks
            Peak1(i) = pks(1);
            Peak2(i) = pks(2);

            % distance between them (in time order)
            topLocs = sort(locs(1:2));
            PeakDistance_s(i) = (topLocs(2) - topLocs(1)) / fs;
        end
    end

    % save results
    features = [Peak1'; Peak2'; PeakDistance_s'];

    [~, name, ~] = fileparts(fileList{f});
    writematrix(features, [name '_peak_features.csv']);
end