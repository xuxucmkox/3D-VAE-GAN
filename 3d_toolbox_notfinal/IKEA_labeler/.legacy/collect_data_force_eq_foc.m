function pos = collect_data_force_eq_foc(obj_type, reset)
% COLLECT_DATA gather ground truths from labeled data and format into a
% list.

% Copyright 2013 Joseph J. Lim


    globals_toolbox;
    
    filename = sprintf('%spos_%s.mat', TOOLBOX_DATA_DIR, obj_type);
    if ~reset && exist(filename, 'file') 
        load(filename);
    else    
        if strcmp(obj_type, 'test')
            %unix(['./sql_to_txt.sh > data.txt']);
            s=reshape(textread([TOOLBOX_DATA_DIR 'ikearoom_update.txt'],'%s'), 8, [])';
        elseif strcmp(obj_type, 'ikeaobject')
            %unix(['./sql_to_txt.sh > data.txt']);
            s=reshape(textread([TOOLBOX_DATA_DIR 'data_ikeaobject.txt'],'%s'), 7, [])';
        elseif strcmp(obj_type, 'ikearoom_eqfoc')
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
                gt_info.matched = r{5};
                gt_info.labeler = r{7};
                gt_info.sql_id = r{1};
                gt_info.l2d = [];
                gt_info.l3d = [];
                pos(cou).gt_info = gt_info;

                pos(cou).pos_prefix = obj_type;
                pos(cou).pos_id = cou;

                pos(cou).opt = [];        
            else
                gt_info.type = r{3};
                gt_info.obj = r{4};        
                gt_info.matched = r{5};
                gt_info.labeler = r{7};
                gt_info.sql_id = r{1};
                gt_info.l2d = [];
                gt_info.l3d = [];
                pos(pos_id).gt_info(end+1) = gt_info;
            end

            i
        end

        for i = 1:length(pos)
            fprintf('%d/%d\n', i, length(pos));
            try
                pos(i).gt_info = obtain_gt_info(pos(i).gt_info, pos(i).im);
            catch
            end
        end

        save(filename, 'pos');
    end
end

function gt_info = obtain_gt_info(gt_info, real_id)
    im = imread(real_id);
    im = imresize(im, [nan 500]);
    
    bestErr = inf;
    for foc = 300:10:2000
        err = zeros(length(gt_info),1);
        for j = 1:length(gt_info)
            [Rp{j}, Tp{j}, err(j), v2d{j}, v3d{j}] = render_helper(real_id, regexp(gt_info(j).matched, '::', 'split'), foc, im);
        end        
        
        if mean(err) < mean(bestErr)
            bestFoc = foc;
            bestErr = err;
            bestRp = Rp;
            bestTp = Tp;
        end
    end
    
    
    A = [bestFoc 0 size(im,2)/2; 0 bestFoc size(im,1)/2; 0 0 1];
    A2 = [-bestFoc 0 size(im,2)/2; 0 bestFoc size(im,1)/2; 0 0 1];
    for j = 1:length(gt_info)       
        TT=-inv(A2)*A*[bestRp{j},bestTp{j}];
        bestRp{j}=TT(1:3,1:3);
        bestTp{j}=TT(1:3,4);
        [bestRp{j},bestTp{j},bestErr(j)] = nonlinear_pnp_mix(v3d{j}', v2d{j}(:,1:2)', [], [], A2, bestRp{j},bestTp{j});
        
    
        gt_info(j).Rp = bestRp{j};
        gt_info(j).Tp = bestTp{j};
        gt_info(j).foc = bestFoc;
        gt_info(j).err = bestErr(j);
        gt_info(j).I = A2;
        gt_info(j).v2d = v2d{j};
        gt_info(j).v3d = v3d{j};
    end
    
    mean(bestErr)
end

function [Rp, Tp, err, v2d, v3d] = render_helper(real_id, matched_particle, foc, im)
    matched_particle = matched_particle(2:end-1);    
    for i = 1:length(matched_particle)
        sp = regexp(matched_particle{i}, ',', 'split');
        v2d(i,:) = [str2num(sp{5}), str2num(sp{6})];
        v3d(i,:) = [str2num(sp{2}), str2num(sp{3}), str2num(sp{4})];
    end
    
    v3d(:,4) = 1;
    v2d(:,3) = 1;
    
    A = [foc 0 size(im,2)/2; 0 foc size(im,1)/2; 0 0 1];

    [Rp,Tp]=efficient_pnp(v3d,v2d,A);

    P=A*[Rp,Tp];
    proj_pt = (P*v3d')';
    proj_pt = bsxfun(@rdivide, proj_pt(:,1:2), proj_pt(:,3));
    err = mean(sqrt(sum((proj_pt - v2d(:,1:2)).^2,2)));
end