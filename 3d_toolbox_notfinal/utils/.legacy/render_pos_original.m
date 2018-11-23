function [im, edgemap, pxmap, imt, obj_data, res] = render_pos(pos, obj_data, this_ratio)
% RENDER_POS render an image using a model and its configuration

    if nargin < 3
        this_ratio = 1;
    end

    globals_toolbox;
    
    % object filename
    obj_name=[OBJ3D_DIR pos.type '/' pos.obj '.obj'];

    % if obj_data is provided, then there is no need to read them (readObj
    % is quite slow)
    if (nargin > 1) && (~isempty(obj_data))
        v = obj_data.v;
        f = obj_data.f;
        vn = obj_data.vn;
        fn = obj_data.fn;
    else
        [v,f,vn,fn] = readObj(obj_name);
        v = v/this_ratio;
        obj_data.v = v;
        obj_data.f = f;
        obj_data.vn = vn;
        obj_data.fn = fn;
    end
    
    pos.scale = 0.01;
    v=v*pos.scale;
    fi = uint32(f)-1;
    
    if (0)
        % a way to get normal from obj file.. unsed
        vn=(vn+1)/2;
        vnn = vn(fn(:,1),:)';
        v2 = v';
    end
    
    % Compute face normals
    mesh_point=reshape(v(f',:)', 3,3,size(f,1));
    vnn=squeeze(cross(mesh_point(:,2,:)-mesh_point(:,1,:),mesh_point(:,3,:)-mesh_point(:,1,:)));
    vnn=bsxfun(@rdivide,vnn,sqrt(sum(vnn.^2,1)));
    if isfield(pos,'Rp')
        vnn = pos.Rp*vnn;
        vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
        vnn(:,(vnn(1,:)==0)&(vnn(2,:)<0)) = -vnn(:,(vnn(1,:)==0)&(vnn(2,:)<0));
        vnn(:,(vnn(1,:)==0)&(vnn(2,:)==0)&(vnn(3,:)<0)) = -vnn(:,(vnn(1,:)==0)&(vnn(2,:)==0)&(vnn(3,:)<0));
    else
        vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
    end
    vnn=(vnn+1)/2;
    fil = fliplr(fi)';
    vf = v';

    % Read an image and resize to width=500
    im = imread(pos.im);
    im = imresize(im, [nan 500]);

    % Render using mex'ed OpenGL library
    % F3 is intrinsic and E3 is extrinsic
    [res,res2] = RenderMex(pos.F3*pos.E3,size(im,1), size(im,2), vf, uint32([]), fil, vnn); 
    
    % Normalize depth
    if max(res(:)) == 0
        error('this should not happen');
    else
        m1 = min(res2(res2<1));
        m2 = max(res2(res2<1));
        if m1==m2
            res2 = (res2==m1);
        else
            res2 = .5-(res2-m1)/(m2-m1);
        end
    end
    res = double(permute(reshape(res,[3 size(im,1) size(im,2)]), [2 3 1]))/255;
    
    % Extract an edgemap from rendered scene
    edgemap = edge_color3(cat(3,res, fliplr(res2)), .05);
    edgemap = bwmorph(edgemap, 'thin', inf);
    pxmap = sum(res,3) > 0;
    
    % Draw an edgemap on top of the given image
    imt = double(im)/255; imt(repmat(edgemap,[1 1 3])) = 0; imt(:,:,3) = imt(:,:,3) + double(edgemap);
end