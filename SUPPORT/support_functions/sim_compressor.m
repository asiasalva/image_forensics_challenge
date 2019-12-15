function dct = sim_compressor(im,Q)        
    
    % Simulated compressor: pixels --> quantized DCT
        
    % Compute 8x8 DCT    
    im = double(im);
    dct = bdct(im-128);
    S = size(im);
    
    % Quantize according to the quantization table Q
    H = S(1)/8; W = S(2)/8; % we assume image size is multiple of 8
    QQ = repmat(Q,[H W]);
    dct = floor(dct./QQ +.5);
    
end