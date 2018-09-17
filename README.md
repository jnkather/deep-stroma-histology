# deep-stroma-histology
Convolutional neural networks for extracting a "deep stroma score" from histological images of human cancer

## What is this?
This is Matlab code to train a convolutional neural network for tissue classification in histological images of human cancer. This network can be used to derive a "deep stroma" risk score from such images. Also, this repository contains R code that we used for downstream statistics. The methods are described in our paper "A deep learning based stroma score is an independent prognostic factor in colorectal cancer"

## What do I need to get started?
You need the code (provided in this repository) and the images which are available for download here: http://doi.org/10.5281/zenodo.1214456 We used the normalized 100K data set for training, but you can also download the non-normalized 100K data set. 

Also, you need to install the "color normalization toolbox" from this link: https://warwick.ac.uk/fac/sci/dcs/research/tia/software/sntoolbox/ 
You should install it in the sub-folder "subroutines_normalization"

## Where can I get your pre-trained VGG model?
The model is available here: http://doi.org/10.5281/zenodo.1420524 
