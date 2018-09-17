function myNet = trainMyNet(net,imds,workhorse,NumEpochs,numClasses)

opts = trainingOptions('sgdm', 'InitialLearnRate', 3E-4, ... 
    'MaxEpochs', NumEpochs, 'MiniBatchSize', 360,'ExecutionEnvironment',workhorse);
myNet = trainNetwork(imds, layers, opts);

end