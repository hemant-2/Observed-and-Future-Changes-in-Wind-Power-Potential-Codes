clc;
clear;
c = dlmread("lat_lon.txt");
for i=1:2
    box_c = dlmread(sprintf("./plot_gmt/Box_Data/box_%d_coords.txt",i));
    idx = find(c(:,1)<=max(box_c(:,1)) & c(:,1)>=min(box_c(:,1)) & c(:,2)<=max(box_c(:,2)) & c(:,2)>=min(box_c(:,2)));
    area=[];
    area(:,1:2) = c(idx,1:2);
    for j=1:length(area)
        wp = dlmread(sprintf('./ERA5 Data/Wind Potential Data Yearly/data_%.3f_%.3f',area(j,1),area(j,2)));
        cwp(:,j) = wp(:,2);
    end
    
    cmwp = mean(cwp,"all","omitnan");
    mwp = mean(cwp,2,"omitnan");
    A = mwp - cmwp;
    d = find(isnan(A));
    wp(d,:)=[];
    A(d)=[];
    data = [wp(:,1) A];
    dlmwrite(sprintf("./plot_gmt/Box_Data/box_%d_wp2",i),data,' ');
end
