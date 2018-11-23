#include <mex.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs != 2)
    {
        mexErrMsgTxt("Wrong number of inputs");
    }
    
    if (nlhs != 1)
    {
        mexErrMsgTxt("Wrong number of outputs");
    }
    
    unsigned char *in = (unsigned char *)mxGetData(prhs[0]);
    double *sz = (double *)mxGetData(prhs[1]);
    
    const int N = mxGetM(prhs[0]);
    
    const int n = (int)sz[0];
    const int m = (int)sz[1];

    mxArray *mxout = mxCreateLogicalMatrix(n, m);
    char *pt_out = (char *)mxGetPr(mxout);
   
    unsigned char op = 1;
    int cou = 0;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            *(pt_out++) = ((*in) & op)>0;
            op = op << 1;
            cou ++;
            if (cou == 8)
            {
                cou = 0;
                op = 1;
                in++;
            }
        }
    }
    
    
    plhs[0] = mxout;
}
