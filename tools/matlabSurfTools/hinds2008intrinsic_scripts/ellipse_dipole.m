% ellipse_dipole generates a figure showing the similarity of the
% shapes of the ellipse and the dipole
% Oliver Hinds <oph@bu.edu>
% 2005-11-30

function ellipse_dipole(samples, printfig)
  if(nargin < 2)
    printfig = 0;
  end

  % load the display stuff
  aspects = [];
  for(s=1:length(samples))
    eval(sprintf('load surfStats%s.mat',samples{s}));        
    eval(sprintf('e = ellipse%s;',samples{s}));
    aspects(end+1) = e.a/e.b;
    clear e;
  end

  aspect_ratio = mean(aspects);
  fprintf('plotting aspect ratio %f\n',aspect_ratio);
  
  % plot the dipole
  a = 0.6;
  b = 80;
  alpha = 0.8;
  [h boundary] = logmap_perimeter(a,b,alpha);
  boundary = [real(boundary); imag(boundary)]';
  
  figure(h);
  hold on;
  
  % get the axis, find the tight bounds, add a smidgin
  a = gca;
  xlim = get(a,'xlim');
  xlim(1) = xlim(1)-diff(xlim)/100;
  xlim(2) = xlim(2)+diff(xlim)/100;
  set(a,'xlim',xlim);
  
  ylim = get(a,'ylim');
  ylim(1) = ylim(1)-diff(ylim)/100;
  ylim(2) = ylim(2)+diff(ylim)/100;  
  set(a,'ylim',ylim);
  
  e.a = abs(diff(xlim))/2;
  e.b = e.a/aspect_ratio;
  e.r = 0;
  e.tx = -e.a;
  e.ty = 0;
  
  e = fitEllipseMaintainAspect(boundary,e);
  
  % set up plot options
  opts = {'k--','linewidth',3};
  
  plot_ellipse(e,opts);
  
  axis off, axis equal, axis tight;
  xlim = get(gca,'xlim');
  set(gca,'xlim',1.05*xlim);
  
  ylim = get(gca,'ylim');
  set(gca,'ylim',1.05*ylim);

  if(printfig)
    print -depsc2 ../FIGURES/ellipse_dipole.eps
  end
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/ellipse_dipole.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:

