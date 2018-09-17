% JN Kather 2017
function copyImages(allnames,utypes,PROPvec,targetDir,subsetMask,ImageFileDir,expandDataset)

% iterate unique CMS
for i = 1:numel(utypes)
    currtype = utypes{i};
    currCMSmask = contains(PROPvec,currtype); % find matching images
    currCopyMask = currCMSmask(:) & subsetMask(:);
    disp(['found ' num2str(sum(currCopyMask)) ' images (not samples) for type '...
        char(currtype)]);
    currTargetDir = [targetDir,char(currtype),'/']; % target directory
    mkdir(currTargetDir);
    currImageNames = allnames(currCopyMask);
    for j = 1:numel(currImageNames)% iterate all images and copy to target dir
        currFname = char(currImageNames{j});
        currImage = imread([ImageFileDir,currFname]);
        % write image to target dir
        imwrite(currImage,[currTargetDir,currFname]);
        if expandDataset % perform data augmentation
            imwrite(flipud(currImage),[currTargetDir,'E1_',currFname]);
            imwrite(fliplr(currImage),[currTargetDir,'E2_',currFname]);
            imwrite(rot90(currImage),[currTargetDir,'E3_',currFname]);
            imwrite(rot90(rot90(currImage)),[currTargetDir,'E4_',currFname]);
            imwrite(rot90(rot90(rot90(currImage))),[currTargetDir,'E5_',currFname]);
            tsize = size(currImage);
            centercrop = imresize(currImage(15:(end-15),15:(end-15),:),tsize(1:2));
            imwrite(centercrop,[currTargetDir,'E6_',currFname]);
            imwrite(flipud(centercrop),[currTargetDir,'E7_',currFname]);
            imwrite(fliplr(centercrop),[currTargetDir,'E8_',currFname]);
        end
    end
end

end