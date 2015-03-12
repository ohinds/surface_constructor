% scaleEllipseMaintainAspect find the scaling of an ellipse that
% maximizes the area of overlap with a reference ellipse
%
% scale = scaleEllipsesMaintainAspect(ref_ellipse,ellipse)
%
% Oliver Hinds <oph@bu.edu>
% 2006-02-16

function [scale err] = scaleEllipseMaintainAspect(ref_ellipse,ellipse)

  if(nargin < 2)
    fprintf('scale = scaleEllipseMaintainAspect(ref_ellipse,ellipse)\n');
    return;
  end

  % construct vectors for parameters
  aspect_ratio = ellipse.a/ellipse.b;
  x0 = [ellipse.a]; % initial model parameters

  opt = optimset('display','off','maxiter',5000);

  [x,fval,flag,out] = fminsearch(@ellipseErrOverlap,x0,opt,...
				 ref_ellipse,aspect_ratio);
  [res] = ellipseErrOverlap(x,ref_ellipse,aspect_ratio);

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

  scale = x(1);
  err = res;

return;

