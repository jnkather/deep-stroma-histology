function [ im ] = readPathoImage_224( imageFile)

finalDim = 224;

im = imread(imageFile);

% resize image
if size(im,1) ~= finalDim || size(im,2) ~= finalDim
im = imresize(im,[finalDim,finalDim]);
end

end
