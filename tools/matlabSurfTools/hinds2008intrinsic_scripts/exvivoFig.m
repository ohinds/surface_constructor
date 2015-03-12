% displays a figure for the ex vivo stria reconstruction flattening
% indicated by the argument
% Oliver Hinds <oph@bu.edu>
% 2005-12-14

function exvivoFig(sampleid,samplename,printfig)

  if(nargin < 1)
    fprintf('usage: exvivoFig(sampleid[,samplename,printfig]\n');
    return
  end
  if(nargin < 2)
    samplename = '';;
  end
  if(nargin < 3)
    printfig = 0;
  end

  % load the display stuff
  d = load(sprintf('display%s.mat',sampleid));
  s = load(sprintf('surfStats%s.mat',sampleid));

  % make a figure of the flattened surface
  figure;
  %set(gcf,'color',[0 0 0]);
  %set(gcf,'inverthardcopy','off')

  % set standard var names
  eval(sprintf('surf = d.smoothedFlatSurf%s;',sampleid));
  eval(sprintf('V1surf = d.V1smoothedFlatSurf%s;',sampleid));
  eval(sprintf('dv = d.flatSurf%s.vertices(d.dorsalVertex%s,:);',...
	       sampleid,sampleid));
  eval(sprintf('e = s.ellipse%s;',sampleid));

  if(isfield(d,sprintf('errcdata%s',sampleid)))
    eval(sprintf('ecd = d.errcdata%s;',sampleid));
    hasecd = 1;
  else
    hasecd = 0;
  end

  % correct vertices into common space of ellipse
  v = surf.vertices;
  surf.vertices = (inv([cos(e.r) sin(e.r); -sin(e.r) ...
		    cos(e.r)]) * (v(:, 1:2)-repmat([e.tx e.ty]',1, ...
						   size(v,1))')')'./e.a;

  % fix the V1 vertices
  v = V1surf.vertices;
  V1surf.vertices = (inv([cos(e.r) sin(e.r); -sin(e.r) ...
		    cos(e.r)]) * (v(:, 1:2)-repmat([e.tx e.ty]',1, ...
						   size(v,1))')')'./e.a;


  % plot the surface
  h = showSurf(surf,0,1,1);

  hold on

  opts = {'linewidth',2};

  % get the normalized ellipse
  norm_ellipse.a = 1.0;
  norm_ellipse.b = e.b/e.a;
  norm_ellipse.r = 0;
  norm_ellipse.tx = 0;
  norm_ellipse.ty = 0;
  plot_ellipse(norm_ellipse,opts,0.01);

  % make a scale bar
  %len = 15;
  %wid = 5;
  %norm_len = len/e.a;
  %norm_wid = wid/e.a;
  %barV = [0 0; norm_len 0; norm_len norm_wid; 0 norm_wid];
  %barF = [1 2 3 4];
  %patch('vertices',barV,'faces',barF,'facecolor','black','edgecolor','none');

  % make a star at the occipital pole
  eval(sprintf('ocv = surf.vertices(d.occPoleVertex%s,:);',sampleid));
  plot(ocv(1),ocv(2),'p','markeredgecolor','none','markerfacecolor','green','markersize',20);

  % load the plot prefs to get a scale
  load flatPlotPrefs.mat;

  mylim = lim*max_ellipse_a/e.a*[-1 1];

  set(gca,'xlim',mylim);
  set(gca,'ylim',mylim);  
  
  fancy = 0;
  if(printfig)
    if(fancy)
      setNonPatchesVisible(gca,0);
      eval(sprintf('print -dtiff ../FIGURES/flat%s.tif',samplename));
      setNonPatchesVisible(gca,1);

      setPatchesVisible(gca,0);
      eval(sprintf('print -depsc2 ../FIGURES/flat%s.eps',samplename));
      setPatchesVisible(gca,1);
    else
      eval(sprintf('print -depsc2 ../FIGURES/flat%s.eps',samplename));
      eval(sprintf('print -dtiff ../FIGURES/flat%s.tif',samplename));
    end
  end

  % make the flattening error figure

  if(~hasecd)
    return
  end

  figure, hold on;

  % threshold errcdata
  thresh = 40;
  fprintf('%s: %d outliers were thresholded out at %f\n', ...
	  samplename, length(find(ecd > thresh)), thresh);
  ecd(find(ecd > thresh)) = thresh;

  showSurf(surf,0,0,0,ecd);
  set(gca,'xlim',[-1 41]);
  
  bv = boundaryVertices(V1surf);

  plot(V1surf.vertices(bv,1),V1surf.vertices(bv,2),'k','linewidth',2);

  set(gca,'xlim',mylim);
  set(gca,'ylim',mylim);
  axis tight;

  colorbar('ylim', [5 40],'ytick',5:5:40);

  if(printfig)
    if(fancy)
      setNonPatchesVisible(gca,0);
      eval(sprintf('print -dtiff ../FIGURES/flaterr%s.tif',samplename));
      setNonPatchesVisible(gca,1);

      setPatchesVisible(gca,0);
      eval(sprintf('print -depsc2 ../FIGURES/flaterr%s.eps',samplename));
      setPatchesVisible(gca,1);
    else
      eval(sprintf('print -depsc2 ../FIGURES/flaterr%s.eps',samplename));
      eval(sprintf('print -dtiff ../FIGURES/flaterr%s.tif',samplename));
    end
  end

  % flattening error histogram
  numbins = 100;
  figure,hist(ecd,numbins);
  colormap(gray);

  xlabel('flattening error (%)');
  ylabel('number of vertices');

  if(printfig)
    eval(sprintf('print -depsc2 ../FIGURES/flaterrhist%s.eps',samplename));
    eval(sprintf('print -dtiff ../FIGURES/flaterrhist%s.tif',samplename));
  end

return;
