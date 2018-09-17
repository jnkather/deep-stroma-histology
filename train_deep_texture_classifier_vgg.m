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
% It requires Matlab R2017b, the neural network toolbox and the pre-trained
% vgg19 model from the Matlab App store. Please observe that different
% licenses may apply to these software packages.
% 
% the image data sets are available separately, see readme

clear all, close all, format compact, clc
addpath('./subroutines/');

% specify data sources
training_inputPath =  '<training input image path here>';
testing_inputPath = '<testing input image path here>'; 

%% READ TRAINING IMAGES
disp('loading TRAINING images');
training_set = imageDatastore(training_inputPath,'IncludeSubfolders',true,'LabelSource','foldernames');
training_set.ReadFcn = @readPathoImage_224; % read and resize images to 224
training_tbl = countEachLabel(training_set) %#ok
training_categories = training_tbl.Label; % extract category labels (from folder name)
disp('successfully loaded TRAINING images');
figure, imshow(preview(training_set)); % show preview image

%% PREPARE AND MODIFY NEURAL NET
rawnet = vgg19;
lgraph = rawnet.Layers;
lgraph(end-2) = fullyConnectedLayer(numel(unique(training_set.Labels)));
lgraph(end) = classificationLayer;
imageInputSize = lgraph(1).InputSize(1:2);
disp(['sucessfully loaded&modified network, input size is ', num2str(imageInputSize)]);

%% DATA AUGMENTATION FOR TRAINING
imageAugmenter = imageDataAugmenter('RandXReflection',true,'RandYReflection',true);
augmented_training_set = augmentedImageSource(imageInputSize,training_set,'DataAugmentation',imageAugmenter);
disp('successfully loaded image augmenter');

%% TRAIN
opts = trainingOptions('sgdm',...
    'MiniBatchSize',360,...           
    'MaxEpochs',8,...               
    'InitialLearnRate',3e-4,...       
    'VerboseFrequency',1,...
    'ExecutionEnvironment','multi-gpu');
myNet = trainNetwork(augmented_training_set, lgraph, opts);

%% READ TESTING IMAGES
disp('loading TESTING images');
testing_set = imageDatastore(testing_inputPath,'IncludeSubfolders',true,'LabelSource','foldernames');
testing_set.ReadFcn = @readPathoImage_224; % read and resize images
testing_tbl = countEachLabel(testing_set) %#ok
testing_categories = testing_tbl.Label; % extract category labels (from folder name)
disp('successfully loaded TESTING images');
figure, imshow(preview(testing_set)); % show preview image

%% DEPLOY
predictedLabels = classify(myNet, testing_set);

%% assess accuracy, show confusion matrix
labels_ground = testing_set.Labels;
labels_pred = predictedLabels;
PerItemAccuracy = mean(labels_pred == labels_ground);
disp(['per image accuracy is ',num2str(PerItemAccuracy)]);
allgroups = cellstr(unique(labels_ground));
conf = confusionmat(labels_ground,labels_pred);
figure(),imagesc(conf);
xlabel('predicted'),ylabel('known');
set(gca,'XTickLabel',allgroups);
set(gca,'YTickLabel',allgroups);
axis square
colorbar
set(gcf,'Color','w');
title(['classification with accuracy ',num2str(round(100*PerItemAccuracy)),'%']);

% save final network
save('.\trained_vgg19_model\lastNet_TEXTURE_VGG.mat','myNet','PerItemAccuracy');
