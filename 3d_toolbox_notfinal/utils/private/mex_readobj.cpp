#include <mex.h>

#include <vector>
#include <sstream>
#include <istream>
#include <fstream>
#include <string>

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {    
    int n = mxGetN(prhs[0])+1;
    char *p = (char*)mxCalloc(n, sizeof(char));
    mxGetString(prhs[0],p,n);
    
    string line;
    ifstream myfile(p);
    
    int v_cou=0, vn_cou=0, f_cou=0;
    if (myfile.is_open()) {
        while (getline(myfile, line)) {
            if (line.compare(0, 2, "v ")==0) {
                v_cou++;
            }
            else if (line.compare(0, 3, "vn ")==0) {
                vn_cou++;
            }
            else if (line.compare(0, 2, "f ") == 0) {
                f_cou++;
            }
        }        
    }
    myfile.close();
        
    
    int out_size[2];
    out_size[0] = v_cou;
    out_size[1] = 3;    
    mxArray *mxout1 = mxCreateNumericArray(2, out_size, mxDOUBLE_CLASS, mxREAL);
    double* vertex = (double*)mxGetPr(mxout1);
    
    out_size[0] = vn_cou;
    mxArray *mxout2 = mxCreateNumericArray(2, out_size, mxDOUBLE_CLASS, mxREAL);    
    double* normal = (double*)mxGetPr(mxout2);
    
    out_size[0] = f_cou;
    mxArray *mxout3 = mxCreateNumericArray(2, out_size, mxDOUBLE_CLASS, mxREAL);    
    double* face = (double*)mxGetPr(mxout3);
    mxArray *mxout4 = mxCreateNumericArray(2, out_size, mxDOUBLE_CLASS, mxREAL);    
    double* face_normal = (double*)mxGetPr(mxout4);
    
    double x, y, z;    
    myfile.open(p);
    if (myfile.is_open()) {
        while (getline(myfile, line)) {
           if (line.compare(0, 2, "v ")==0) {
                sscanf(line.c_str(), "v %lf %lf %lf", &x, &y, &z);
                vertex[0] = x;
                vertex[v_cou] = y;
                vertex[v_cou*2] = z;
                vertex++;
            }
            else if (line.compare(0, 3, "vn ")==0) {
                sscanf(line.c_str(), "vn %lf %lf %lf", &x, &y, &z);
                normal[0] = x;
                normal[vn_cou] = y;
                normal[vn_cou*2] = z;
                normal++;
            }
            else if (line.compare(0, 2, "f ") == 0) {
               stringstream ss(line.substr(2));
               string item;
               vector<double> tmp3;
               vector<double> tmp5;
               while (getline(ss, item, ' ')) {
                   if (item.length() <= 2) {
                       break;
                   }
                   sscanf(item.c_str(), "%lf/%lf/%lf", &x, &y, &z);
                   tmp3.push_back(x);
                   tmp5.push_back(z);
               }
               
               for (int i = 1; i < tmp3.size()-1; i++) {
                   face[0] = tmp3[0];
                   face[f_cou] = tmp3[i];
                   face[f_cou*2] = tmp3[i+1];
                   face++;
                   
                   face_normal[0] = tmp5[0];
                   face_normal[f_cou] = tmp5[i];
                   face_normal[f_cou*2] = tmp5[i+1];
                   face_normal++;
               }
            }
        }
    }
    myfile.close();    
    
    mxFree(p);   

    
    plhs[0] = mxout1;
    plhs[1] = mxout3;
    plhs[2] = mxout2;
    plhs[3] = mxout4;
}
