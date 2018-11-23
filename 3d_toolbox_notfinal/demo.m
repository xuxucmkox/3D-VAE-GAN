%% (0) Initialize all setup
init_toolbox_setup;

%% (1) Load IKEA room annotations and models
pos = collect_data_force_eq_foc_rescale('ikearoom', 0);
models = extract_all_models(pos);

%% (2) Check if the object files are downloaded
globals_toolbox;
if ~exist([OBJ3D_DIR models(3).type '/' models(3).obj '.obj'],'file')
    error('Please download our dataset linked from README.md');
end

%% (3) render model with some specific view parameter
param.angle = 45;
param.phi = pi/8;
param.theta = pi/10;
param.d = 3;
param.x = 1/3;
param.y = 1/3;
param.h = 500;
param.w = 500;
[obj_data, v2d,I_mat,E_mat, im, edgemap, pxmap, res] = render_model_rescale(models(3), param,[], 2);

figure(1);
imagesc(edgemap);
figure(2);
imagesc(res);


%% (4) render groundtruth pose
[im,edgemap,im_overlay] = render_pos_gt(pos(5), 1);

figure(3);
imagesc(im);
figure(4);
imagesc(edgemap);
figure(5);
imagesc(im_overlay);