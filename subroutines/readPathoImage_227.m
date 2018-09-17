function [ im ] = readPathoImage_227( imageFile)

finalDim = 227;

im = imread(imageFile);

% resize image
if size(im,1) ~= finalDim || size(im,2) ~= finalDim
im = imresize(im,[finalDim,finalDim]);
end

end
