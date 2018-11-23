function [im,b,im2,obj_data] = render_det_res(pos, obj_data, im)
    globals_toolbox;

    if exist('im', 'var')
    else
        im = imread(pos.im);
        im = imresize(im, [nan 500]);
    end
    foc_fact = pos.foc / size(im,2);    
    param.angle = atan(1/foc_fact/2)/pi*180*2;

    near = 0.01;
    far = 1000;
    F=[cot(param.angle/2/180*pi), 0 0 0; 0, cot(param.angle/2/180*pi)*size(im,2)/size(im,1), 0 0 ; 0 0 -(far+near)/(far-near) -2*far*near/(far-near); 0 0 -1 0];
    %F=[cot(param.angle/2/180*pi), 0 0 0; 0, cot(param.angle/2/180*pi), 0 0 ; 0 0 -(far+near)/(far-near) -2*far*near/(far-near); 0 0 -1 0];
    F2 = F;
    F2(1,:) = -F(2,:);
    F2(2,:) = -F(1,:);

    % Render using mex'ed OpenGL
    pos.F3 = F2;
    pos.E3 = [[pos.Rp, pos.Tp/100]; 0 0 0 1];
    pos.scale = 1/100;
    pos.type = pos.type;
    pos.obj = pos.obj;
    [~,b,c,d,obj_data,f]=render_pos(pos, obj_data);


    
    im = double(im)/255;
    mask = double(repmat(sum(f==0,3)<3,[ 1 1 3]));
    im2 = im .* ~mask + f .* (mask*.7) + im .* (mask*.3);
end
