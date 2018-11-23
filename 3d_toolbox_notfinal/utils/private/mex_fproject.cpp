#include <mex.h>
#include <cmath>

void convert_param(double *param, double *out_pt)
{
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
}
       

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    double *param = (double *)mxGetData(prhs[0]);
    double *p3d = (double *)mxGetData(prhs[1]);
    double *p2d = (double *)mxGetData(prhs[2]);
    double *l3d = (double *)mxGetData(prhs[3]);
    double *l2d_s = (double *)mxGetData(prhs[4]);
    double *A = (double *)mxGetData(prhs[5]);

    const int M_p2d = mxGetM(prhs[2]);
    const int N_l2d_s = mxGetN(prhs[4]);
    
    int out_size[2];
    out_size[0] = M_p2d+N_l2d_s;
    out_size[1] = 1;
    mxArray *mxout = mxCreateNumericArray(2, out_size, mxDOUBLE_CLASS, mxREAL);
    double* out_pt = (double*)mxGetPr(mxout);
    
    double *E = (double *)mxCalloc(3*4, sizeof(double));
    convert_param(param, E);
    
    const double I[12] = 
    {
        A[0]*E[0]+A[3]*E[1]+A[6]*E[2], A[1]*E[0]+A[4]*E[1]+A[7]*E[2], A[2]*E[0]+A[5]*E[1]+A[8]*E[2],
        A[0]*E[3]+A[3]*E[4]+A[6]*E[5], A[1]*E[3]+A[4]*E[4]+A[7]*E[5],A[2]*E[3]+A[5]*E[4]+A[8]*E[5],
        A[0]*E[6]+A[3]*E[7]+A[6]*E[8], A[1]*E[6]+A[4]*E[7]+A[7]*E[8],A[2]*E[6]+A[5]*E[7]+A[8]*E[8],
        A[0]*E[9]+A[3]*E[10]+A[6]*E[11], A[1]*E[9]+A[4]*E[10]+A[7]*E[11], A[2]*E[9]+A[5]*E[10]+A[8]*E[11],           
    };
    
    for (int i = 0; i < M_p2d; i+=2) {
        double t[3];
        for (int k = 0; k < 3; k++) {
            t[k] = 0;
            for (int j = 0; j < 4; j++) {
                t[k] += (*(I+k+3*j)) * (*(p3d+j));
            }
        }
        *(out_pt++) = *(p2d++) - t[0]/t[2];
        *(out_pt++) = *(p2d++) - t[1]/t[2];
        
        p3d += 4;
    }
    
    for (int i = 0; i < N_l2d_s; i++) {
        double t[3];
        for (int k = 0; k < 3; k++) {
            t[k] = 0;
            for (int j = 0; j < 4; j++) {
                t[k] += (*(I+k+3*j)) * (*(l3d+j));
            }
        }
        *(out_pt++) = l2d_s[0] * t[0]/t[2] + l2d_s[1] * t[1]/t[2] - l2d_s[2];
        
        l3d += 4;
        l2d_s += 3;
    }
    
    plhs[0] = mxout;
}
