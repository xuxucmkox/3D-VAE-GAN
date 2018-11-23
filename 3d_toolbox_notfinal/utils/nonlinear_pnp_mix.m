function [Rp,Tp,err,proj_pt] = nonlinear_pnp_mix(p3d, p2d, l3d, l2d_s, A, Rp,Tp)
% everything n x 3, n x 2, ...

    %param = ones(6,1);
    if (trace(Rp)-1)/2 > 1
        theta = acos(1);
        w = [1 1 1] / norm([1 1 1]);
    elseif (trace(Rp)-1)/2 < -1
        theta = acos(-1);
        w = [1 1 1] / norm([1 1 1]);
    else
        theta = acos((trace(Rp)-1)/2);
        if theta
            w = 1/(2*sin(theta))*[Rp(3,2)-Rp(2,3);Rp(1,3)-Rp(3,1);Rp(2,1)-Rp(1,2)];
        else
            w = [1 0 0];
        end
    end    
    param(1:3,1) = w*theta;
    param(4:6,1) = Tp;

    l2d_s = reshape(l2d_s, 3, []);
    l3d = reshape(l3d, 4, []);

    e = 1e-6;
    
    J = zeros(size(p3d,2)*2+size(l3d,2), 6);
    e_add = eye(6)*e;
    p2d = reshape(p2d, [], 1);
    for iter = 1:20
        res = fproject(param, p3d, p2d, l3d, l2d_s, A);

        J(:,1) = (fproject(param+[e;0;0;0;0;0], p3d, p2d, l3d, l2d_s, A)-res)/e;
        J(:,2) = (fproject(param+[0;e;0;0;0;0], p3d, p2d, l3d, l2d_s, A)-res)/e;
        J(:,3) = (fproject(param+[0;0;e;0;0;0], p3d, p2d, l3d, l2d_s, A)-res)/e;
        J(:,4) = (fproject(param+[0;0;0;e;0;0], p3d, p2d, l3d, l2d_s, A)-res)/e;
        J(:,5) = (fproject(param+[0;0;0;0;e;0], p3d, p2d, l3d, l2d_s, A)-res)/e;
        J(:,6) = (fproject(param+[0;0;0;0;0;e], p3d, p2d, l3d, l2d_s, A)-res)/e;
        
        dx = pinv(J) * res;
        
        if abs(norm(dx)/norm(param)) < 1e-5
            break;
        end
        
        param = param - dx;
    end
    
    res = fproject(param, p3d, p2d, l3d, l2d_s, A);
    dy = reshape(res, 2, []);
    err = sum(sqrt(sum(dy.^2,1)))/size(dy,2);
    
    if iter == 20
        %keyboard;
    end

    
    [Rp,Tp]=convert_param(param);
end

function ph_o = fproject(param, p3d, p2d, l3d, l2d_s, A)
    if (0)
        [R,T]=convert_param(param);
    else
        E=mex_convert_param(param);
    end
    %[R,T]=convert_param(param);
    %assert(sum(sum(abs(E-[R,T]),1),2) < 1e-5);

    ph_o = zeros(size(p2d,1)+size(l2d_s,2),1);
    % point
    if ~isempty(p3d)
        ph = A*E*p3d;
        ph(1,:) = ph(1,:)./ph(3,:);
        ph(2,:) = ph(2,:)./ph(3,:);
        %ph2 = bsxfun(@rdivide, ph(1:2,:), ph(3,:));
        %ph = reshape(ph, [], 1) - p2d;
        ph_o(1:size(p2d,1)) = p2d - reshape(ph(1:2,:), [], 1);
    end
    
    % line
    if ~isempty(l3d)
        ph2 = A*E*l3d;
        ph2(1,:) = ph2(1,:)./ph2(3,:);
        ph2(2,:) = ph2(2,:)./ph2(3,:);
        %ph3 = bsxfun(@rdivide, ph2(1:2,:), ph2(3,:));
        ph2(3,:) = -1;

        ph_o(size(p2d,1)+1:end) = sum(ph2 .* l2d_s,1)';
    end
end

function [R,T]=convert_param(param)
    wx = param(1);
    wy = param(2);
    wz = param(3);
    
    theta = sqrt(wx^2 + wy^2 + wz^2);
    if theta ~= 0
        wx = wx / theta; wy = wy / theta; wz = wz / theta;
    end
    
    ct = cos(theta);
    st = sin(theta);
    R = [ct + wx^2*(1-ct), wx*wy*(1-ct)-wz*st, wy*st+wx*wz*(1-ct); ...
        wz*st + wx*wy*(1-ct), ct + wy^2*(1-ct), -wx*st+wy*wz*(1-ct); ...
        -wy*st + wx*wz*(1-ct), wx*st + wy*wz*(1-ct), ct+wz^2*(1-ct)];
    T=param(4:6);
end