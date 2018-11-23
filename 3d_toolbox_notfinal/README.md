3D MODEL TOOLBOX      V0.95 
==============================

This software package provides tools to handle various 3D computer vision related MATLAB operations. It provides you a code for MATLAB 3D rendering based on OpenGL mex code.


Installation
------------
<ol>
<li>
Extract and install OSMesa (http://www.mesa3d.org/)
</li>

<li>
Edit TOOLBOX_DIR/globals_toolbox.m and TOOLBOX_DIR/utils/online_renderer/compile_renderer.m
</li>

<li>
Run TOOLBOX_DIR/compile.m under TOOLBOX_DIR
</li>
</ol>

Demo
----
There is a demo script provided in this toolbox to render an object for you.

    >> demo



Bundled code
------------
There are functions or snippets of code included with or without modification from the following packages:
 - <a href="http://cvlab.epfl.ch/software/EPnP">EPnP: Efficient Perspective-n-Point Camera Pose Estimation</a>
 - <a href="http://vision.ucsd.edu/~pdollar/toolbox/doc/">Piotr's Image & Video Matlab Toolbox</a>

References
----------
Please cite the following paper if you end up using the code:<br>
[1] "Parsing IKEA Objects: Fine Pose Estimation." Joseph J. Lim, Hamed Pirsiavash, Antonio Torralba. ICCV 2013.

License
-------
Copyright 2014 Joseph Lim [lim@csail.mit.edu]

Please email me if you find bugs, or have suggestions or questions!

Licensed under the Simplified BSD License [see bsd.txt] <br>
