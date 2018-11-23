% Edit -I and -L libraries to point where OSMesa is installed
% If you are a Mac user, I found using MacPort install is easiset.
% If you are a linux user, please download and install ftp://ftp.freedesktop.org/pub/mesa/older-versions/8.x/8.0.4/MesaLib-8.0.4.tar.gz

mex RenderMex.cpp -lGLU -lOSMesa -I/opt/local/include -L/opt/local/lib
mex RenderMex_prim.cpp -lGLU -lOSMesa -I/opt/local/include -L/opt/local/lib
mex RenderMex_texturemap.cpp -lGLU -lOSMesa -I/opt/local/include -L/opt/local/lib
