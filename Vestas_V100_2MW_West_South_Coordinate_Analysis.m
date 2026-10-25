%% VESTAS V100-2.0 MW: WEST/SOUTH COORDINATE-WISE ANALYSIS
% Input coordinate files: data_LAT_LON in Data1/, format YYYY MM DD HH WIND_SPEED
% Regions: box_1_coords.txt = West, box_2_coords.txt = South
% Periods: Ref 1981-2010; Recent 2011-2015, 2016-2020, 2021-2025.
% Calculates at EACH coordinate, then appends a spatial REGION_MEAN row.
% Uses Vestas curve from Vestas_V100_2MW_Power_Curve.xlsx, rho=1.225 kg/m3.
% V100 = 2 MW. Generation is per one turbine; CF uses 2 MW rating.
% Recent comparisons use mean annual generation (not raw period totals).
% Full annual 1981-2025 generation trend is also calculated.

clear; clc; t0=tic;

%% SETTINGS
COORD_FILE='lat_lon.txt';
WEST_BOUNDARY=fullfile("",'Box_Data','box_1_coords.txt');
SOUTH_BOUNDARY=fullfile("",'Box_Data','box_2_coords.txt');
DATA_FOLDER='.\Wind at 100m\Data\';
CURVE_FILE='Vestas_V100_2MW_Power_Curve.xlsx';
OUT_FOLDER='V100_Regional_Results';
FILE_PREFIX='data_'; 
FILE_DECIMALS=3;
NUM_WORKERS=4; MIN_VALID_FRACTION=0.90;
CUT_IN=3; CUT_OUT=22; RATED_KW=2000; RATED_MW=2;

%% VESTAS V100-2.0 MW: WEST/SOUTH COORDINATE-WISE ANALYSIS
% Worker-safe version for MATLAB parfor.
%
% Input:
%   lat_lon.txt
%   plot_gmt/Box_Data/box_1_coords.txt  -> West
%   plot_gmt/Box_Data/box_2_coords.txt  -> South
%   Data1/data_LAT_LON                 -> YYYY MM DD HH WIND_SPEED
%   Vestas_V100_2MW_Power_Curve.xlsx
%
% Output:
%   V100_Regional_Results/West_V100_2MW_Coordinate_Summary.csv
%   V100_Regional_Results/South_V100_2MW_Coordinate_Summary.csv
%% VESTAS V100-2.0 MW: WEST/SOUTH COORDINATE-WISE ANALYSIS
% Worker-safe version for MATLAB parfor.
%
% Input:
%   lat_lon.txt
%   plot_gmt/Box_Data/box_1_coords.txt  -> West
%   plot_gmt/Box_Data/box_2_coords.txt  -> South
%   Data1/data_LAT_LON                 -> YYYY MM DD HH WIND_SPEED
%   Vestas_V100_2MW_Power_Curve.xlsx
%
% Output:
%   V100_Regional_Results/West_V100_2MW_Coordinate_Summary.csv
%   V100_Regional_Results/South_V100_2MW_Coordinate_Summary.csv


N_TURBINES      = 1;

% Periods: [start_year end_year]
Periods = [1981 2010;
           2011 2015;
           2016 2020;
           2021 2025];

if ~exist(OUT_FOLDER,'dir')
    mkdir(OUT_FOLDER);
end

%% LOAD VESTAS CURVE
fprintf('\n[1/6] Loading Vestas V100-2.0 MW curve...\n');

C = readtable(CURVE_FILE,'VariableNamingRule','preserve');

if ~all(ismember({'WindSpeed_mps','Power_kW'},C.Properties.VariableNames))
    error('Curve file must contain WindSpeed_mps and Power_kW columns.');
end

CurveWS = double(C.WindSpeed_mps);
CurveP  = double(C.Power_kW);

good = isfinite(CurveWS) & isfinite(CurveP);
CurveWS = CurveWS(good);
CurveP  = CurveP(good);

[CurveWS,ord] = sort(CurveWS);
CurveP = CurveP(ord);

if any(diff(CurveWS)<=0)
    error('Curve wind-speed values must be strictly increasing.');
end

fprintf('      %d curve points | %.1f-%.1f m/s | %.0f kW rated\n', ...
    numel(CurveWS),min(CurveWS),max(CurveWS),max(CurveP));

%% LOAD COORDINATES AND BOUNDARIES
fprintf('[2/6] Loading coordinates and region boundaries...\n');

XY = dlmread(COORD_FILE);
XY = XY(:,1:2);

WB = dlmread(WEST_BOUNDARY);
SB = dlmread(SOUTH_BOUNDARY);

% Preserve the same rectangular min/max boundary convention used
% in the existing MASTER_WIND_ANALYSIS workflow.
westMask = XY(:,1)>=min(WB(:,1)) & XY(:,1)<=max(WB(:,1)) & ...
           XY(:,2)>=min(WB(:,2)) & XY(:,2)<=max(WB(:,2));

southMask = XY(:,1)>=min(SB(:,1)) & XY(:,1)<=max(SB(:,1)) & ...
            XY(:,2)>=min(SB(:,2)) & XY(:,2)<=max(SB(:,2));

West  = XY(westMask,:);
South = XY(southMask,:);

fprintf('      Total : %d\n',size(XY,1));
fprintf('      West  : %d\n',size(West,1));
fprintf('      South : %d\n',size(South,1));

%% START PARALLEL POOL
fprintf('[3/6] Starting parallel pool...\n');

pool = gcp('nocreate');

if isempty(pool)
    pool = parpool('local',NUM_WORKERS);
elseif pool.NumWorkers ~= NUM_WORKERS
    delete(pool);
    pool = parpool('local',NUM_WORKERS);
end

% IMPORTANT:
% Make the current MATLAB file explicitly available to workers.
% This prevents the "source code ... could not be found" error when
% processRegion contains the parfor loop.
thisFile = mfilename('fullpath');
if ~isempty(thisFile) && isfile([thisFile '.m'])
    addAttachedFiles(pool,{[thisFile '.m']});
end

fprintf('      Workers: %d\n',pool.NumWorkers);

%% PROCESS WEST
fprintf('\n[4/6] WEST INDIA\n');

W = processRegion( ...
    West,'West',DATA_FOLDER,FILE_PREFIX,FILE_DECIMALS, ...
    CurveWS,CurveP,Periods,CUT_IN,CUT_OUT,RATED_KW,RATED_MW, ...
    N_TURBINES,MIN_VALID_FRACTION);

%% PROCESS SOUTH
fprintf('\n[5/6] SOUTH INDIA\n');

S = processRegion( ...
    South,'South',DATA_FOLDER,FILE_PREFIX,FILE_DECIMALS, ...
    CurveWS,CurveP,Periods,CUT_IN,CUT_OUT,RATED_KW,RATED_MW, ...
    N_TURBINES,MIN_VALID_FRACTION);

%% SAVE
fprintf('\n[6/6] Saving outputs...\n');

WestOut  = fullfile(OUT_FOLDER,'West_V100_2MW_Coordinate_Summary.csv');
SouthOut = fullfile(OUT_FOLDER,'South_V100_2MW_Coordinate_Summary.csv');

writetable(W,WestOut);
writetable(S,SouthOut);

fprintf('      %s\n',WestOut);
fprintf('      %s\n',SouthOut);

printMean(W,'WEST');
printMean(S,'SOUTH');

fprintf('\nDONE in %.2f minutes.\n',toc(t0)/60);

%% ========================================================================
function T = processRegion(XY,RName,DataFolder,FilePrefix,FileDecimals, ...
    CurveWS,CurveP,Periods,CutIn,CutOut,RatedKW,RatedMW, ...
    NTurbines,MinValidFraction)

N = size(XY,1);

fprintf('%s: %d coordinate files.\n',upper(RName),N);

% Coordinate-level outputs
mw  = nan(N,4);
mp  = nan(N,4);
me  = nan(N,4);
cf  = nan(N,4);
vy  = nan(N,4);

dm  = nan(N,3);
dp  = nan(N,3);
lm  = nan(N,3);
lp  = nan(N,3);

trm  = nan(N,1);
trp  = nan(N,1);
trpv = nan(N,1);

status = strings(N,1);
fn     = strings(N,1);

%% Progress
q = parallel.pool.DataQueue;
done = 0;
progressTimer = tic;
afterEach(q,@progressUpdate);

%% PARFOR
parfor i = 1:N

    lat = XY(i,1);
    lon = XY(i,2);

    f = sprintf('%s%.*f_%.*f', ...
        FilePrefix,FileDecimals,lat,FileDecimals,lon);

    fn(i) = string(f);
    status(i) = "OK";

    % Local values returned by this iteration
    a   = nan(1,4);       % annual mean wind
    b   = nan(1,4);       % annual mean power
    e   = nan(1,4);       % annual mean energy
    c   = nan(1,4);       % CF
    yrs = nan(1,4);       % valid years

    ch  = nan(1,3);       % energy change
    cp  = nan(1,3);       % percent change
    lo  = nan(1,3);       % loss
    lop = nan(1,3);       % loss percent

    tm = nan;
    tp = nan;
    pv = nan;

    try

        filePath = fullfile(DataFolder,f);

        if ~isfile(filePath)

            status(i) = "MISSING_FILE";
            send(q,1);

        else

            %% READ POINT FILE
            A = dlmread(filePath);

            if size(A,2) < 5
                error('Expected columns: YYYY MM DD HH WIND_SPEED');
            end

            A = A(:,1:5);

            % Remove rows containing NaN/Inf
            A = A(all(isfinite(A),2),:);

            if isempty(A)
                error('No valid observations.');
            end

            Y = A(:,1);
            M = A(:,2);
            D = A(:,3);
            H = A(:,4);
            V = A(:,5);

            Tm = datetime(Y,M,D,H,0,0);

            %% WIND SPEED -> VESTAS POWER
            %
            % Manufacturer points: linear interpolation.
            % <3 m/s: 0
            % 20 to <22 m/s: rated power
            % >=22 m/s: 0
            %
            P = zeros(size(V));

            inside = V>=min(CurveWS) & V<=max(CurveWS);

            P(inside) = interp1( ...
                CurveWS,CurveP,V(inside),'linear');

            P(V<CutIn) = 0;
            P(V>max(CurveWS) & V<CutOut) = RatedKW;
            P(V>=CutOut) = 0;

            P = max(0,min(RatedKW,P));

            % Hourly energy for one 2-MW turbine
            E = P/1000*NTurbines;

            %% PERIOD CALCULATIONS
            for z = 1:4

                idx = Y>=Periods(z,1) & Y<=Periods(z,2);

                if ~any(idx)
                    continue;
                end

                yy = unique(Y(idx));
                yrs(z) = numel(yy);

                % Exact expected number of hours, including leap years
                expectedHours = hours( ...
                    datetime(Periods(z,2)+1,1,1) - ...
                    datetime(Periods(z,1),1,1));

                if sum(idx) < MinValidFraction*expectedHours
                    continue;
                end

                av = nan(numel(yy),1);
                ap = nan(numel(yy),1);
                ae = nan(numel(yy),1);

                for k = 1:numel(yy)

                    yidx = idx & Y==yy(k);

                    av(k) = mean(V(yidx),'omitnan');
                    ap(k) = mean(P(yidx),'omitnan');
                    ae(k) = sum(E(yidx),'omitnan');

                end

                % IMPORTANT:
                % Mean annual generation = mean of annual generation,
                % not total period generation.
                a(z) = mean(av,'omitnan');
                b(z) = mean(ap,'omitnan');
                e(z) = mean(ae,'omitnan');

                % Capacity factor of the actual 2 MW turbine
                c(z) = 100*e(z)/(RatedMW*8760*NTurbines);

            end

            %% CHANGE FROM 1981-2010
            for z = 1:3

                if isfinite(e(1)) && isfinite(e(z+1))

                    ch(z) = e(z+1)-e(1);
                    cp(z) = 100*ch(z)/e(1);

                    % Positive loss only
                    lo(z) = max(e(1)-e(z+1),0);
                    lop(z) = 100*lo(z)/e(1);

                end

            end

            %% ANNUAL GENERATION TREND, 1981-2025
            allYears = unique(Y);

            annualE = nan(size(allYears));

            for k = 1:numel(allYears)

                yidx = Y==allYears(k);

                annualE(k) = sum(E(yidx),'omitnan');

            end

            trendOK = isfinite(annualE) & ...
                      allYears>=1981 & allYears<=2025;

            if sum(trendOK)>=10

                xx = allYears(trendOK);
                zz = annualE(trendOK);

                % Linear trend
                fitCoef = polyfit(xx,zz,1);

                slopeMWhPerYear = fitCoef(1);

                tm = slopeMWhPerYear*10;

                meanAnnualE = mean(zz,'omitnan');

                if meanAnnualE ~= 0
                    tp = 100*tm/meanAnnualE;
                end

                % p-value for slope
                Xfit = [ones(numel(xx),1),xx];

                beta = Xfit\zz;
                residual = zz-Xfit*beta;

                dof = numel(zz)-2;

                if dof>0

                    s2 = sum(residual.^2)/dof;

                    XtX = Xfit'*Xfit;

                    CovB = s2*(XtX\eye(2));

                    seSlope = sqrt(CovB(2,2));

                    tStat = beta(2)/seSlope;

                    pv = 2*(1-tcdf(abs(tStat),dof));

                end

            end

            send(q,1);

        end

    catch ME

        status(i) = "ERROR";

        warning('%s: %s',f,ME.message);

        send(q,1);

    end

    %% Return parfor iteration values
    mw(i,:)  = a;
    mp(i,:)  = b;
    me(i,:)  = e;
    cf(i,:)  = c;
    vy(i,:)  = yrs;

    dm(i,:)  = ch;
    dp(i,:)  = cp;
    lm(i,:)  = lo;
    lp(i,:)  = lop;

    trm(i)   = tm;
    trp(i)   = tp;
    trpv(i)  = pv;

end

%% BUILD TABLE
T = table( ...
    XY(:,1),XY(:,2),fn,status, ...
    'VariableNames',{'Latitude','Longitude','DataFile','Status'});

T = [T table( ...
    mw(:,1),mw(:,2),mw(:,3),mw(:,4), ...
    'VariableNames',{ ...
    'MeanAnnualWind_Ref_1981_2010', ...
    'MeanAnnualWind_2011_2015', ...
    'MeanAnnualWind_2016_2020', ...
    'MeanAnnualWind_2021_2025'})];

T = [T table( ...
    mp(:,1),mp(:,2),mp(:,3),mp(:,4), ...
    'VariableNames',{ ...
    'MeanAnnualPower_kW_Ref', ...
    'MeanAnnualPower_kW_2011_2015', ...
    'MeanAnnualPower_kW_2016_2020', ...
    'MeanAnnualPower_kW_2021_2025'})];

T = [T table( ...
    me(:,1),me(:,2),me(:,3),me(:,4), ...
    'VariableNames',{ ...
    'MeanAnnualEnergy_MWh_Ref', ...
    'MeanAnnualEnergy_MWh_2011_2015', ...
    'MeanAnnualEnergy_MWh_2016_2020', ...
    'MeanAnnualEnergy_MWh_2021_2025'})];

T = [T table( ...
    cf(:,1),cf(:,2),cf(:,3),cf(:,4), ...
    'VariableNames',{ ...
    'CF_pct_Ref', ...
    'CF_pct_2011_2015', ...
    'CF_pct_2016_2020', ...
    'CF_pct_2021_2025'})];

T = [T table( ...
    vy(:,1),vy(:,2),vy(:,3),vy(:,4), ...
    'VariableNames',{ ...
    'ValidYears_Ref', ...
    'ValidYears_2011_2015', ...
    'ValidYears_2016_2020', ...
    'ValidYears_2021_2025'})];

T = [T table( ...
    dm(:,1),dm(:,2),dm(:,3), ...
    dp(:,1),dp(:,2),dp(:,3), ...
    'VariableNames',{ ...
    'Change_MWh_2011_2015_vs_Ref', ...
    'Change_MWh_2016_2020_vs_Ref', ...
    'Change_MWh_2021_2025_vs_Ref', ...
    'Change_pct_2011_2015_vs_Ref', ...
    'Change_pct_2016_2020_vs_Ref', ...
    'Change_pct_2021_2025_vs_Ref'})];

T = [T table( ...
    lm(:,1),lm(:,2),lm(:,3), ...
    lp(:,1),lp(:,2),lp(:,3), ...
    trm,trp,trpv, ...
    'VariableNames',{ ...
    'Loss_MWh_2011_2015_vs_Ref', ...
    'Loss_MWh_2016_2020_vs_Ref', ...
    'Loss_MWh_2021_2025_vs_Ref', ...
    'Loss_pct_2011_2015_vs_Ref', ...
    'Loss_pct_2016_2020_vs_Ref', ...
    'Loss_pct_2021_2025_vs_Ref', ...
    'GenerationTrend_MWh_per_decade', ...
    'GenerationTrend_pct_per_decade', ...
    'GenerationTrend_pValue'})];

%% APPEND REGIONAL SPATIAL MEAN
numeric = varfun(@isnumeric,T,'OutputFormat','uniform');

R = T(1,:);

R.Latitude = NaN;
R.Longitude = NaN;
R.DataFile = "REGION_MEAN";
R.Status = "REGION_MEAN";

for j = 1:width(T)

    if numeric(j) && j>2
        R{1,j} = mean(T{:,j},'omitnan');
    end

end

T = [T;R];

fprintf('%s completed.\n',upper(RName));

%% PROGRESS CALLBACK
function progressUpdate(~)

    done = done+1;

    if done==1 || done==N || mod(done,max(1,ceil(N/100)))==0

        elapsed = toc(progressTimer);
        rate = done/max(elapsed,eps);
        eta = (N-done)/max(rate,eps);

        fprintf('\r%s: %d/%d (%.1f%%) | %.2f files/s | ETA %.1f min', ...
            upper(RName),done,N,100*done/N,rate,eta/60);

        if done==N
            fprintf('\n');
        end

    end

end

end

%% ========================================================================
function printMean(T,RName)

idx = T.Status=="REGION_MEAN";

if ~any(idx)
    return;
end

R = T(idx,:);

fprintf('\n============================================================\n');
fprintf('%s INDIA - REGIONAL MEAN\n',RName);
fprintf('============================================================\n');

fprintf('1981-2010 mean wind speed : %.4f m/s\n', ...
    R.MeanAnnualWind_Ref_1981_2010);

fprintf('1981-2010 mean annual power : %.2f kW\n', ...
    R.MeanAnnualPower_kW_Ref);

fprintf('1981-2010 mean annual energy : %.2f MWh/turbine\n', ...
    R.MeanAnnualEnergy_MWh_Ref);

fprintf('1981-2010 capacity factor : %.3f %%\n', ...
    R.CF_pct_Ref);

fprintf('\nChanges relative to 1981-2010:\n');

fprintf('2011-2015 : %+0.3f %% | %+0.2f MWh/year\n', ...
    R.Change_pct_2011_2015_vs_Ref, ...
    R.Change_MWh_2011_2015_vs_Ref);

fprintf('2016-2020 : %+0.3f %% | %+0.2f MWh/year\n', ...
    R.Change_pct_2016_2020_vs_Ref, ...
    R.Change_MWh_2016_2020_vs_Ref);

fprintf('2021-2025 : %+0.3f %% | %+0.2f MWh/year\n', ...
    R.Change_pct_2021_2025_vs_Ref, ...
    R.Change_MWh_2021_2025_vs_Ref);

fprintf('\nGeneration trend 1981-2025:\n');

fprintf('  %.3f MWh/decade\n',R.GenerationTrend_MWh_per_decade);
fprintf('  %.3f %%/decade\n',R.GenerationTrend_pct_per_decade);
fprintf('  p = %.5g\n',R.GenerationTrend_pValue);

end
