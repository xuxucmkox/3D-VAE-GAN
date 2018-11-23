#include <mex.h>

float float_abs(float a)
{
    if (a >= 0)
        return a;
    else
        return -a;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    if (nrhs != 5)
    {
        mexErrMsgTxt("Wrong number of inputs");
    }
    
    if (nlhs != 2)
    {
        mexErrMsgTxt("Wrong number of outputs");
    }
    
    float *ix = (float *)mxGetData(prhs[0]);
    float *iy = (float *)mxGetData(prhs[1]);
    float *mag = (float *)mxGetData(prhs[2]);
    const int *dims = mxGetDimensions(prhs[0]);
    const int m = dims[0], n = dims[1];
    
    const double lowThresh = *(double*)mxGetData(prhs[3]);
    const double highThresh = *(double*)mxGetData(prhs[4]);
    
    mxArray *mxout1 = mxCreateLogicalMatrix(m, n);
    mxArray *mxout2 = mxCreateLogicalMatrix(m, n);
    
    char *out_pt1 = (char *)mxGetPr(mxout1);
    char *out_pt2 = (char *)mxGetPr(mxout2);
    
    //int debug_cou = 0;
    
    for (int j = 0; j < m; j++) {
        *(out_pt1++) = false;
        *(out_pt2++) = false;
        ix++; iy++; mag++;
    }
    for (int i = 1; i < n-1; i++) {
        *(out_pt1++) = false;
        *(out_pt2++) = false;
        ix++; iy++; mag++;
        
        for (int j = 1; j < m-1; j++) {
            const float ixv = *ix;
            const float iyv = *iy;
            const float gradmag = *mag;
            
            if (gradmag <= lowThresh)
            {
                *(out_pt1++) = false;
                *(out_pt2++) = false;
            }
            else 
            {
                int passed = false;

                const float dyx = float_abs(iyv / ixv);
                const float dxy = float_abs(ixv / iyv);

                // case 1
                if (((iyv <= 0)  && (ixv > -iyv)) || ((iyv >= 0) && (ixv < -iyv)))
                {
                    const float gradmag1 = *(mag+m)*(1-dyx) + *(mag+m-1)*dyx;
                    const float gradmag2 = *(mag-m)*(1-dyx) + *(mag-m+1)*dyx;

                    passed = (gradmag >= gradmag1) && (gradmag >= gradmag2);
                }            
                // case 2
                if (!passed && ((ixv > 0) && (-iyv >= ixv)) || ((ixv < 0) && (-iyv <= ixv)))
                {
                    const float gradmag1 = *(mag-1)*(1-dxy) + *(mag+m-1)*dxy;
                    const float gradmag2 = *(mag+1)*(1-dxy) + *(mag-m+1)*dxy;

                    passed = (gradmag >= gradmag1) && (gradmag >= gradmag2);
                }
                // case 3
                if (!passed && ((ixv <= 0) && (ixv > iyv)) || ((ixv >= 0) && (ixv < iyv)))
                {
                    const float gradmag1 = *(mag-1)*(1-dxy) + *(mag-m-1)*dxy;
                    const float gradmag2 = *(mag+1)*(1-dxy) + *(mag+m+1)*dxy;

                    passed = (gradmag >= gradmag1) && (gradmag >= gradmag2);
                }
                // case 4
                if (!passed && ((iyv < 0) && (ixv <= iyv)) || ((iyv > 0) && (ixv >= iyv)))
                {
                    const float gradmag1 = *(mag-m)*(1-dyx) + *(mag-m-1)*dyx;
                    const float gradmag2 = *(mag+m)*(1-dyx) + *(mag+m+1)*dyx;

                    passed = (gradmag >= gradmag1) && (gradmag >= gradmag2);
                }

                *(out_pt1++) = passed;                
                *(out_pt2++) = passed && (gradmag > highThresh);
            }
            
            ix++; iy++; mag++;
        }
        
        *(out_pt1++) = false;
        *(out_pt2++) = false;
        ix++; iy++; mag++;
    }
    
    
    plhs[0] = mxout1;
    plhs[1] = mxout2;
}


//tic; for k =1:100, abc=tmp(ix,iy); idx=find(abc(:,1)); idx=find(abc(:,2)); idx=find(abc(:,3));end; toc;
//tic; for k =1:100,           idx = find((iy<=0 & ix>-iy)  | (iy>=0 & ix<-iy));  idx = find((ix>0 & -iy>=ix)  | (ix<0 & -iy<=ix));   idx = find((ix<=0 & ix>iy) | (ix>=0 & ix<iy));   idx = find((iy<0 & ix<=iy) | (iy>0 & ix>=iy)); end; toc;