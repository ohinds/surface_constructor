% fitWedgeDipoleBoundary fits a wedge dipole to the boundary of a flat surface
%
% [BOUNDARY] = FITWEDGEDIPOLEBOUNDARY(FLATSURF[,FIT_LABELS])

function boundary = fitWedgeDipoleBoundary(surfStruct)

  if(isfield(surfStruct, 'vertexLabels'))
    surfStruct = extractpatchCC(extractpatchQ(surfStruct,find(surfStruct.vertexLabels==1)));
  end

  coords = surfStruct.vertices(boundaryVertices(surfStruct),:);

  % do an eigenanalysis to find best initial parameters
  [v,e] = eig(cov(coords));
  e = diag(e);
  [trash, mxind] = max(e);
  ord = sort(sqrt(e),1,'descend');

  r0 = atan2(v(mxind,2),v(mxind,1));
  if(r0 < pi/2)
    r0 = r0 + pi;
  elseif(r0 > 3*pi/2)
    r0 = r0 - pi;
  end

  k0 = 15;

  % construct vectors for parameters
  x0 = [tx0,ty0,r0,k0]; % initial model parameters

%   figure,set(gcf,'doublebuffer','on');
%   plot(coords(:,1), coords(:,2),'.');
%   hold on
%   plot_ellipse(a0,b0,tx0,ty0,r0,'r');

  opt = optimset('display','off');
  if(weight)
    [x,fval,flag,out] = fminsearch(@ellipseErr,x0,opt,coords,wgrid,wmapx,wmapy);
    [res] = ellipseErr(x,coords,wgrid,wmapx,wmapy);
  else
    [x,fval,flag,out] = fminsearch(@ellipseErr,x0,opt,coords);
    [res] = ellipseErr(x,coords);
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
  ellipse.b = x(2);
  ellipse.tx = x(3);
  ellipse.ty = x(4);
  ellipse.r = x(5);
  ellipse.e = res;

return;

function err = dipoleErr(x, coords):
