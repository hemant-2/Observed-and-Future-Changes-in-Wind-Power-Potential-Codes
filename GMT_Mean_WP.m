clc;
clear;
c = dlmread("lat_lon.txt");

out=[];
scen={'historical' 'ssp126' 'ssp245' 'ssp370' 'ssp585'};
model=importdata('Model_List1');

for a=1:length(model)
    gmt = dlmread(sprintf("GMT_Data/%s_Data",char(model(a))));
    for b=1:length(scen)
        for cc=1:length(c)
            wp = dlmread(sprintf('./Wind_Potential/%s/%s/data_%.3f_%.3f',char(model(a)),char(scen(b)),c(cc,1), c(cc,2)));
            
            yl=[]; f=[];yl15=[]; yl20=[]; yl25=[];
            if b==1

                f = find(wp(:,1)>=1981 & wp(:,1)<=2010);
                yl = mean(wp(f,4));
                out(cc,1:3)=[c(cc,1) c(cc,2) yl];
                disp([a b cc])
            else
                l15=1; l20=1; l25=1;l=1;
                for i=0:10:70
                     f=[];
                    f = find(wp(:,1)>=2021+i & wp(:,1)<=2030+i);
                    
                    switch gmt(b-1,l)
                        case 1.5
                            yl15(1,l15) = mean(wp(f,4));
                            l15=l15+1;
                        case 2.0
                             yl20(1,l20) = mean(wp(f,4));
                             l20=l20+1;
                            
                        case 2.5
                             yl25(1,l25) = mean(wp(f,4));    
                             l25=l25+1;
                    end
                    l=l+1;
                end
                ylm15=[]; ylm20=[]; ylm25=[];
                    ylm15 = mean(yl15,'omitnan');
                    ylm20 = mean(yl20,'omitnan');
                    ylm25 = mean(yl25,'omitnan');
                  
                    out15(cc,1:3)=[c(cc,1) c(cc,2) ylm15];
                    out20(cc,1:3)=[c(cc,1) c(cc,2) ylm20];
                    out25(cc,1:3)=[c(cc,1) c(cc,2) ylm25];
                    disp([a b cc]) 
            end
            
        end
        if b==1
        dlmwrite(sprintf('./GMT_Data/GMT_ref_%s_%s',char(model(a)),char(scen(1))),out,' ');
        end
        if b>1
        dlmwrite(sprintf('./GMT_Data/GMT_1.5_%s_%s',char(model(a)),char(scen(b))),out15,' ');
        dlmwrite(sprintf('./GMT_Data/GMT_2.0_%s_%s',char(model(a)),char(scen(b))),out20,' ');
        dlmwrite(sprintf('./GMT_Data/GMT_2.5_%s_%s',char(model(a)),char(scen(b))),out25,' ');
        end
        

    end
end