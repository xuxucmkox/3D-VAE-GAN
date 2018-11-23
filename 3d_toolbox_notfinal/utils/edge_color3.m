function [eout,thresh] = edge_color3(a,thresh)
% Compute a Canny edgemap on multi-dimension image (this is NOT stable)


% Transform to a double precision intensity image if necessary
%if ~isa(a,'double') && ~isa(a,'single')
if ~isa(a,'single')
    a = im2single(a);
end

% Magic numbers
PercentOfPixelsNotEdges = .7; % Used for selecting thresholds
ThresholdRatio = .4;          % Low thresh is this fraction of the high.

% Calculate gradients using a derivative of Gaussian filter
[dx,dy]=gradient2(a); dx=convTri(dx,3); dy=convTri(dy,3);

[dx,dy,magGrad] = mexAbsMaxInd2(dx,dy);


% Normalize for threshold selection
magmax = max(magGrad(:));
if magmax > 0
    magGrad = magGrad / magmax;
end

% Determine Hysteresis Thresholds
[lowThresh, highThresh] = selectThresholds(thresh, magGrad, PercentOfPixelsNotEdges, ThresholdRatio, mfilename);

% Perform Non-Maximum Suppression Thining and Hysteresis Thresholding of Edge
% Strength
eout = thinAndThreshold([], dx, dy, magGrad, lowThresh, highThresh);

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Local Function : selectThresholds
%
function [lowThresh, highThresh] = selectThresholds(thresh, magGrad, PercentOfPixelsNotEdges, ThresholdRatio, ~)

[m,n] = size(magGrad);

% Select the thresholds
if isempty(thresh)
    counts=imhist(magGrad, 64);
    highThresh = find(cumsum(counts) > PercentOfPixelsNotEdges*m*n,...
        1,'first') / 64;
    lowThresh = ThresholdRatio*highThresh;
elseif length(thresh)==1
    highThresh = thresh;
    if thresh>=1
        error(message('images:edge:thresholdMustBeLessThanOne'))
    end
    lowThresh = ThresholdRatio*thresh;
elseif length(thresh)==2
    lowThresh = thresh(1);
    highThresh = thresh(2);
    if (lowThresh >= highThresh) || (highThresh >= 1)
        error(message('images:edge:thresholdOutOfRange'))
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Local Function : thinAndThreshold
%
function H = thinAndThreshold(E, dx, dy, magGrad, lowThresh, highThresh)

% Perform Non-Maximum Suppression Thining and Hysteresis Thresholding of Edge
% Strength
    
% We will accrue indices which specify ON pixels in strong edgemap
% The array e will become the weak edge map.

if (1)
    % MEX version
    [mask, marker] = mexCannyFindLocalMaximaHelper3(dx, dy, magGrad, lowThresh, highThresh);
elseif (0)
    idxStrong = [];
    for dir = 1:4
        idxLocalMax = cannyFindLocalMaxima(dir,dx,dy,magGrad);
        idxWeak = idxLocalMax(magGrad(idxLocalMax) > lowThresh);
        E(idxWeak)=1;
        idxStrong = [idxStrong; idxWeak(magGrad(idxWeak) > highThresh)]; %#ok<AGROW>
    end
end

if (0)
    assert(isequal(unique(idxStrong_o), unique(idxStrong)) && isequal(E, E_o));
end

if any(marker(:)) % result is all zeros if idxStrong is empty
    H = imreconstruct(marker, mask, 8);
    %H = imreconstructmex(marker, mask, 8);
else
    H = zeros(size(marker));
end
