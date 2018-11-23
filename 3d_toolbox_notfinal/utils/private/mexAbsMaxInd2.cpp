#include <mex.h>
#include <cmath>

float float_abs(float a)
{
    if (a >= 0)
        return a;
    else
        return -a;
}

float absmax(float a, float b)
{
    if (float_abs(a) > float_abs(b))
    {
        return a;
    }
    else
    {
        return b;
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs != 2)
    {
        mexErrMsgTxt("Wrong number of inputs");
    }
    
    if (nlhs != 3)
    {
        mexErrMsgTxt("Wrong number of outputs");
    }
    
    
    float *dx = (float *)mxGetData(prhs[0]);
    float *dy = (float *)mxGetData(prhs[1]);
    const int *dims = mxGetDimensions(prhs[0]);
    const int m = dims[0], n = dims[1], d = dims[2];    
    
    int out_size[2];
    out_size[0] = m;
    out_size[1] = n;
    mxArray *mxout1 = mxCreateNumericArray(2, out_size, mxSINGLE_CLASS, mxREAL);
    float *out_pt_x = (float *)mxGetPr(mxout1);
    mxArray *mxout2 = mxCreateNumericArray(2, out_size, mxSINGLE_CLASS, mxREAL);
    float *out_pt_y = (float *)mxGetPr(mxout2);
    mxArray *mxout3 = mxCreateNumericArray(2, out_size, mxSINGLE_CLASS, mxREAL);
    float *out_mg = (float *)mxGetPr(mxout3);
    
    const int STEP = m*n;
    
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            *out_pt_x = *dx;
            *out_pt_y = *dy;
            for (int k = 1; k < d; k++) {
                *out_pt_x = absmax(*out_pt_x, *(dx+k*STEP));
                *out_pt_y = absmax(*out_pt_y, *(dy+k*STEP));                
            }
            *(out_mg++) = sqrt(*out_pt_x*(*out_pt_x) + *out_pt_y*(*out_pt_y));
            out_pt_x++;
            out_pt_y++;
            dx++;
            dy++;
        }
    }
    
    plhs[0] = mxout1;
    plhs[1] = mxout2;
    plhs[2] = mxout3;
}
