clc;
clear;

files   = {'V100_Regional_Results\West_V100_2MW_Coordinate_Summary.csv','V100_Regional_Results\South_V100_2MW_Coordinate_Summary.csv'};
boxes   = {'box_1','box_2'};

progRows = [];

for code = 1:2
    box = boxes{code};

    T = readtable(files{code});
    keep = ~strcmp(string(T.DataFile), 'REGION_MEAN');
    T = T(keep, :);

    lat  = T.Latitude;
    lon  = T.Longitude;
    d1   = T.Change_pct_2011_2015_vs_Ref;
    d2   = T.Change_pct_2016_2020_vs_Ref;
    d3   = T.Change_pct_2021_2025_vs_Ref;
    pval = T.GenerationTrend_pValue;
    v0   = T.MeanAnnualWind_Ref_1981_2010;
    v1   = T.MeanAnnualWind_2021_2025;
    dv3  = (v1 - v0) ./ v0 * 100;
    trend = T.GenerationTrend_pct_per_decade;

    n = height(T);
    fid = fopen([box '_v100_generation.txt'], 'w');
    for i = 1:n
        fprintf(fid, '%.3f %.3f %.4f %.4f %.4f %.4e %.4f %.4f\n', ...
            lat(i), lon(i), d1(i), d2(i), d3(i), pval(i), dv3(i), trend(i));
    end
    fclose(fid);
    fprintf('%s_v100_generation.txt  %d cells\n', box, n);

    dcols = [d1 d2 d3];
    for k = 1:3
        x = dcols(:,k);
        progRows = [progRows; k, code, mean(x), prctile(x,10), prctile(x,90), 100*mean(x<0)];
    end
end

fid = fopen('v100_progression.txt', 'w');
for i = 1:size(progRows,1)
    fprintf(fid, '%d %d %.4f %.4f %.4f %.1f\n', progRows(i,:));
end
fclose(fid);
fprintf('v100_progression.txt  %d rows\n', size(progRows,1));
