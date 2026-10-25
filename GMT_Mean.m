clc;
clear;
c = dlmread("lat_lon.txt");

out=[];
scen={'historical' 'ssp126' 'ssp245' 'ssp370' 'ssp585'};
model=importdata('Model_List2');
for a=1:length(model)
    out = dlmread(sprintf('./GMT_Data/GMT_ref_%s_%s',char(model(a)),char(scen(1))));
    for b=2:length(scen)
            out15 = dlmread(sprintf('./GMT_Data/GMT_1.5_%s_%s',char(model(a)),char(scen(b))));
            out20 = dlmread(sprintf('./GMT_Data/GMT_2.0_%s_%s',char(model(a)),char(scen(b))));
            out25 = dlmread(sprintf('./GMT_Data/GMT_2.5_%s_%s',char(model(a)),char(scen(b))));
%             out15(isnan(out15(:,3)),3) = 0;
%             out20(isnan(out20(:,3)),3) = 0;
%             out25(isnan(out25(:,3)),3) = 0;

%             if mean(out15(:,3))~=0
                  m15(:,b-1) = out15(:,3) - out(:,3);
%             else
%                 m15(length(out15),b-1) = 0;
%             end
%             if mean(out20(:,3))~=0
                  m20(:,b-1)= out20(:,3) - out(:,3);
%             else
%                 m20(length(out20),b-1) = 0;
%             end
%             if mean(out25(:,3))~=0
                  m25(:,b-1)= out25(:,3) - out(:,3);
%             else
%                 m25(length(out25),b-1) = 0;
%             end

    end
%     zeroc = all(m15== 0);
%     m15 = m15(:,~zeroc);
%     zeroc = all(m20== 0);
%     m20 = m20(:,~zeroc);
%     zeroc = all(m25== 0);
%     m25 = m25(:,~zeroc);
    m(:,1:2) = c;
    m(:,3) = mean(m15,2,'omitnan');
    m(:,4) = mean(m20,2,'omitnan');
    m(:,5) = mean(m25,2,'omitnan');
    m15 =[]; m20=[]; m25=[];
    dlmwrite(sprintf('./GMT_Data/GMT_%s',char(model(a))),m,' ');

end
for a=1:length(model)
    m = dlmread(sprintf('./GMT_Data/GMT_%s',char(model(a))));
     d15(:,a) = m(:,3);
%     if isnan(d15(:,a))
%         d15(:,a) =[];
%     end
     d20(:,a) = m(:,4);
%     if isnan(d20(:,a))
%         d20(:,a) =[];
%     end
     d25(:,a) = m(:,5);
%     if isnan(d25(:,a))
%         d25(:,a) =[];
%     end

end
d15 = [c mean(d15,2,"omitnan")];
d20 = [c mean(d20,2,"omitnan")];
d25 = [c mean(d25,2,"omitnan")];
dlmwrite('./GMT_Data/GMT_1.5',d15,' ');
dlmwrite('./GMT_Data/GMT_2.0',d20,' ');
dlmwrite('./GMT_Data/GMT_2.5',d25,' ');
