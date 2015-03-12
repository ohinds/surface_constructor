% Oliver Hinds <oph@bu.edu>
% 2006-04-26

function [tr tt err] = analyze2dShapeICP(samples)
  
  % read the ellipses and boundaries
  for(s=1:length(samples))
    eval(sprintf('load display%s.mat',samples{s}));
    eval(sprintf('load surfStats%s.mat',samples{s}));        
  
    eval(sprintf('v1bv = V1smoothedFlatSurf%s.vertices(boundaryVertices(V1smoothedFlatSurf%s),:);',samples{s},samples{s}));
    eval(sprintf('e = ellipse%s;',samples{s}));

    boundaries{s} = v1bv;
    ellipses{s} = e;
  end
  
  % align all the boundaries to the first one
  A = inv(getEllipseTransform(ellipses{1}));
  model = transformVertices(boundaries{1},A)';
  
  tr{1} = eye(3);
  tt{1} = zeros(3,1);
  err(1) = 0.;

  % find the icp transformation for each boundary
  for(b=2:length(boundaries))
    % transform the boundary for an initial guess
    boundary = boundaries{b};
    ell = ellipses{b};

    A = inv(getEllipseTransform(ell));
    boundary = transformVertices(boundary,A)';
    
    [tr{b} tt{b} err(b)] = icp(model, boundary, 2);
  end
    
return

function A = getEllipseTransform(ell)
  A = ell.a*[cos(ell.r) sin(ell.r);-sin(ell.r) cos(ell.r)];
  A(3,:) = [0 0];
  A(:,3) = [0 0 1]';
  A(:,4) = [ell.tx ell.ty 0]';
  A(4,:) = [0 0 0 1];
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/analyze2dShapeICP.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
