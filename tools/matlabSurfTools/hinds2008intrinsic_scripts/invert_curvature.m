% negates the curvature data for a given display file
% Oliver Hinds <oph@bu.edu>
% 2005-11-01

function invert_curvature(matfile,suffix)

  load(matfile);

  newVcurve = eval(sprintf('-surf%s.vertexCurvature;',suffix));
  newFcurve = eval(sprintf('-surf%s.faceCurvature;',suffix));

  eval(sprintf('surf%s.vertexCurvature = newVcurve;',suffix));
  eval(sprintf('surf%s.faceCurvature = newFcurve;',suffix));
  
  eval(sprintf('flatSurf%s.vertexCurvature = newVcurve;',suffix));
  eval(sprintf('flatSurf%s.faceCurvature = newFcurve;',suffix));
  
  eval(sprintf('smoothedSurf%s.vertexCurvature = newVcurve;',suffix));
  eval(sprintf('smoothedSurf%s.faceCurvature = newFcurve;',suffix));

  eval(sprintf('smoothedFlatSurf%s.vertexCurvature = newVcurve;',suffix));
  eval(sprintf('smoothedFlatSurf%s.faceCurvature = newFcurve;',suffix));
  
  
  newVcurve = eval(sprintf('-V1surf%s.vertexCurvature;',suffix));
  newFcurve = eval(sprintf('-V1surf%s.faceCurvature;',suffix));

  eval(sprintf('V1surf%s.vertexCurvature = newVcurve;',suffix,suffix));
  eval(sprintf('V1surf%s.faceCurvature = newFcurve;',suffix,suffix));
  
  eval(sprintf('V1flatSurf%s.vertexCurvature = newVcurve;',suffix,suffix));
  eval(sprintf('V1flatSurf%s.faceCurvature = newFcurve;',suffix,suffix));
  
  eval(sprintf('V1smoothedSurf%s.vertexCurvature = newVcurve;',suffix,suffix));
  eval(sprintf('V1smoothedSurf%s.faceCurvature = newFcurve;',suffix,suffix));

  eval(sprintf('V1smoothedFlatSurf%s.vertexCurvature = newVcurve;',suffix,suffix));
  eval(sprintf('V1smoothedFlatSurf%s.faceCurvature = newFcurve;',suffix,suffix));
  
  
  eval(sprintf('save %s surf%s flatSurf%s smoothedSurf%s smoothedFlatSurf%s V1surf%s V1flatSurf%s V1smoothedSurf%s V1smoothedFlatSurf%s -APPEND',matfile,suffix,suffix,suffix,suffix,suffix,suffix,suffix,suffix));
  
return