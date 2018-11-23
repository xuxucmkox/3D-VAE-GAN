function out = bit2logical(in, sz, mex_mode)
    if (mex_mode)
        out = mex_bit2logical(in, sz);
    else
        out=[bitand(in, 1); bitand(in, 2); bitand(in, 4); bitand(in, 8); bitand(in, 16); bitand(in, 32); bitand(in, 64); bitand(in, 128)] > 0;
        out=reshape(out(1:(sz(1)*sz(2))), sz(1:2)); 
    end
end