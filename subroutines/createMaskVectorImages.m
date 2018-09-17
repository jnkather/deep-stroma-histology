% JN Kather, NCT Heidelberg 2017
% this function takes a vector of image names (cleanNames) and a vector of
% sample names (trainSampleIDs) and returns a logical mask the length of
% cleanNames for matching trainSampleIDs

function trainingImageMask = createMaskVectorImages(cleanNames,trainSampleIDs)
    for i = 1:numel(trainSampleIDs)  
        if i==1
        trainingImageMask = contains(cleanNames,trainSampleIDs{i});
        else
        trainingImageMask = trainingImageMask | contains(cleanNames,trainSampleIDs{i});    
        end
    end
end