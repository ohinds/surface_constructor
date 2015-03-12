% make the stats and the fits for the horton macaque data
% Oliver Hinds <oph@bu.edu>
% 2005-10-30

function map = makeMacaqueStats
  samples = {
      'm1l',
      'm1r',
      'm2l',
      'm2r',
      'm3l',
      'm3r',
      'm4l',
      'm4r',
	    };
  
  % load the display stuff
  verts = {};
  ellipses = {};
  labels = {};
  aspects = [];
  load horton1996intrinsic_boundary_contours.mat
  for(s=1:length(samples))        
    name = samples{s};
    
    % normalize the vertices into the ellipse of the surface
    eval(sprintf('v = [%s.x; %s.y];',name,name));
    v = v';
    
    if(name(end) == 'l')
      v(:,1)=-v(:,1);
    end
    
    e = fitEllipse(v);
    ellipses{end+1} = e;
    aspects(end+1) = e.a/e.b;
    verts{end+1} = v;
    
    eval(sprintf('ellipse_%s = e;',name));
    eval(sprintf('aspect_%s = e.a/e.b;',name));
    eval(sprintf('verts_%s = v;',name));
    eval(sprintf('save macaqueStats_%s ellipse_%s aspect_%s verts_%s;',name,name,name,name));    
  end
  
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/makeMacaqueStats.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
