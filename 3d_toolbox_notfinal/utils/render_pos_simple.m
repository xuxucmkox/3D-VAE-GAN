function [edgemap, pxmap, res, depth] = render_pos_simple(pos, obj_data, im_w, im_h)
% RENDER_POS render an image using a model and its configuration
    globals_toolbox;
    
    obj_name=[OBJ3D_DIR pos.type '/' pos.obj '.obj'];

    if (nargin > 1) && ~isempty(obj_data)
        v = obj_data.v;
        f = obj_data.f;
        vn = obj_data.vn;
        fn = obj_data.fn;
    else
        [v,f,vn,fn] = readObj(obj_name);
        obj_data.v = v;
        obj_data.f = f;
        obj_data.vn = vn;
        obj_data.fn = fn;
    end
    vn=(vn+1)/2;
    pos.scale = 0.01;
    v=v*pos.scale;
    fi = uint32(f)-1;

    vnn = vn(fn(:,1),:)';
    v2 = v';
    mesh_point=reshape(v(f',:)', 3,3,size(f,1));
    vnn=squeeze(cross(mesh_point(:,2,:)-mesh_point(:,1,:),mesh_point(:,3,:)-mesh_point(:,1,:)));
    vnn=bsxfun(@rdivide,vnn,sqrt(sum(vnn.^2,1)));
    if isfield(pos,'Rp')
        vnn = pos.Rp*vnn;
        vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
        vnn(:,(vnn(1,:)==0)&(vnn(2,:)<0)) = -vnn(:,(vnn(1,:)==0)&(vnn(2,:)<0));
        vnn(:,(vnn(1,:)==0)&(vnn(2,:)==0)&(vnn(3,:)<0)) = -vnn(:,(vnn(1,:)==0)&(vnn(2,:)==0)&(vnn(3,:)<0));
        %elseif isfield(pos,'E3')
        %vnn = pos.E3(1:3,1:3)*vnn;
    else
        vnn(:,vnn(1,:)<0) = -vnn(:,vnn(1,:)<0);
    end
    vnn=(vnn+1)/2;
    
    fil = fliplr(fi)';
    vf = v';
    
    im_h = im_h * 500 / im_w;
    im_w = 500;

    
    [res,res2] = RenderMex(pos.F3*pos.E3,im_h, im_w, vf, uint32([]), fil, vnn); 
    depth = res2;
    %assert(isequal(max(res(:))==0, ~any(res(:))));
    %if max(res(:)) == 0
    if ~any(res(:))
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
    res = double(permute(reshape(res,[3 im_h im_w]), [2 3 1]))/255;
    %edgemap = edge_color(cat(3,res, fliplr(res2)), 'canny', .05);
    edgemap = edge_color3(cat(3,res, fliplr(res2)), .05);
    %edgemap = edge(fliplr(res2), 'canny', .05);
    edgemap = bwmorph(edgemap, 'thin', inf);
    %pxmap = sum(res,3) > 0;    
    pxmap = any(res, 3);
end