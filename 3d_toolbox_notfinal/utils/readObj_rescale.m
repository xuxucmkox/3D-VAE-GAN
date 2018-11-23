function [vertex, face, normal, face_normal] = readObj_rescale(OBJ3D_DIR, type, obj)
% function [vertex, face, normal, face_normal] = readObj(filename)

    the_ratio=get_scale_factor(type, obj);

    filename = [OBJ3D_DIR type '/' obj '.obj'];
    if (1)
        % 50x faster mex version
        [vertex, face, normal, face_normal] = mex_readobj(filename);
    else
        st = textread(filename, '%s', 'delimiter', '\n');

        vertex = zeros(50000, 3);
        normal = zeros(50000, 3);
        face = zeros(50000, 3);
        face_normal = zeros(50000, 3);
        v_i = 0;
        n_i = 0;
        f_i = 0;
        fn_i = 0;
        %vertex = [];
        %normal = [];
        %face = [];
        %face_normal = [];
        for i = 1:length(st)
            if (length(st{i}) <= 2)
                continue;
            end

            if strcmp(st{i}(1:2), 'v ')
                v_i = v_i+1;
                vertex(v_i,:) = str2num(st{i}(3:end));
            elseif strcmp(st{i}(1:3), 'vn ')
                n_i = n_i+1;
                normal(n_i,:) = str2num(st{i}(4:end));
            elseif strcmp(st{i}(1:2), 'f ')
                tmp = regexp(st{i}(3:end), ' ', 'split');
                tmp3 = [];
                tmp5 = [];
                for j = 1:length(tmp)
                    tmp2 = regexp(tmp{j}, '/', 'split');
                    if (length(tmp2{1}) < 1)
                        break;
                    end
                    tmp3(j) = str2num(tmp2{1});                
                    tmp5(j) = str2num(tmp2{3});
                end

    %             if length(tmp3)>4
    %                 tmp4 = vertex(tmp3,:);
    %                 a = tmp4(2,:) - tmp4(1,:);
    %                 b = tmp4(3,:) - tmp4(1,:);
    %                 n = cross(a,b);
    %                 for k = 1:length(tmp3)-1
    %                     if abs((tmp4(k+1,:)-tmp4(k,:))*n') < 1e-5
    %                     else
    %                         abs((tmp4(k+1,:)-tmp4(k,:))*n')
    %                         length(tmp3)
    %                     end
    %                 end
    %             end

                for j = 2:length(tmp3)-1
                    f_i = f_i + 1;
                    fn_i = fn_i + 1;
                    face(f_i,:) = [tmp3(1) tmp3(j) tmp3(j+1)];
                    face_normal(fn_i,:) = [tmp5(1) tmp5(j) tmp5(j+1)];
                end
            end
        end

        vertex = vertex(1:v_i,:);
        normal = normal(1:n_i,:);
        face = face(1:f_i,:);
        face_normal = face_normal(1:fn_i,:);
    end
    
    vertex = vertex / the_ratio;
end

% 
% function sameside = sameside(p1, p2, a,b)
%     cp1 = cross(repmat(b-a, [size(p1, 1), 1]), p1-repmat(a, [size(p1, 1), 1]));
%     cp2 = cross(b-a, p2-a);
%     
%     sameside = (cp1 * cp2') >= 0;
% end