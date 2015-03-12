% calculates the surface statistics of a surfStruct used for
% comparison of surfaces
%
% Oliver Hinds <oph@bu.edu>
% 2004-11-05

function [area, perim, fperim, aspect, aspect3d, ellipse] ...
      = surfStats(surfStruct,v1flatSurf,occPoleVert,dm,flatSurf)
  % check for args
  if(nargin < 1)
    fprintf('usage: [area, perimeter, flat_perimeter, aspect, hm2sa, ellipse] = surfStats(surfStruct,flatSurf,occPoleVert)\n');
  end
  
  area = surfaceArea(surfStruct);
  perim = perimeter(surfStruct);
  fperim = perimeter(v1flatSurf);
  aspect = aspectRatio(v1flatSurf);
  ellipse = fitEllipse(v1flatSurf,occPoleVert);
  aspect3d = estimate3Daspect(flatSurf,dm,ellipse);
  
return

