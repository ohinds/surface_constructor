% extract the labeled vertices and saves the mat file with the new variables 
% suffix is the end of the variable names, eg '_ev19_sfn'
% Oliver Hinds <oph@bu.edu>
% 2005-10-30

function generateV1FromSurfLabels(matfilename,suffix)
  % validate
  if(nargin < 2)
    fprintf('usage: generateV1FromSurfLabels(matfilename)\n');
    return
  end
  
  load(matfilename);
  
  eval(sprintf('V1surf%s = pruneVertices(surf%s,find(surf%s.vertexLabels==-1));',...
	       suffix,suffix,suffix));
  eval(sprintf('V1surf%s = extractpatchCC(V1surf%s);',suffix,suffix));

  eval(sprintf('V1smoothedSurf%s = pruneVertices(smoothedSurf%s,find(surf%s.vertexLabels==-1));',...
	       suffix,suffix,suffix));
  eval(sprintf('V1smoothedSurf%s = extractpatchCC(V1smoothedSurf%s);',...
	       suffix,suffix));

  eval(sprintf('V1flatSurf%s = pruneVertices(flatSurf%s,find(surf%s.vertexLabels==-1));',...
	       suffix,suffix,suffix));
  eval(sprintf('V1flatSurf%s = extractpatchCC(V1flatSurf%s);',...
	       suffix,suffix));

  eval(sprintf('V1smoothedFlatSurf%s = pruneVertices(smoothedFlatSurf%s,find(surf%s.vertexLabels==-1));',...
	       suffix,suffix,suffix));
  eval(sprintf('V1smoothedFlatSurf%s = extractpatchCC(V1smoothedFlatSurf%s);',...
	       suffix,suffix));  
  
  eval(sprintf('save %s V1surf%s V1smoothedSurf%s V1flatSurf%s V1smoothedFlatSurf%s -APPEND',matfilename,suffix,suffix,suffix,suffix));
return

%************************************************************************%
%%% $Source: /home/oph/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/v1FromSurfLabels.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
