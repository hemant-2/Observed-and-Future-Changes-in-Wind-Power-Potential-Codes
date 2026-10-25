clc
clear;
c = dlmread("lat_lon.txt");

out=[];
for i=1:length(c)

wp = dlmread(sprintf('E:\\Civil_Server\\ERA5 Data\\Wind_Potential_ERA5\\data_%.3f_%.3f',c(i,1), c(i,2)));

yl=[];
yl(:,1) = (1951:2025)';
for j=1:length(yl(:,1))
    %a=find(yl(j,1)==wp(:,1) & wp(:,2)>=6 & wp(:,2)<=9);
    a=find(yl(j,1)==wp(:,1));
    yl(j,2) = mean(wp(a,4));
    if isnan(yl(j,2))
        yl(j,2)=0;
    end
end
% mp = mean(yl(:,2));
% yc(:,1) = yl(:,1);
% yic(:,1) = yl(:,1);
% for j=1:length(yl)
%     yc(j,2) = ((yl(j,2) - mp)/mp)*100;
%     if isnan(yc(j,2))
%         yc(j,2)=0;
%     end
%     % yic(j,2) = ((yl(j,2) - yl(1,2))/yl(1,2))*100;
% end
alpha = 0.05;
wantplot = 0;
[taub, tau, h, sig, Z, S, sigma, sen, n, senplot, CIlower, CIupper, D, Dall, C3, nsigma] = ktaub(yl, alpha, wantplot);
tyc = sen * 75;
out(i,:)=[c(i,1) c(i,2) sen tyc h];
% [taubc, tauc, hc, sigc, Zc, Sc, sigmac, senc, nc, senplotc, CIlowerc, CIupperc, Dc, Dallc, C3c, nsigmac] = ktaub(yc, alpha, wantplot);
% tyic = senc * 72;
% out1(i,1:6)=[c(i,1) c(i,2) senc tyic];
%fprintf("data_%.3f_%.3f is complete\n",c(i,1), c(i,2));
disp(i)
end
sens = out;
dlmwrite('Sens_Plot_ERA5_Data_2025',sens,' ')
