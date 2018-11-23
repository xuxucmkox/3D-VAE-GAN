function init_toolbox_setup()

globals_toolbox;

% toolbox
addpath(TOOLBOX_DIR);
addpath([TOOLBOX_DIR 'IKEA_labeler']);
addpath([TOOLBOX_DIR 'lib/EPnP']);
addpath([TOOLBOX_DIR 'eval']);
addpath(genpath([TOOLBOX_DIR 'utils']));

% Piotr's toolbox
addpath(genpath([TOOLBOX_DIR 'lib/Piotr_toolbox/']));
