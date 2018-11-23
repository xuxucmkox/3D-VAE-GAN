function [im,b,im2] = render_pos_gt(pos, gt_id)
    if nargin < 2
        gt_id = 1;
    end
    globals_toolbox;

    im = imread(pos.im);
    im = imresize(im, [nan 500]);

    near = 0.01;
    far = 1000;
    F=[pos.gt_info(gt_id).foc/size(im,2)*2, 0 0 0; 0, pos.gt_info(gt_id).foc/size(im,1)*2, 0 0; 0 0 -(far+near)/(far-near) -2*far*near/(far-near); 0 0 -1 0];
    F2 = F;
    F2(1,:) = -F(2,:);
    F2(2,:) = -F(1,:);

    % Render using mex'ed OpenGL
    pos.F3 = F2;
    pos.E3 = [[pos.gt_info(gt_id).Rp, pos.gt_info(gt_id).Tp/100]; 0 0 0 1];
    pos.scale = 1/100;
    pos.type = pos.gt_info(gt_id).type;
    pos.obj = pos.gt_info(gt_id).obj;
    [~,b,c,d,~,f]=render_pos_rescale(pos,[]);

%     pos.I = pos.gt_info.I;
%     pos.Rp = pos.gt_info.Rp;
%     pos.Tp = pos.gt_info.Tp;
%     sres=render_helper(pos);
%     keyboard;

%     % Render using Blender
%     E = [pos.gt_info.Rp, pos.gt_info.Tp/100; 0 0 0 1];
%     obj_file=[OBJ3D_DIR pos.gt_info.type '/' pos.gt_info.obj '.obj'];
%     render_blender(obj_file, [size(im,1) size(im,2)], inv(E), 0.01, param.angle, 'tmp.png'); %[RESULT_DIR 'blender/' pos.type '/' pos.obj '/' sprintf('%04d', pose_iter) '.png']);
%     render_im = imread('tmp.png');
    
    im = double(im)/255;
    mask = double(repmat(sum(f==0,3)<3,[ 1 1 3]));
    im2 = im .* ~mask + f .* (mask*.7) + im .* (mask*.3);
end





function sres = render_helper(pos, this_ratio)
% RENDER_POS render an image using a model and its configuration
    globals;
    
    obj_name=[OBJ3D_DIR pos.type '/' pos.obj '.obj'];

%     if nargin > 1
%         v = obj_data.v;
%         f = obj_data.f;
%         vn = obj_data.vn;
%         fn = obj_data.fn;
%     else
        [v,f,vn,fn] = readObj(obj_name);
        v = v / this_ratio;
        obj_data.v = v;
        obj_data.f = f;
        obj_data.vn = vn;
        obj_data.fn = fn;
%     end
    vn=(vn+1)/2;
    v=v*pos.scale;
    fi = uint32(f)-1;
vnn = vn(fn(:,1),:)';
v2 = v';
mesh_point=reshape(v(f',:)', 3,3,size(f,1));
vnn=squeeze(cross(mesh_point(:,2,:)-mesh_point(:,1,:),mesh_point(:,3,:)-mesh_point(:,1,:)));
vnn=bsxfun(@rdivide,vnn,sqrt(sum(vnn.^2,1)));
vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
vnn=(vnn+1)/2;
    fil = fliplr(fi)';
    vf = v';

    im = imread(pos.im);
    im = imresize(im, [nan 500]);
    
    [~,v2d] =render_im(pos);
    uv_map = [];
    for k = 1:size(f, 1)
        uv_map(k,:) = [v2d(f(k,3), 1:2), v2d(f(k,2), 1:2), v2d(f(k,1), 1:2)];
    end
    uv_map = uv_map';
    uv_map([1,3,5],:) = uv_map([1,3,5],:) / size(im,2);
    uv_map([2,4,6],:) = uv_map([2,4,6],:) / size(im,1);
    %uv_map = uv_map([2 1 4 3 6 5],:);
    im2 = imresize(im, [512 512]); im2 = im2(:,:,3:-1:1);
    res = RenderMex_texturemap(pos.F3*pos.E3,size(im,1), size(im,2), vf, uint32([]), fil, permute(im2, [3 2 1]), uv_map); 
    res = double(permute(reshape(res,[3 size(im,1) size(im,2)]), [2 3 1]))/255;
    
    r = pos.E3(1:3,1:3);
    t = pos.E3(1:3,4);
    
    r2=[1 0 0; 0 cos(pi/10) -sin(pi/10); 0 sin(pi/10) cos(pi/10)];
    pos.E3(1:3,1:3) = r * r2;
    res = RenderMex_texturemap(pos.F3*pos.E3,size(im,1), size(im,2), vf, uint32([]), fil, permute(im2, [3 2 1]), uv_map); 
    sres{1} = double(permute(reshape(res,[3 size(im,1) size(im,2)]), [2 3 1]))/255;
    %imwrite(res,sprintf('%sgt/%s_%04d_1.png', DATA_DIR, pos.pos_prefix, pos.pos_id));
        
    r2=[1 0 0; 0 cos(pi/10) -sin(pi/10); 0 sin(pi/10) cos(pi/10)];
    pos.E3(1:3,1:3) = r * inv(r2);
    res = RenderMex_texturemap(pos.F3*pos.E3,size(im,1), size(im,2), vf, uint32([]), fil, permute(im2, [3 2 1]), uv_map); 
    sres{2} = double(permute(reshape(res,[3 size(im,1) size(im,2)]), [2 3 1]))/255;
    %imwrite(res,sprintf('%sgt/%s_%04d_2.png', DATA_DIR, pos.pos_prefix, pos.pos_id));
    
    r2=[1 0 0; 0 cos(pi/10) -sin(pi/10); 0 sin(pi/10) cos(pi/10)];
    t2 = t; t2(3) = t2(3)*1.5;
    pos.E3(1:3,:) = [r*r2, t2];
    res = RenderMex_texturemap(pos.F3*pos.E3,size(im,1), size(im,2), vf, uint32([]), fil, permute(im2, [3 2 1]), uv_map); 
    sres{3} = double(permute(reshape(res,[3 size(im,1) size(im,2)]), [2 3 1]))/255;
    %imwrite(res,sprintf('%sgt/%s_%04d_3.png', DATA_DIR, pos.pos_prefix, pos.pos_id));
end