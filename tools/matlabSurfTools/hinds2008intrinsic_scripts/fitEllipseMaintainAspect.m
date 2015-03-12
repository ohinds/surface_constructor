% fitEllipseMaintainAspect fits an ellipse to the boundary of a flat surface
%
% [A, B, TX, TY, R, S] = FIT_ELLIPSE(FLATSURF)
% A  is the semimajor axis
% B  is the semiminor axis
% TX is translation laterally
% TY is translation vertically
% R  is rotation
% S  is scale
%
% Oliver Hinds <oph@bu.edu>
% 2005-05-04

function ellipse = fitEllipseMaintainAspect(surfStruct,e0)

  if(nargin < 2)
    fprintf('ellipse = fitEllipseMaintainAspect(surfStruct,e0)\n');
    return;
  end

  weight = 0;
  upsample = 0;
  %keyboard

  if(~isstruct(surfStruct))
    coords = surfStruct;
    %[v,e] = eig(cov(coords));
  else
    if(upsample)
      coords = upsampleBorder(surfStruct);
    else
      coords = surfStruct.vertices(boundaryVertices(surfStruct),:);
    end
    %[v,e] = eig(cov(surfStruct.vertices(:,1:2)));
  end

  % do an eigenanalysis to find best initial parameters
  %[v,e] = eig(cov(coords));
  %e = diag(e);
  %[trash, mxind] = max(e);

%   mn = min(coords);
%   mx = max(coords);
%   ord = sort((mx-mn)/3,1,'descend');
  %ord = sort(sqrt(e),1,'descend');
  %
  %if(nargin < 3 | r0 == [])
  %  r0 = atan2(v(mxind,2),v(mxind,1));
  %  if(r0 < pi/2)
  %    r0 = r0 + pi;
  %  elseif(r0 > 3*pi/2)
  %    r0 = r0 - pi;
  %  end
  %end
  %
  %if(nargin < 4 | a0 == [])
  %  a0 = ord(1);
  %end
  %
  %if(nargin < 5 | b0 == [])
  %  b0 = ord(2);
  %end
  %
  %if(nargin < 6 | tx0 == [])
  %  tx0 = mean(coords(:,1));
  %end
  %
  %if(nargin < 7 | ty0 == [])
  %  ty0 = mean(coords(:,2));
  %end


  % construct vectors for parameters
  aspect_ratio = e0.a/e0.b;
  x0 = [e0.a,e0.tx,e0.ty,e0.r]; % initial model parameters

  if(weight)
    [wgrid, wmapx, wmapy] = get_wgrid(coords,2);
  end

%   figure,set(gcf,'doublebuffer','on');
%   plot(coords(:,1), coords(:,2),'.');
%   hold on
%   opts = {'r'};
%   plot_ellipse(e0,opts);

  opt = optimset('display','off','maxiter',5000);
  if(weight)
    [x,fval,flag,out] = fminsearch(@ellipseErrMaintainAspect,...
				   x0,opt,coords,aspect_ratio,...
				   wgrid,wmapx,wmapy);
    [res] = ellipseErrMaintainAspect(x,coords,aspect_ratio,wgrid,wmapx,wmapy);
  else
    [x,fval,flag,out] = fminsearch(@ellipseErrMaintainAspect,x0,opt,...
				   coords,aspect_ratio);
    [res] = ellipseErrMaintainAspect(x,coords,aspect_ratio);
  end

  % check the error flag
  if(flag < 0)
    fprintf('error: fminsearch did not converge\n');
  elseif(flag == 0)
    fprintf('error: fminsearch exceeded the max number of iterations\n');
  else % if success, print some info
    fprintf(['success: the %s algorithm performed %d function' ...
	    ' evaluations using %d iterations\n'], out.algorithm, ...
	    out.funcCount, out.iterations);
  end

  ellipse.a = x(1);
  ellipse.b = x(1)/aspect_ratio;
  ellipse.tx = x(2);
  ellipse.ty = x(3);
  ellipse.r = x(4);
  ellipse.e = res;

return;



% calculate the error of the fit of a set of vertex coordinates to
% an analytically determined ellipse. wgrid is a grid of weights
% that attempts to account for the desity of the vertices along the
% boundary of some flattened surface. see getWgrid.m for details
% parameterizes ellipse by semi-major axis, aspect ratio,
% translation, rotation
% 
% Oliver Hinds <oph@bu.edu>
% 2005-05-23
function e = ellipseErrMaintainAspect(x,coords,aspect_ratio,wgrid,wmapx,wmapy)
  
  a = x(1);
  b = x(1)/aspect_ratio;
  tx = x(2);
  ty = x(3);
  r = x(4);
  
  e = 0;

  if(r < 0 | r > 2*pi)
    e = 100000;
  end
  
  for(v=1:size(coords,1))

    if(nargin > 3)
      wx = find(coords(v,1) < wmapx);
      if(length(wx) < 1)
	wx = size(wmapx,1);
      else 
	wx = wx(1);
      end
      
      wy = find(coords(v,2) < wmapy);
      if(length(wy) < 1)
	wy = size(wmapy,1);
      else 
	wy = wy(1);
      end
      
      w = wgrid(wx,wy);
    else
      w = 1;
    end
      
    tcoords = coords(v,1:2)';
    tcoords(1) = tcoords(1)-tx;
    tcoords(2) = tcoords(2)-ty;
    tcoords = inv([cos(r), sin(r); -sin(r), cos(r)]) * tcoords;
    
    e = e + w*abs(((tcoords(1)/a)^2 + (tcoords(2)/b)^2) - 1);
  end

%   cla;
%   plot(coords(:,1), coords(:,2),'g.');
%   hold on
%   plot_ellipse(a,b,tx,ty,r,'r');
%   pause(0.01);
  
return;
