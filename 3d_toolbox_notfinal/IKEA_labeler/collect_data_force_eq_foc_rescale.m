function pos = collect_data_force_eq_foc_rescale(gt_type, reset)
% Gather ground truths from labeled data and estimate all poses for objects
% in each image.
%
% INPUTS:
%  gt_type - target groundtruth type (i.e. 'ikearoom', 'ikeaobject')
%  reset   - [0] re-estimate all poses from labels again if 1.
%
% OUTPUTS:
%  pos(i)
%   .gt_info(j) - each object's estimated pose
%     .obj        - 3D OBJ file is at 
%                     [OBJ3D_DIR gt_info(j).obj '/' gt_info(j).type '.obj']
%     .type       - see above
%     .matched    - debug info
%     .labeler    - labeler's ID
%     .foc        - GT estimated focal length
%     .Rp         - GT estimated rotation matrix 
%     .Tp         - GT estimated translation matrix
%     .err        - ground truth estimation error
%     .v2d        - corresponding 2d points used for GT estimation 
%     .v3d        - corresponding 3d points used for GT estimation
%   .pos_prefix - debug info
%   .pos_id     - debug info
%   .opt        - debug info
%   .im         - Image location
%
% EXAMPLE
%  pos = collect_data_force_eq_foc_rescale('ikearoom', 0);
%
% Copyright 2014 Joseph J. Lim [lim@csail.mit.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see bsd.txt]

    globals_toolbox;

    filename = sprintf('%spos_%s_eqfocrescale.mat', TOOLBOX_DATA_DIR, gt_type);
    if ~reset && exist(filename, 'file') 
        load(filename);
    elseif reset
        label_files=dir([LABEL_DIR '*.xml']);
        
        i = 0;
        for ii = 1:length(label_files)
            xmldata = xmlread([LABEL_DIR label_files(ii).name]);

            objectsNode = xmldata.getDocumentElement.getElementsByTagName('objects').item(0).getElementsByTagName('object');
            type = char(xmldata.getDocumentElement.getElementsByTagName('type').item(0).getFirstChild.getData);
            if ~(isempty(gt_type) || strcmp(gt_type, type))
                continue;
            end
            i = i + 1;
            foc = str2double(xmldata.getDocumentElement.getElementsByTagName('focal').item(0).getFirstChild.getData);
            im = char(xmldata.getDocumentElement.getElementsByTagName('name').item(0).getFirstChild.getData);
            for j = 0:objectsNode.getLength-1
                objectItem = objectsNode.item(j);

                pos(i).gt_info(j+1).obj = char(objectItem.getElementsByTagName('obj').item(0).getFirstChild.getData);
                pos(i).gt_info(j+1).type = char(objectItem.getElementsByTagName('type').item(0).getFirstChild.getData);
                pos(i).gt_info(j+1).matched = char(objectItem.getElementsByTagName('matches').item(0).getFirstChild.getData);
                pos(i).gt_info(j+1).labeler = char(objectItem.getElementsByTagName('labeler').item(0).getFirstChild.getData);
                pos(i).gt_info(j+1).foc = foc;
                pos(i).gt_info(j+1).l2d = [];
                pos(i).gt_info(j+1).l3d = [];
                pos(i).gt_info(j+1).truncated = [];
                pos(i).gt_info(j+1).difficult = [];
            end
            pos(i).pos_prefix = type;
            pos(i).pos_id = i;
            pos(i).opt = [];
            pos(i).im = im;

            i
        end

        for i = 1:length(pos)
            fprintf('%d/%d\n', i, length(pos));
            try
                pos(i).gt_info = obtain_gt_info(pos(i).gt_info, pos(i).im);
            catch me
                me
            end
        end

        save(filename, 'pos');
    end
end

function gt_info = obtain_gt_info(gt_info, real_id)
    globals_toolbox;
    
    im = imread(real_id);
    im = imresize(im, [nan 500]);
    
    bestErr = inf;
    for foc = 300:10:2000
        err = zeros(length(gt_info),1);
        for j = 1:length(gt_info)
            if (1)
                scale = get_scale_factor(gt_info(j).type, gt_info(j).obj);
            else
                scale = 1;
            end
            [Rp{j}, Tp{j}, err(j), v2d{j}, v3d{j}] = render_helper(real_id, regexp(gt_info(j).matched, '::', 'split'), foc, im, scale);
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
        
        v=readObj_rescale(OBJ3D_DIR, gt_info(j).type, gt_info(j).obj);
        v(:,4)=1;
        obj_v2d = A2*[bestRp{j}, bestTp{j}]*v';
        obj_v2d = bsxfun(@rdivide, obj_v2d(1:2,:), obj_v2d(3,:))';
        
        bbox = [min(obj_v2d), max(obj_v2d)];
        bbox2(1) = max(bbox(1), 1);
        bbox2(2) = max(bbox(2), 1);
        bbox2(3) = min(bbox(3), size(im,2));
        bbox2(4) = min(bbox(4), size(im,1));
        
        area1 = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
        area2 = (bbox2(3)-bbox2(1)+1)*(bbox2(4)-bbox2(2)+1);
    
        gt_info(j).Rp = bestRp{j};
        gt_info(j).Tp = bestTp{j};
        gt_info(j).foc = bestFoc;
        gt_info(j).err = bestErr(j);
        gt_info(j).I = A2;
        gt_info(j).v2d = v2d{j};
        gt_info(j).v3d = v3d{j};
        gt_info(j).truncated = 1-area2/area1;
        gt_info(j).difficult = [];
    end
    
    mean(bestErr)
end

function [Rp, Tp, err, v2d, v3d] = render_helper(real_id, matched_particle, foc, im, scale)
    matched_particle = matched_particle(2:end-1);    
    for i = 1:length(matched_particle)
        sp = regexp(matched_particle{i}, ',', 'split');
        v2d(i,:) = [str2num(sp{5}), str2num(sp{6})];
        v3d(i,:) = [str2num(sp{2}), str2num(sp{3}), str2num(sp{4})];
    end
    
    v3d(:,1:3) = v3d(:,1:3)/scale;
    v3d(:,4) = 1;
    v2d(:,3) = 1;
    
    A = [foc 0 size(im,2)/2; 0 foc size(im,1)/2; 0 0 1];

    [Rp,Tp]=efficient_pnp(v3d,v2d,A);

    P=A*[Rp,Tp];
    proj_pt = (P*v3d')';
    proj_pt = bsxfun(@rdivide, proj_pt(:,1:2), proj_pt(:,3));
    err = mean(sqrt(sum((proj_pt - v2d(:,1:2)).^2,2)));
end