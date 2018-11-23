function pos = collect_data(obj_type, reset)
% COLLECT_DATA gather ground truths from labeled data and format into a
% list.

% Copyright 2013 Joseph J. Lim


    globals_toolbox;
    
    filename = sprintf('%spos_%s.mat', TOOLBOX_DATA_DIR, obj_type);
    if ~reset && exist(filename, 'file') 
        load(filename);
    else    
        if strcmp(obj_type, 'ikeaobject')
            %unix(['./sql_to_txt.sh > data.txt']);
            s=reshape(textread([TOOLBOX_DATA_DIR 'data_ikeaobject.txt'],'%s'), 7, [])';
        elseif strcmp(obj_type, 'ikearoom')
            s=reshape(textread([TOOLBOX_DATA_DIR 'data_ikearoom.txt'],'%s'), 8, [])';
        else
            error('obj_type mismatched');
        end

        cou = 0;
        for i = 2:size(s,1)
            r = s(i,:);

            if any(strcmp(r,'BAD')) || strcmp(r{5},'::')
                continue;
            end

            tmp = regexp(r{5},'::', 'split');
            if length(tmp) < 5
                continue;
            end
            
            [bestRp, bestTp, bestFoc, bestErr, v2d, v3d, A] = render_helper(r{2}, regexp(r{5}, '::', 'split'));

            if exist('pos', 'var')
                pos_id = find(strcmp({pos.im}, r{2}));
            else
                pos_id = [];
            end
            if isempty(pos_id)
                cou = cou + 1;
                
                pos(cou).im = r{2};
            
                gt_info.type = r{3};
                gt_info.obj = r{4};        
                gt_info.foc = bestFoc;
                gt_info.matched = r{5};
                gt_info.labeler = r{7};
                gt_info.sql_id = r{1};
                gt_info.Rp = bestRp;
                gt_info.Tp = bestTp;
                gt_info.err = bestErr;
                gt_info.v2d = v2d;
                gt_info.v3d = v3d;
                gt_info.l2d = [];
                gt_info.l3d = [];
                gt_info.I = A;
                pos(cou).gt_info = gt_info;

                pos(cou).pos_prefix = obj_type;
                pos(cou).pos_id = cou;

                pos(cou).opt = [];        
            else
                gt_info.type = r{3};
                gt_info.obj = r{4};        
                gt_info.foc = bestFoc;
                gt_info.matched = r{5};
                gt_info.labeler = r{7};
                gt_info.sql_id = r{1};
                gt_info.Rp = bestRp;
                gt_info.Tp = bestTp;
                gt_info.err = bestErr;
                gt_info.v2d = v2d;
                gt_info.v3d = v3d;
                gt_info.l2d = [];
                gt_info.l3d = [];
                gt_info.I = A;
                pos(pos_id).gt_info(end+1) = gt_info;
            end

            i
        end


        save(filename, 'pos');
    end
end

function [bestRp, bestTp, bestFoc, bestErr, v2d, v3d, A2] = render_helper(real_id, matched_particle)
%     obj_name=['/afs/csail.mit.edu/u/l/lim/public_html/weio_synthetic_world/data/ikea/' real_name '/' matched_id '.obj'];
%     try
%         [v,f,vn,fn] = readObj(obj_name);
%     catch e
%         bestRp = -1; bestTp = -1; bestFoc = -1; bestErr = inf; v2d =[]; v3d =[]; A2=[];
%         return ;
%     end
    
    matched_particle = matched_particle(2:end-1);    
    for i = 1:length(matched_particle)
        sp = regexp(matched_particle{i}, ',', 'split');
        v2d(i,:) = [str2num(sp{5}), str2num(sp{6})];
        v3d(i,:) = [str2num(sp{2}), str2num(sp{3}), str2num(sp{4})];
    end
    
    im = imread(real_id);
    im = imresize(im, [nan 500]);
    
    v3d(:,4) = 1;
    v2d(:,3) = 1;

    bestErr = inf;
    for foc = 300:10:2000
        A = [foc 0 size(im,2)/2; 0 foc size(im,1)/2; 0 0 1];

        [Rp,Tp]=efficient_pnp(v3d,v2d,A);
        
        P=A*[Rp,Tp];
        proj_pt = (P*v3d')';
        proj_pt = bsxfun(@rdivide, proj_pt(:,1:2), proj_pt(:,3));
        err = mean(sqrt(sum((proj_pt - v2d(:,1:2)).^2,2)));
        
%         A2 = [-foc 0 size(im,2)/2; 0 foc size(im,1)/2; 0 0 1];
%         TT=inv([[A2;0 0 0],[0;0;0;1]])*[[A;0 0 0],[0;0;0;1]]*[Rp,Tp; 0 0 0 1];
%         Rp=TT(1:3,1:3);
%         Tp=TT(1:3,4);
%         [Rp2,Tp2,err2] = nonlinear_pnp_mix(v3d', v2d(:,1:2)', [], [], A2, Rp,Tp);
%         Rp = Rp2;
%         Tp = Tp2;
%         err = err2;
        
        if err < bestErr
            bestFoc = foc;
            bestErr = err;
            bestRp = Rp;
            bestTp = Tp;
        end
    end
    
    %bestErr
    
    A = [bestFoc 0 size(im,2)/2; 0 bestFoc size(im,1)/2; 0 0 1];
    A2 = [-bestFoc 0 size(im,2)/2; 0 bestFoc size(im,1)/2; 0 0 1];
    TT=-inv(A2)*A*[bestRp,bestTp];
    bestRp=TT(1:3,1:3);
    bestTp=TT(1:3,4);
    [bestRp,bestTp,bestErr] = nonlinear_pnp_mix(v3d', v2d(:,1:2)', [], [], A2, bestRp,bestTp);
        
    bestErr

    %A2 = [bestFoc 0 size(im,2)/2; 0 bestFoc size(im,1)/2; 0 0 1];
    %P=A2*[bestRp,bestTp];
    %proj_pt = (P*[v,ones(size(v,1),1)]')';
    %proj_pt = bsxfun(@rdivide, proj_pt, proj_pt(:,3));    
end