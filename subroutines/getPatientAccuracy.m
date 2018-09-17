function [uCleanNames,truePatientLabel,predictedPatientLabel,PerPatientAccuracy] = ...
    getPatientAccuracy(testing_inputPath,testing_set,predictedLabels)
    
    trueLabels = testing_set.Labels; % extract true labels
    allFileNames = testing_set.Files;
    ulabels = cellstr(unique(testing_set.Labels)); % find unique labels
    removeStrings = {'/','\','E1_','E2_','E3_','E4_','E5_','E6_','E7_','E8_','E9_'};
    for i = 1:numel(allFileNames) % iterate all files and clean up
        allFileNames{i} = strrep(allFileNames{i},testing_inputPath,''); %remove input path
        for j = 1:numel(ulabels) % remove input category folder
            allFileNames{i} = strrep(allFileNames{i},ulabels{j},''); 
        end
        for j = 1:numel(removeStrings) % remove additional strings
            allFileNames{i} = strrep(allFileNames{i},removeStrings{j},''); 
        end
    end
    % clean up all block file names (so that only the TCGA ID remains)
    stopStr = {'-01A','-01B','-01C','-01D','-01E','-01F'};
    cleanNames = cleanUpFileNames(allFileNames,stopStr);
    
    % cleanNames contains the TCGA ID only
    [uCleanNames,~,ic] = unique(cleanNames);
    
    for i = unique(ic)' % find the predicted labels
    currEnsemble = predictedLabels(ic==i);
    predictedPatientLabel(i) = mode(currEnsemble);
    end
    
    for i = unique(ic)' % find the true labels
    currEnsemble = trueLabels(ic==i);
    truePatientLabel(i) = mode(currEnsemble);
    end
    
    
    PerPatientAccuracy = sum(predictedPatientLabel==truePatientLabel) / ...
        numel(truePatientLabel);
    
end