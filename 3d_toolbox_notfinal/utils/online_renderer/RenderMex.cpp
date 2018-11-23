/*
 * Highly modified version by Joseph J. Lim
 * TODO: more comments to follow...
 *
 * This code is to render a Mesh given a 3x4 camera matrix with an image resolution widthxheight. The rendering result is an ID map for facets, edges and vertices. This can usually used for occlusion testing in texture mapping a model from an image, such as the texture mapping in the following two papers.
 *
 * --Jianxiong Xiao http://mit.edu/jxiao/
 *
 * Citation:
 *
 * [1] J. Xiao, T. Fang, P. Zhao, M. Lhuillier, and L. Quan
 * Image-based Street-side City Modeling
 * ACM Transaction on Graphics (TOG), Volume 28, Number 5
 * Proceedings of ACM SIGGRAPH Asia 2009
 *
 * [2] J. Xiao, T. Fang, P. Tan, P. Zhao, E. Ofek, and L. Quan
 * Image-based Facade Modeling
 * ACM Transaction on Graphics (TOG), Volume 27, Number 5
 * Proceedings of ACM SIGGRAPH Asia 2008
 *
 */

#include "mex.h"
#include <GL/osmesa.h>
#include <GL/glu.h>

void uint2uchar(unsigned int in, unsigned char* out){
    out[0] = (in & 0x00ff0000) >> 16;
    out[1] = (in & 0x0000ff00) >> 8;
    out[2] =  in & 0x000000ff;
}

unsigned int uchar2uint(unsigned char* in){
    unsigned int out = (((unsigned int)(in[0])) << 16) + (((unsigned int)(in[1])) << 8) + ((unsigned int)(in[2]));
    return out;
}

// Input:
//     arg0: 3x4 Projection matrix,
//     arg1: image width,
//     arg2: image height,
//     arg3: 3xn double vertices matrix,
//     arg4: 2xn uint32 edge matrix, index from zero
//     arg5: 4xn uint32 face matrix, index from zero
// Output: you will need to transpose the result in Matlab manually
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
//   mexPrintf("RenderMex\n");
    
    float m_near = .01;
    float m_far = 10000;
    int m_level = 0;
    
    int m_linewidth = 1;
    int m_pointsize = 1;
    
    double* projection = mxGetPr(prhs[0]); // 3x4 matrix
    int m_width = (int)mxGetScalar(prhs[1]);
    int m_height = (int)mxGetScalar(prhs[2]);
    double*       vertex = mxGetPr(prhs[3]); // 3xn double vertices matrix
    unsigned int  num_vertex = mxGetN(prhs[3]);
    unsigned int* edge = (unsigned int*) mxGetData(prhs[4]); // 2xn uint32 edge matrix
    unsigned int  num_edge = mxGetN(prhs[4]);
    unsigned int* face = (unsigned int*) mxGetData(prhs[5]); // 4xn uint32 face matrix
    unsigned int  num_face = mxGetN(prhs[5]);
    double* face_c = mxGetPr(prhs[6]);
    
    plhs[0] = mxCreateNumericMatrix(3, m_width*m_height, mxUINT8_CLASS, mxREAL);
    unsigned char* pbuffer = (unsigned char*) mxGetData(plhs[0]);
    
    // Step 1: setup off-screen mesa's binding
    OSMesaContext ctx;
    ctx = OSMesaCreateContextExt(OSMESA_RGB, 32, 0, 0, NULL );
    //unsigned char * pbuffer = new unsigned char [3 * m_width * m_height];
    // Bind the buffer to the context and make it current
    if (!OSMesaMakeCurrent(ctx, (void*)pbuffer, GL_UNSIGNED_BYTE, m_width, m_height)) {
        mexErrMsgTxt("OSMesaMakeCurrent failed!: ");
    }
    OSMesaPixelStore(OSMESA_Y_UP, 0);
    
    // Step 2: Setup basic OpenGL setting
    glEnable(GL_DEPTH_TEST);
    glShadeModel(GL_SMOOTH);
    //glEnable(GL_LIGHTING);
    glDisable(GL_LIGHTING);
    glEnable(GL_CULL_FACE);
    //glCullFace(GL_BACK);
    glPolygonMode(GL_FRONT, GL_FILL);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //glClearColor(m_clearColor[0], m_clearColor[1], m_clearColor[2], 1.0f); // this line seems useless
    
    glViewport(0, 0, m_width, m_height);
    //glViewport(-m_width/2,-m_height/2, m_width/2, m_height/2);
    
    // Step 3: Set projection matrices
    double scale = (0x0001) << m_level;
    double final_matrix[16];
    
#ifdef FINAL
    // new way: faster way by reuse computation and symbolic derive. See sym_derive.m to check the math.
    double inv_width_scale  = 1.0/(m_width*scale);
    double inv_height_scale = 1.0/(m_height*scale);
    //   double inv_width_scale_1 =inv_width_scale - 1.0;
    //   double inv_height_scale_1_s = -(inv_height_scale - 1.0);
    //   double inv_width_scale_2 = inv_width_scale*2.0;
    //   double inv_height_scale_2_s = -inv_height_scale*2.0;
    double inv_width_scale_1 =inv_width_scale - 1.0;
    double inv_height_scale_1_s = -(inv_height_scale - 1.0);
    double inv_width_scale_2 = inv_width_scale*2.0;
    double inv_height_scale_2_s = -inv_height_scale*2.0;
    double m_far_a_m_near = m_far + m_near;
    double m_far_s_m_near = m_far - m_near;
    double m_far_d_m_near = m_far_a_m_near/m_far_s_m_near;
    final_matrix[ 0]= projection[2+0*3]*inv_width_scale_1 + projection[0+0*3]*inv_width_scale_2;
    final_matrix[ 1]= projection[2+0*3]*inv_height_scale_1_s + projection[1+0*3]*inv_height_scale_2_s;
    final_matrix[ 2]= projection[2+0*3]*m_far_d_m_near;
    final_matrix[ 3]= projection[2+0*3];
    final_matrix[ 4]= projection[2+1*3]*inv_width_scale_1 + projection[0+1*3]*inv_width_scale_2;
    final_matrix[ 5]= projection[2+1*3]*inv_height_scale_1_s + projection[1+1*3]*inv_height_scale_2_s;
    final_matrix[ 6]= projection[2+1*3]*m_far_d_m_near;
    final_matrix[ 7]= projection[2+1*3];
    final_matrix[ 8]= projection[2+2*3]*inv_width_scale_1 + projection[0+2*3]*inv_width_scale_2;
    final_matrix[ 9]= projection[2+2*3]*inv_height_scale_1_s + projection[1+2*3]*inv_height_scale_2_s;
    final_matrix[10]= projection[2+2*3]*m_far_d_m_near;
    final_matrix[11]= projection[2+2*3];
    final_matrix[12]= projection[2+3*3]*inv_width_scale_1 + projection[0+3*3]*inv_width_scale_2;
    final_matrix[13]= projection[2+3*3]*inv_height_scale_1_s + projection[1+3*3]*inv_height_scale_2_s;
    final_matrix[14]= projection[2+3*3]*m_far_d_m_near - (2*m_far*m_near)/m_far_s_m_near;
    final_matrix[15]= projection[2+3*3];
#endif

    // matrix is ready. use it
    glMatrixMode(GL_PROJECTION);
    glLoadMatrixd(projection);
    //glLoadMatrixd(final_matrix);
    //glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();


    // Step 3: render the mesh with encoded color from their ID
    unsigned char colorBytes[3];
    unsigned int base_offset;

//         GLfloat lp[] = {50, 50, 15, 1};
//         glEnable(GL_LIGHT0);
//         glLightfv(GL_LIGHT0, GL_POSITION, lp);
//         GLfloat mat_diffuse[] = { 0.1, 0.5, .8, 1.0 };
//         GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
//         GLfloat mat_shininess[] = { 5.0 };
//         glShadeModel (GL_SMOOTH);
//         glMaterialfv(GL_FRONT, GL_AMBIENT, mat_diffuse);
//         glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
//         glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);


    // render face
//       base_offset = 1;
//       for (unsigned int i = 0; i < num_face; ++i) {
//         uint2uchar(base_offset+i,colorBytes);
//         glColor3f(0,0,3);
//         //glColor3ubv(colorBytes);
//         //glBegin(GL_POLYGON);
//         glBegin(GL_TRIANGLES);
//         glVertex3dv(vertex+3*(*face++));
//         glVertex3dv(vertex+3*(*face++));
//         glVertex3dv(vertex+3*(*face++));
//         //glVertex3dv(vertex+3*(*face++));
//         glEnd();
//       }


    if (0) {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glPolygonMode(GL_BACK, GL_LINE);
        glLineWidth(3);
        glCullFace(GL_FRONT);
        glDepthFunc(GL_LEQUAL);
        //glEnable(GL_LINE_SMOOTH);

        glBegin(GL_TRIANGLES);
        face = (unsigned int*) mxGetData(prhs[5]); // 4xn uint32 face matrix
        // render face
        base_offset = 1;
        for (unsigned int i = 0; i < num_face; ++i) {
            //uint2uchar(base_offset+i,colorBytes);
            //glColor3ubv(colorBytes);
            //glBegin(GL_POLYGON);
            glColor3dv(face_c+i*3);

            glVertex3dv(vertex+3*(*face++));
            glVertex3dv(vertex+3*(*face++));
            glVertex3dv(vertex+3*(*face++));
            //glVertex3dv(vertex+3*(*face++));
        }
        glEnd();
    }

    if (1) {
        glDisable(GL_BLEND);
        glDepthFunc(GL_LEQUAL);
        glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);
        glDisable(GL_CULL_FACE);
        glLineWidth(0);

        //num_face = 0;
        base_offset = 1;
        face = (unsigned int*) mxGetData(prhs[5]); // 4xn uint32 face matrix
        
        glBegin(GL_TRIANGLES);
        //glColor3f(0,0,3);
        for (unsigned int i = 0; i < num_face; ++i) {
            //uint2uchar(base_offset+i,colorBytes);            
            //glColor3ubv(colorBytes);
            //glBegin(GL_POLYGON);
            //glColor3f();
            glColor3dv(face_c+i*3);
            
            glVertex3dv(vertex+3*(*face++));
            glVertex3dv(vertex+3*(*face++));
            glVertex3dv(vertex+3*(*face++));
            //glVertex3dv(vertex+3*(*face++));
        }
        glEnd();
    }



    //    glEnable(GL_COLOR_MATERIAL);
    //    glColorMaterial(GL_FRONT, GL_DIFFUSE);



    /*
     * // render edge
     * base_offset = 1+num_face;
     * glLineWidth(m_linewidth);
     *
     * glBegin(GL_LINES);
     * for (unsigned int i = 0; i < num_edge; ++i) {
     * uint2uchar(base_offset+i,colorBytes);
     * glColor3ubv(colorBytes);
     * glVertex3dv(vertex+3*(*edge++));
     * glVertex3dv(vertex+3*(*edge++));
     * }
     * glEnd();
     **/


    if (0) {
        // render vertex
        base_offset = 1+num_face+num_edge;
        glPointSize(m_pointsize);
        glBegin(GL_POINTS);
        for (unsigned int i = 0; i < num_vertex; ++i) {
            uint2uchar(base_offset+i,colorBytes);
            glColor3ubv(colorBytes);
            glVertex3dv(vertex);
            vertex+=3;
        }
        glEnd();
    }

    glFinish(); // done rendering
    
    // Step 5: convert the result from color to interger array
    plhs[1] = mxCreateNumericMatrix(m_width, m_height, mxSINGLE_CLASS, mxREAL);
    float* result = (float*) mxGetData(plhs[1]);
    glReadPixels(0,0,m_width, m_height, GL_DEPTH_COMPONENT, GL_FLOAT, result);
    
    //plhs[0] = mxCreateNumericMatrix(m_width, m_height, mxUINT32_CLASS, mxREAL);
//     plhs[0] = mxCreateNumericMatrix(3, m_width*m_height, mxUINT32_CLASS, mxREAL);
//     unsigned int* result = (unsigned int*) mxGetData(plhs[0]);
//     unsigned int* resultCur = result;
//     unsigned int* resultEnd = result + m_width * m_height * 3;
//     unsigned char * pbufferCur = pbuffer;
//     while(resultCur != resultEnd){
//         *resultCur = *(pbufferCur++);
//                 
// //         *resultCur = uchar2uint(pbufferCur);
// //         pbufferCur += 3;
//         ++resultCur;
//     }

    OSMesaDestroyContext(ctx);
    //delete [] pbuffer;

}
