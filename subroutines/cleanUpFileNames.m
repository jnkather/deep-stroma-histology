% JN Kather, 2017
% this function uses pre-defined stop strings to clean up file names given
% in allnames
% example: cleanNames contains the TCGA Sample ID for each block

function cleanNames = cleanUpFileNames(allnames,stopStr)

cleanNames = allnames;
for i=1:numel(allnames) % iterate all names
    currname = allnames{i}; % get current name
    for termination = stopStr
    en = strfind(currname,termination);
    if ~isempty(en), break
    end
    end
    if isempty(en)
        warning(['possible MISMATCH in ',num2str(i)]);
    else
        cleanNames{i} = currname(1:(en-1));
    end
    en = [];
end

end