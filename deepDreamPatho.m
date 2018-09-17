% JN Kather, NCT Heidelberg / RWTH Aachen, 2017-2018
% see separate LICENSE 
%
% This MATLAB script is associated with the following project
% "A deep learning based stroma score is an independent prognostic 
% factor in colorectal cancer"
% Please refer to the article and the supplemntary material for a
% detailed description of the procedures. This is experimental software
% and should be used with caution.
% 
% this script will create a deep dream visualization
%
% assumes the neural net is loaded as myNet, works for VGG19

close all

names = {'ADI','BACK','DEB','LYM','MUC','MUS','NORM','STR','TUM'};

for layer =  46
    for pyram = 12 %[6,12,18]
        for iter = 75 %[50,75,100]
            for scale = 1.1
                figure
                    for i=1:9
                    currImages(:,:,:,i) = deepDreamImage(myNet,layer,i,'Verbose',true,'PyramidLevels',pyram,...
                        'NumIterations',iter,'PyramidScale',scale,'ExecutionEnvironment','gpu');
                    end
                    lastMontage = montage(currImages);
                    clear currImages % prevent spillover
                    currTitle = ['VGG v2 layer ',num2str(layer),' pyram ',num2str(pyram),' iter ',num2str(iter),...
                        ' scale ',num2str(scale)];
                    suptitle(currTitle);
                    currRGB = lastMontage.CData;
                    imwrite(currRGB,['./dreamoutput/',currTitle,'.png']);
            end
        end
    end
end