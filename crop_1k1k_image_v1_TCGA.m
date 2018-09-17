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
% crop images to 1K x 1K
% perform Macenko color normalization

clear all, close all, clc
addpath(genpath('./subroutines_normalization'));

sourcePath = '[source path to large tumor images]'; 
ref_image_path = 'Ref.png';
ref_image = imread(ref_image_path);
outputPath = '[path to output folder]';
mkdir(outputPath);
rng('shuffle');

% read all input image files
allMyFiles = dir([sourcePath,'*.tif']);
skips = 0;
verbose = false;
MPPtable = readtable('[a table containing MPP data for each patient, MPP = microns per pixel]');
allMPPs = MPPtable.MPP;
allMPPNames = MPPtable.allIDs;
targetMPP = 0.5;
targetDim = 1500; % target pixel size, v1: 1500

for i=1:numel(allMyFiles)
    
    currImageName = allMyFiles(i).name;
    matchMPP = strcmp(allMPPNames,strrep(currImageName,'.tif',''));
    sourceMPP = allMPPs(matchMPP);
    
    
    currImagePath = [sourcePath,currImageName];
    currOutputPath = [outputPath,'norm_2k2k_',currImageName];
    
    currImage = imread(currImagePath);
    currImage = imresize(currImage,sourceMPP/targetMPP); % RESIZE TO TARGET MPP (microns per pixel)
    currXsize = size(currImage,1);
    currYsize = size(currImage,2);

    if currXsize>targetDim & currYsize>targetDim
       % crop non-square images to 1K by 1K
       currXoffset = round((currXsize-targetDim)/2);
       currYoffset = round((currYsize-targetDim)/2);
       currImage = currImage(currXoffset:(currXoffset+targetDim-1),...
                             currYoffset:(currYoffset+targetDim-1),:);
                         
       tic
        [ NormMM ] = Norm(currImage, ref_image, 'Macenko', 255, 0.15, 1, verbose);
        toc
        imwrite(NormMM,currOutputPath); 
    
    else
        currXsize
        currYsize
        warning('WRONG IMAGE DIMENSION... will skip this image');
        skips = skips +1;
        disp(num2str(skips)); 

    end
	
end
