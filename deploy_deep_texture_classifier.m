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
% this script will use a trained neural network model and apply it for
% tissue classification and to derive raw values for the deep stroma score
%
% assumes that a network is loaded in the workspace and is called myNet.
% This is available in the "trained_vgg19_model" folder
%
close all, clc

addpath(genpath('./subroutines/'));
mkdir('./output_images');

% colors
%           ADI         BACK      DEB       LYM          MUC     MUS     NORM      STR      TUM 
colors = [ 141 141 141;53 53 53;189 41 153; 30 149 191; 250 216 206; 68 172 35; ...
    204 102 0; 247 188 10; 230 73 22]/255;
tissuenames = {'ADI','BACK','DEB','LYM','MUC','MUS','NORM','STR','TUM'};
verbose = true;

% assumes that a network is loaded in the workspace and is called myNet
deploy_dataPath = '<enter path to images here>';
allFiles = dir([deploy_dataPath,'*.tif']);
border = [94 94];   % indirectly define the step size of sliding windows
                    % default 90 90. step size is 222-2xborder(1), so 109
                    % yields a step size of 6 px. warning: this may take
                    % several hours per image
                    % border 90 -> 23 min per image on Desktop
                    % default 70 70, max 110
                    % the larger the value, the more detailed the image
                    
% calculate offset
layerNum = numel(myNet.Layers);
bsize = myNet.Layers(1).InputSize;
bsize = bsize(1:2)-2*border;
depth = myNet.Layers(layerNum).OutputSize;
rmov = ceil(border(1)/bsize(1)); % was +1
rotInv = false;

% classification function: use the GPU to get the deep layer activations
activateMyNet = @(I) rotinvNet(myNet,I.data,layerNum,rotInv); 

for i = 1:numel(allFiles) % GPU is way faster than parallel CPU
tic
currFilePath = [deploy_dataPath,allFiles(i).name];
disp('starting to process next image');

% process image blockwise. Do not use parallel processing because this
% cannot be combined with GPU
mask = blockproc(currFilePath,bsize(1:2),activateMyNet,...
    'TrimBorder',false,'BorderSize',border,...
    'PadPartialBlocks',true,'UseParallel',false);
disp('finished blockproc');

mask = mask((rmov):(end-rmov),(rmov):(end-rmov),:); % remove margin

[rgbout, currstats] = mask9toRGB(mask,colors);

if verbose
figure()
subplot(1,2,1)
imshow(currFilePath)
subplot(1,2,2)
imagesc(rgbout),axis equal tight off
suptitle(strrep(allFiles(i).name,'_',' '));
set(gcf,'Color','w');
drawnow
end

allstats(i,:) = currstats(:);
allnames{i} = allFiles(i).name;

% visualize tumor-stroma-lympho
imwrite(rgbout,['./output_images/mask_',num2str(border(1)),'_',allFiles(i).name,'_VGG.tif']);
toc
end

statstable = [array2table(allnames','VariableNames',{'ID'}),...
    array2table(allstats,'VariableNames',tissuenames)]

writetable(statstable,'lastResultsTable.xlsx');
