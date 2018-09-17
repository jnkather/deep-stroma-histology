function fout = rotinvNet(net,img,lay,rotInv)

% define rotation functions
rot180 = @(I) rot90(rot90(I));
rot270 = @(I) rot90(rot90(rot90(I)));

environ = 'gpu';

if rotInv
% feature vector in all rotations
fvec1 = double(activations(net,      img,lay,'ExecutionEnvironment',environ));
fvec2 = double(activations(net,rot90(img),lay,'ExecutionEnvironment',environ));
fvec3 = double(activations(net,rot180(img),lay,'ExecutionEnvironment',environ));
fvec4 = double(activations(net,rot270(img),lay,'ExecutionEnvironment',environ));

% construct output from mean of rotated images,  reshape feature vector
fout = reshape(mean([fvec1;fvec2;fvec3;fvec4]),[1,1,net.Layers(lay).OutputSize]); 

else
    fvec = double(activations(net,      img,lay,'ExecutionEnvironment',environ));
    fout = reshape(fvec,[1,1,net.Layers(lay).OutputSize]); 
end

end