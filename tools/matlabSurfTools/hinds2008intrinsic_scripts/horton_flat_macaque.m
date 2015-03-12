% generates a figure showing the stereotyped shape of flattened V1
% in macaques due to horton1996intrinsic
%
% Oliver Hinds <oph@bu.edu> 2005-11-07

function horton_flat_macaque(printfig)
  %
  if(nargin < 1)
    printfig = 0;
  end

  load macaqueV1borders;

  monkey = {
      'm1l',
      'm1r',
      'm2l',
      'm2r',
      'm3l',
      'm3r',
      'm4l',
      'm4r'
	   };

  % make the monkey figure
  figure, hold on, axis off, axis equal;
  for(m=1:length(monkey))
    name = monkey{m};
    
    % get the vertices
    eval(sprintf('v = [%s.x; %s.y];',name,name));
    v = v';
    
    % get the ellipse
    eval(sprintf('e = %s.e;',name));    
    
    v = (inv([cos(e.r) sin(e.r); -sin(e.r) cos(e.r)]) * ...
	 (v(:,1:2)-repmat([e.tx e.ty]',1,size(v,1))')')'./e.a;

    plot(v(:,1),-v(:,2),'k-');
  end
  
  if(printfig) 
    print -depsc2 ../FIGURES/horton_flat_macaque.eps
  end
  
return;
