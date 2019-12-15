function im = sim_decompressor(dct,Q)
     
    % Simulated decompressor: quantized DCT --> pixels

    S = size(dct);
        
    % Dequantize according to the quantization table
    H = S(1)/8; W = S(2)/8; % we assume image size is multiple of 8
    QQ = repmat(Q,[H W]);
    dct = dct .* QQ;
    
    % Compute inverse 8x8 DCT
    im = ibdct(dct);
    
    im = uint8(im + 128);
    
end