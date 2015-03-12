% fixFlatmapOrientation reads in the mat file for display of the
% surface of a sample, containing at least a flat surface, occipital
% pole vertex, and dorsal vertex. the outward pointingness of the
% flatmap is checked, and if it fails the y coordinates are
% negated. then the mat file is resaved.
%
% SAMPLE is the sampleid to process
%
% Oliver Hinds <oph@bu.edu>
% 2006-01-31

function fixFlatmapOrientation(sample)

  d = load(sprintf('display%s.mat',sample));
  eval(sprintf('flat = d.flatSurf%s;',sample));
  eval(sprintf('ocv = d.occPoleVertex%s;',sample));
  eval(sprintf('dv = d.dorsalVertex%s;',sample));

  fprintf('checking orientation consistency for ev%s\n',sample);

  % center vertices, rotate to align with occipital pole
  v = flat.vertices;
  v = v-repmat(mean(v),size(v,1),1);
  theta = atan2(v(ocv,2),v(ocv,1));
  A = [cos(theta) sin(theta) 0; -sin(theta), cos(theta), 0; 0 0 1];
  vo = (A*v')';
  
  % check orientation
  orient = cross(vo(ocv,:),vo(dv,:));
  if(orient(3) >= 0)
    fprintf('orientation is consistent\n');
  else
    fprintf('orientation is NOT consistent, flipping y coords\n');
    eval(sprintf('d.flatSurf%s.vertices(:,2) = -d.flatSurf%s.vertices(:,2);',sample,sample));
    eval(sprintf('d.smoothedFlatSurf%s.vertices(:,2) = -d.smoothedFlatSurf%s.vertices(:,2);',sample,sample));
    eval(sprintf('d.V1flatSurf%s.vertices(:,2) = -d.V1flatSurf%s.vertices(:,2);',sample,sample));
    eval(sprintf('d.V1smoothedFlatSurf%s.vertices(:,2) = -d.V1smoothedFlatSurf%s.vertices(:,2);',sample,sample));

    % save the display mat file
    eval(sprintf('save display%s.mat -STRUCT d',sample));
  end
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/fixFlatmapOrientation.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
