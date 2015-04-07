% fitWedgeDipoleBoundary fits a wedge dipole to the boundary of a flat surface.
%
% NOTE: a, b, and alpha are fixed. a = 0.6, b = 80, and alpha = 0.8.
%
% [tx, ty, r, a, b, alpha, k] = FITWEDGEDIPOLEBOUNDARY(FLATSURF[,FIT_LABELS])

function [tx, ty, r, a, b, alpha, k] = fitWedgeDipoleBoundary(surfStruct)

  r0 = atan2(surfStruct.vertices(surfStruct.occVert,2) - surfStruct.vertices(surfStruct.antVert,2),...
             surfStruct.vertices(surfStruct.occVert,1) - surfStruct.vertices(surfStruct.antVert,1));

  if(isfield(surfStruct, 'vertexLabels'))
    surfStruct = extractpatchCC(extractpatchQ(surfStruct,find(surfStruct.vertexLabels==1)));
  end

  if(~isfield(surfStruct, 'occVert') | ~isfield(surfStruct, 'antVert'))
    fprintf('ERROR: surface must contain occVert and antVert fields\n');
    tx = inf;
    ty = inf;
    r = inf;
    a = inf;
    b = inf;
    alpha = inf;
    k = inf;
    return
  end

  coords = surfStruct.vertices(boundaryVertices(surfStruct),1:2);

  k0 = 20;

  [h, dipole_boundary] = logmap_perimeter(0.6, 80, 0.8, k0, 0);
  dipole_boundary = [real(dipole_boundary); imag(dipole_boundary)]';

  R = [cos(r0), -sin(r0);
       sin(r0),  cos(r0)];
  rot_dipole = R * dipole_boundary';
  rot_dipole = rot_dipole';

  tx0 = mean(coords(:, 1)) - mean(rot_dipole(:, 1));
  ty0 = mean(coords(:, 2)) - mean(rot_dipole(:, 2));

  % construct vectors for parameters
  x0 = [tx0, ty0, r0, k0]; % initial model parameters

  opt = optimset('display','off');
  [x,fval,flag,out] = fminsearch(@dipoleErr,x0,opt,coords);
  [res] = dipoleErr(x,coords);

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

  tx = x(1);
  ty = x(2);
  r = x(3);
  k = x(4);
  a = 0.6;
  b = 80;
  alpha = 0.8;


  [h, dipole_boundary] = logmap_perimeter(a, b, alpha, k, 0);

  keyboard

  dipole_boundary = [real(dipole_boundary); imag(dipole_boundary)]';

  R = [cos(r), -sin(r);
       sin(r),  cos(r)];
  rot_dipole = R * dipole_boundary';
  rot_dipole = rot_dipole';

  trans_dipole = rot_dipole + [repmat(tx, size(rot_dipole, 1), 1), repmat(ty, size(rot_dipole, 1), 1)];

  plot(coords(:, 1), coords(:, 2)); hold on; plot(trans_dipole(:, 1), trans_dipole(:, 2));


return

function err = dipoleErr(x, coords)

  BIG_ERR = 10000000;

  tx = x(1);
  ty = x(2);
  r = x(3);
  k = x(4);

  % sanity
  if r > pi
     err = BIG_ERR;
     return
  end

  a = 0.6;
  b = 80;
  alpha = 0.8;

  [h, dipole_boundary] = logmap_perimeter(a, b, alpha, k, 0);
  dipole_boundary = [real(dipole_boundary); imag(dipole_boundary)]';

  R = [cos(r), -sin(r);
       sin(r),  cos(r)];
  rot_dipole = R * dipole_boundary';
  rot_dipole = rot_dipole';

  trans_dipole = rot_dipole + [repmat(tx, size(rot_dipole, 1), 1), repmat(ty, size(rot_dipole, 1), 1)];

  dists = zeros(size(coords, 1), 1);
  for i=1:size(coords, 1)
    dists(i) = findClosestVertDist(coords(i, :), trans_dipole);
  end

  err = median(dists);

return

function dist = findClosestVertDist(pt, verts)

  dist = inf;
  for v=1:size(verts, 1)
    d = norm(pt - verts(v, :));
    if d < dist
       dist = d;
    end
  end

return
