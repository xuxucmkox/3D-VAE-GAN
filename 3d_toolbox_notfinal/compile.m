globals_toolbox;

current_dir = pwd;

cd([TOOLBOX_DIR 'utils/private']);
a=dir('*.cpp');
for i = 1:length(a)
    mex(a(i).name);
end

cd([TOOLBOX_DIR 'utils/online_renderer']);
compile_renderer;

cd([TOOLBOX_DIR 'lib/']);
addpath(genpath(pwd));
toolboxCompile;

cd(current_dir);
