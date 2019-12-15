function outdata= RGB2YCbCr(data)

T= [ 0.2990  0.5870  0.1140
    -0.1687 -0.3313  0.5000 
     0.5000 -0.4187 -0.0813 ];

% obtain relevant size information
[rows,cols,colors]= size(data);
numpix= rows*cols;

% reshape data for colorspace transformation
rgb= double(reshape(data, [numpix 3]));

% transform data from RGB to YCbCr colorspace
ycbcr= T*(rgb.') + [0;128;128]*ones(1,numpix);

% reshape YCbCr data to original size
outdata= reshape(ycbcr.',rows,cols,colors);