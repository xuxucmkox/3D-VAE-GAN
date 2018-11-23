#include <mex.h>
#include <cmath>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
//     if (nrhs != 1)
//     {
//         mexErrMsgTxt("Wrong number of inputs");
//     }
//     
//     if (nlhs != 1)
//     {
//         mexErrMsgTxt("Wrong number of outputs");
//     }    
    double *param = (double *)mxGetData(prhs[0]);

    int out_size[2];
    out_size[0] = 3;
    out_size[1] = 4;
    mxArray *mxout = mxCreateNumericArray(2, out_size, mxDOUBLE_CLASS, mxREAL);    
    double *out_pt = (double *)mxGetPr(mxout);
    
    double wx = *(param++);
    double wy = *(param++);
    double wz = *(param++);
    
    const double theta = sqrt(wx*wx + wy*wy + wz*wz);
    if (theta != 0)
    {
        wx /= theta; wy /= theta; wz /= theta;
    }
    
    const double ct = cos(theta);
    const double st = sin(theta);
    
    *(out_pt++) = ct + wx*wx*(1-ct);
    *(out_pt++) = wz*st + wx*wy*(1-ct);
    *(out_pt++) = -wy*st + wx*wz*(1-ct);
    
    *(out_pt++) = wx*wy*(1-ct)-wz*st;
    *(out_pt++) = ct + wy*wy*(1-ct);
    *(out_pt++) = wx*st + wy*wz*(1-ct);
    
    *(out_pt++) = wy*st+wx*wz*(1-ct);
    *(out_pt++) = -wx*st+wy*wz*(1-ct);
    *(out_pt++) = ct+wz*wz*(1-ct);
    
    *(out_pt++) = *(param++);
    *(out_pt++) = *(param++);
    *(out_pt++) = *(param++);
        
    plhs[0] = mxout;
}
