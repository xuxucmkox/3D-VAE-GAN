function [out, sz] = logical2bit(in)
    [m,n] = size(in);
    in(ceil(m*n/8)*8) = 0;
    in=reshape(in, 8, []);
    out = uint8(2.^(0:7)*in);    
    sz = [m, n];
end