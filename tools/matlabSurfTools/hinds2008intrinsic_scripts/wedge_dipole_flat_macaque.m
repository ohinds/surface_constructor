% wedge_dipole_flat_macaque implements a simple wedge dipole mapping
% for a figure for the ex vivo stria neuroscience slides
% Oliver Hinds <oph@bu.edu>
% 2005-10-26

function h = wedge_dipole_flat_macaque(printfig)
  if(nargin < 1)
    printfig = 0;
  end
  
  % params
  a = 0.6;
  b = 80;
  alpha = 0.8;

  h = logmap_perimeter(a,b,alpha);
  
  figure(h);
  axis equal, axis tight, axis off;
  xlim = get(gca,'xlim');
  ylim = get(gca,'ylim');
  
  xlim = xlim*1.05;
  ylim = ylim*1.05;

  set(gca,'xlim',xlim);
  set(gca,'ylim',ylim);

%  set(gcf,'color',[0 0 0]);
%  set(gcf,'inverthardcopy','off')
  
  if(printfig)
    print -deps2 ../FIGURES/wedge_dipole_flat_macaque.eps
  end
return;

%  nring = 15;
%  nray = 10;
%  rays = [];
%  rings = [];
  
  % make rings and rays
%  ring_loc = logspace(log10(a),log10(b),nring);
%  for(r=1:length(ring_loc))
%    rings(:,end+1) = ring_loc(r)*exp(-i*[-alpha*pi/2:0.001:alpha*pi/2])';  
%  end
%  
%  for(a=linspace(-alpha*pi/2,alpha*pi/2,nray))
%    rays(:,end+1) = linspace(0,b,nray*b)'*(cos(a)+i*sin(a));
%  end

  %map_rays = log(rays+a)-log(rays+b)-log(real(a))+log(real(b));
  %map_rings = log(rings+a)-log(rings+b)-log(real(a))+log(real(b));

  % plot
%  figure, hold on;
%  plot(rings);
%  plot(rays);
%  xlabel('eccentricity (deg)');
%  ylabel('polar angle (deg)');
%  title('visual field');
%  axis equal;

%  figure,hold on;
  %plot(-map_rings,'w','linewidth',2);
  %plot(-map_rays,'w','linewidth',2);
%  plot(-map,'w','linewidth',2);