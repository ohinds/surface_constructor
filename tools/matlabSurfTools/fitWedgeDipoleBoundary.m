% fitWedgeDipoleBoundary fits a wedge dipole to the boundary of a flat surface.
%
% NOTE: a, b, and alpha are fixed. a = 0.6, b = 80, and alpha = 0.8.
%
% [tx, ty, r, a, b, alpha, k] = FITWEDGEDIPOLEBOUNDARY(FLATSURF[,FIT_LABELS])

function [tx, ty, r, a, b, alpha, k] = fitWedgeDipoleBoundary(subjs_dir, subj, hemi)

  if nargin < 3
    hemi = '';
  else
    hemi = strcat('_', hemi);
  end

  path = strcat(subjs_dir, '/ex_vivo', subj, '/surfRecon');
  load(strcat(path, '/display_ev', subj, hemi));
  load(strcat(path, '/ant_vert', hemi, '.txt'));
  load(strcat(path, '/occ_vert', hemi, '.txt'));

  eval(strcat('surfStruct = flatSurf_ev', subj, hemi, ';'));
  eval(strcat('surfStruct.antVert = ant_vert', hemi, ';'));
  eval(strcat('surfStruct.occVert = occ_vert', hemi, ';'));

  antCoord = surfStruct.vertices(surfStruct.antVert, :);
  occCoord = surfStruct.vertices(surfStruct.occVert, :);

  r0 = atan2(antCoord(2) - occCoord(2), antCoord(1) - occCoord(1));

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
  visual_perimeter = visualPerimeter();
  dipole_boundary = wedgedipole(visual_perimeter, 0.6, 80, 0.8, 1, 1, k0, r0);

  keyboard

  t0 = occCoord(1) - real(dipole_boundary(1)) + i * occCoord(2) - imag(dipole_boundary(1));
  dipole_boundary = dipole_boundary + t0;

  % construct vectors for parameters
  x0 = [t0, r0, k0]; % initial model parameters

  opt = optimset('display','off');
  [x,fval,flag,out] = fminsearch(@dipoleErr, x0, opt, {coords, visual_perimeter});
  [res] = dipoleErr(x, {coords, visual_perimeter});

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

  t = x(1);
  r = x(2);
  k = x(3);
  a = 0.6;
  b = 80;
  alpha = 0.8;

  dipole = wedgedipole(visual_perimeter, a, b, alpha, 1, 1, k, r, t);

  plot(coords(:, 1), coords(:, 2)); hold on; plot(dipole);

  fit_file = strcat(path, '/wedge_dipole_fit', hemi);
  fprintf('saving parameters to %s.\n', fit_file);
  save(fit_file, 't', 'r', 'k', 'a', 'b', 'alpha');

  keyboard
return

function err = dipoleErr(x, data)

  coords = data{1};
  visual_perimeter = data{2};

  t = x(1);
  r = x(2);
  k = x(3);

  a = 0.6;
  b = 80;
  alpha = 0.8;

  dipole_boundary = wedgedipole(visual_perimeter, a, b, alpha, 1, 1, k, r, t);

  dists = zeros(size(coords, 1), 1);
  for i=1:size(coords, 1)
    dists(i) = findClosestVertDist(coords(i, :), dipole_boundary);
  end

  err = median(dists);

return

function dist = findClosestVertDist(pt, verts)

  dist = inf;
  for v=1:length(verts)
    d = norm(pt - [real(verts(v)) imag(verts(v))]);
    if d < dist
       dist = d;
    end
  end

return
