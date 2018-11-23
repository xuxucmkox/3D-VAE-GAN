function [out_v, out_I_mat, out_E_mat,out_camera_center] = project3d_2d_update3(pt3d, param, return_v)
    if nargin < 3
        return_v = true;
    end
    if (0)
    if isfield(param(1), 'theta')
        theta = param(1).theta;
    else
        theta = 0;
    end    
    if isfield(param(1), 'phi')
        phi = param(1).phi;
    else
        phi = 0;
    end
    end
    if isfield(param(1), 'angle')
        angle = param(1).angle;
    else
        angle = 35;
    end
    if isfield(param(1), 'w')
        w = param(1).w;
    else
        w = 800;
    end
    if isfield(param(1), 'h')
        h = param(1).h;
    else
        h = 600;
    end
    if isfield(param(1), 'max')
        max_x = param(1).max(1);
        max_y = param(1).max(2);
        max_z = param(1).max(3);
    else
        max_x = max(pt3d(:,1));
        max_y = max(pt3d(:,2));
        max_z = max(pt3d(:,3));
    end
    if isfield(param(1), 'min')
        min_x = param(1).min(1);
        min_y = param(1).min(2);
        min_z = param(1).min(3);
    else
        min_x = min(pt3d(:,1));
        min_y = min(pt3d(:,2));
        min_z = min(pt3d(:,3));
    end

    center_vec = [(max_x+min_x)/2, (max_y+min_y)/2, (max_z+min_z)/2];
    %object_size =  max([max_x - min_x, max_y - min_y, max_z - min_z]);
    relative_object1 = max_y-min_y;
    relative_object2 = max([max_x-min_x, max_z-min_z]);
    if isfield(param(1), 'd')
        dist_camera_obj1 = relative_object1*w/h / tan(param(1).angle/180*pi/2)/2;% + relative_object2;
        dist_camera_obj2 = relative_object2 / tan(param(1).angle/180*pi/2)/2; % + relative_object1;
        dist_camera_obj = max(dist_camera_obj1, dist_camera_obj2);
    end

    angle = angle/180*pi;
    I_mat = [-w/2/tan(angle/2), 0, w/2, 0; 0, w/2/tan(angle/2), h/2, 0; 0, 0, 1, 0; 0, 0, 0, 1];

    out_v = [];
    for k = 1:length(param)
        phi = param(k).phi;
        theta = param(k).theta;

        z_amt = cos(phi)*cos(theta);
        x_amt = cos(phi)*sin(theta);
        y_amt = sin(phi);
        
        %z_amt=1; x_amt=0; y_amt=0;
        camera_center = center_vec + [x_amt y_amt z_amt]*dist_camera_obj*param(k).d;
        
        %     rotationY(theta)
        %     rotationX(-phi)
        E_mat = inv(translation(camera_center) * rotationY(theta) * rotationX(-phi));
        E_mat(:,4) = E_mat(:,4) + dist_camera_obj*param(k).d*tan(param(1).angle/2/180*pi)*[param(k).x -1*param(k).y*h/w 0 0]';
        

        if return_v
            pt3d = [pt3d'; ones(1,size(pt3d,1))];
            v = I_mat * E_mat * pt3d;
            v = v./repmat(v(3,:),[4, 1]);
            v = v(1:2,:)';
            out_v(:,:,k) = v;
        end
            
        out_camera_center(:,:,k) = camera_center;
        out_E_mat(:,:,k) = E_mat;
        out_I_mat(:,:,k) = I_mat;
    end
end

function ret = rotationX(angle)
    ret = [1 0 0 0; 0 cos(angle) -sin(angle) 0; 0 sin(angle) cos(angle) 0; 0 0 0 1];
end

function ret = rotationY(angle)
    ret = [cos(angle) 0 sin(angle) 0; 0 1 0 0; -sin(angle) 0 cos(angle) 0; 0 0 0 1];
end

function ret = translation(vec)
    ret = eye(4);
    ret(1:3,4) = vec;
end