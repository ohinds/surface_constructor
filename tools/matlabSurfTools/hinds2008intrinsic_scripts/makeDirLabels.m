% makeDirLabels makes the labels indicating the directional axes on
% a patch figure
%
% Oliver Hinds <oph@bu.edu>
% 2005-05-24

function makeDirLabels(varargin)

  camRatio = 0.9;
  midRatio = varargin{end};
  
  if(nargin < 4 | mod(nargin,2) ~= 1)
    fprintf('usage: makeDirLabels(axis,patch,vertex,''label''[,vertex,''label''...])\n');
    return;
  end

  % read the input axis and patch
  a = varargin{1};
  p = varargin{2};
  v = get(p,'vertices');
  
  % get the camera position to adjust the placement of the text
  cp = get(a,'cameraposition');

  % read the labels and vertices
  c = 1;
  for(i=3:2:nargin-1)
    if(size(varargin{i}) ~= [1,3])
      fprintf('error: vertices must be [1,3] vectors\n');
      continue;
    end

    % move toward camera
    pos = cp + camRatio*(varargin{i}-cp);

    % move away from center of patch
    pos = pos - (midRatio(c))*(mean(v)-pos);
    
    text(pos(1),pos(2),pos(3),varargin{i+1},'fontsize',16,'color','red');
    c = c+1;
  end

return
