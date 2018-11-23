function model_info = extract_all_models(pos)
% Given all GT pos, extract all 3D object models labeled in pos and their
% counts. Outputs are sorted in descending order of occurances.
%
% INPUTS:
%  pos  - GT pos
%
% OUTPUTS:
%  model_info(i) - each 3D object model
%   .obj          - 3D OBJ file is at 
%                   [OBJ3D_DIR model_info(i).obj '/' model_info(i).type '.obj']
%   .type        - see above
%   .count       - number of occurances of 3D models over the entire pos
%
% EXAMPLE
%  pos = collect_data_force_eq_foc_rescale('ikearoom', 0);
%  models = extract_all_models(pos);
%
% Copyright 2014 Joseph J. Lim [lim@csail.mit.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see bsd.txt]
    
    gt_infos = {};
    types = {};
    objs = {};
    for i = 1:length(pos)
        for j = 1:length(pos(i).gt_info)
            if ~isfield(pos(i).gt_info(j), 'foc')
                continue;
            end
            gt_infos{end+1} = [pos(i).gt_info(j).type '::' pos(i).gt_info(j).obj];
            types{end+1} = pos(i).gt_info(j).type;
            objs{end+1} = pos(i).gt_info(j).obj;
        end
    end
    [a,b,c]=unique(gt_infos);
    d=histc(c, 1:max(c));
    [~,e]=sort(d,'descend');
    for i = 1:length(e)
        model_info(i).type = types{find(e(i)==c,1)};
        model_info(i).obj = objs{find(e(i)==c,1)};
        model_info(i).count = sum(e(i)==c);
    end
end