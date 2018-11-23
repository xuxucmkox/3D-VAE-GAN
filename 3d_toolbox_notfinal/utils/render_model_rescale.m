function [obj_data, v2d,I_mat,E_mat, im, edgemap, pxmap, res, res3] = render_model_rescale(model, param,obj_data, mode)
% RENDER_POS render an image using a model and its configuration

    globals_toolbox;

    % if obj_data is provided, then there is no need to read them (readObj
    % is quite slow)
    if (nargin > 1) && ~isempty(obj_data)
        v = obj_data.v;
        f = obj_data.f;
        vn = obj_data.vn;
        fn = obj_data.fn;
    else
        [v,f,vn,fn] = readObj_rescale(OBJ3D_DIR, model.type, model.obj);
        obj_data.v = v;
        obj_data.f = f;
        obj_data.vn = vn;
        obj_data.fn = fn;
    end

    if isempty(param)
        return ;
    end
    
    %model.scale = 0.01;
    %v=v*model.scale;
    v = v * 0.01;
    fi = uint32(f)-1;
    
    % Compute face normals
    mesh_point=reshape(v(f',:)', 3,3,size(f,1));
    vnn=squeeze(cross(mesh_point(:,2,:)-mesh_point(:,1,:),mesh_point(:,3,:)-mesh_point(:,1,:)));
    vnn=bsxfun(@rdivide,vnn,sqrt(sum(vnn.^2,1)));
    if isfield(model,'Rp')
        vnn = model.Rp*vnn;
        vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
        vnn(:,(vnn(1,:)==0)&(vnn(2,:)<0)) = -vnn(:,(vnn(1,:)==0)&(vnn(2,:)<0));
        vnn(:,(vnn(1,:)==0)&(vnn(2,:)==0)&(vnn(3,:)<0)) = -vnn(:,(vnn(1,:)==0)&(vnn(2,:)==0)&(vnn(3,:)<0));
    else
        vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
    end
    vnn=(vnn+1)/2;
    fil = fliplr(fi)';
    vf = v';

    [v2d, I_mat, E_mat] = project3d_2d_update3(v, param);
    %I_mat = double(I_mat);
    E_mat = double(E_mat);
    
    if mode <= 1
        return;
    end

    %param = model.param;
    im = zeros(param.h,param.w, 3);
    
    near = 0.01;
    far = 1000;
    F=[cot(param.angle/2/180*pi), 0 0 0; 0, cot(param.angle/2/180*pi)*size(im,2)/size(im,1), 0 0; 0 0 -(far+near)/(far-near) -2*far*near/(far-near); 0 0 -1 0];
    F2 = F;
    F2(1,:) = -F(2,:);
    F2(2,:) = -F(1,:);

    % Render using mex'ed OpenGL library
    % F3 is intrinsic and E3 is extrinsic
    [res,res2] = RenderMex(F2*E_mat,param.h, param.w, vf, uint32([]), fil, vnn); 

    assert(max(res(:)) ~= 0);
    
    % Normalize depth
    m1 = min(res2(res2<1));
    m2 = max(res2(res2<1));
    if m1==m2
        res2 = (res2==m1);
    else
        res2 = .5-(res2-m1)/(m2-m1);
    end
    res = double(permute(reshape(res,[3 size(im,1) size(im,2)]), [2 3 1]))/255;
    
    
    % Extract an edgemap from the rendered scene
    edgemap = edge_color3(cat(3,res, fliplr(res2)), .05);
    edgemap = bwmorph(edgemap, 'thin', inf);
    pxmap = sum(res,3) > 0;
    
    if (0)
    if ~isempty(mask)
        vnn(1,:) = 1;
        vnn(2,:) = 0;
        vnn(3,:) = 0;
        vnn(1,all(mask(fil+1),1))=0;
        vnn(2,all(mask(fil+1),1))=1;
        %vnn = vnn(:,all(mask(fil+1),1));
        %fil = fil(:,all(mask(fil+1),1));
        res3 = RenderMex(F2*E_mat, 500, 500, vf, uint32([]), fil, vnn);

        res3 = double(permute(reshape(res3,[3 size(im,1) size(im,2)]), [2 3 1]))/255;        
        pxmap(:,:,2) = res3(:,:,2)==1;
    end
    end
    
    % Draw an edgemap on top of the given image
    %imt = double(im)/255; imt(repmat(edgemap,[1 1 3])) = 0; imt(:,:,3) = imt(:,:,3) + double(edgemap);
    
    if mode >= 3
        res3 = RenderMex_prim(F2*E_mat,param.h, param.w, vf, uint32([]), fil, vnn); 
    end
end