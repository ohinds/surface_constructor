% generate the figure showing the shape similarity for the horton macaque data
% Oliver Hinds <oph@bu.edu>
% 2005-10-30

function map = macaqueOverlapFigs(printfig)
  % parameters for overlap computation
    
  % size of rectangle to compute overlap for, in ratio of ellipse size
  rectSize = 1.2;
  
  % number of spatial samples on a side of the rectangle to compute overlap
  spatialSamples = 1000;
  
  if(nargin < 1)
    printfig = 0;
  end

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
  for(s=1:length(samples))        
    name = samples{s};

    m = load(sprintf('macaqueStats_%s',name));
    eval(sprintf('e = m.ellipse_%s;',name));
    eval(sprintf('a = m.aspect_%s;',name));
    eval(sprintf('v = m.verts_%s;',name));

    ellipses{end+1} = e;
    aspects(end+1) = a;
    verts{end+1} = v;
  end
  clear v e a m;
    
  % get the average ellipse
  ave_ellipse.a = 1.0;
  ave_ellipse.b = mean(1./aspects);
  ave_ellipse.r = 0;
  ave_ellipse.tx = 0;
  ave_ellipse.ty = 0;
  
  % get the best overlapping scale to the ave ellipse for each best ellipse
  for(s=1:length(samples))
    diff = (1/aspects(s)-ave_ellipse.b)/2;
    ell.a = ave_ellipse.a - diff;
    ell.b = ell.a*ellipses{s}.b/ellipses{s}.a;
    scale = scaleEllipseMaintainAspect(ave_ellipse,ell);

    % convert the vertex coords
    e = ellipses{s};

    v = verts{s};
    v = (inv([cos(e.r) sin(e.r); -sin(e.r) cos(e.r)]) * ...
	 (v(:,1:2)-repmat([e.tx e.ty]',1,size(v,1))')')'./e.a;
    v = v*scale;
    verts{s} = v;
  end
    
  
  % generate spatial map of overlap
  map = zeros(spatialSamples);
  indiv_map = zeros(spatialSamples,spatialSamples,length(samples));
  count = zeros(length(samples)+1,1);
  [X,Y] = meshgrid(linspace(-rectSize,rectSize,spatialSamples));
  
  % get the counts for each sample
  for(s=1:length(samples))
    v = verts{s};
    in = inpolygon(X(:),Y(:),v(:,1),v(:,2));
    indiv_map(:,:,s) = reshape(in,spatialSamples,spatialSamples);
    map = map+indiv_map(:,:,s);
  end
  
  % count the number of samples in each pixel
  for(i=1:spatialSamples)
    x = X(1,i);
    for(j=1:spatialSamples)
      y = Y(j);
      
      % if this pixel is in the ellipse, store the count
      if(y^2+x^2/ave_ellipse.b^2 <= 1)
	count(map(i,j)+1) = count(map(i,j)+1)+1;
      end
    end
  end

  % print the percent blurring 
  indiv_count = squeeze(sum(sum(indiv_map)));
  per_blur = 100*(sum(map(:) > 0)-mean(indiv_count))/mean(indiv_count);
  fprintf('macaque percent blur is %0.2f%%\n',per_blur);  
  fprintf('macaque aspect ratio is %0.2f +/- %0.3f\n',...
	  mean(aspects),sqrt(var(aspects)));  
  
  
  % limit the figure to just nonzero rows and cols
  [r,c] = find(map > 0);  
  
  %disp_map = map(min(r):max(r),min(c):max(c));
  disp_map = map;

  % get a transformed ellipse for this image
  show_ell.a = spatialSamples/(rectSize*2);
  show_ell.b = ave_ellipse.b*show_ell.a;
  show_ell.r = 0;
  %show_ell.tx = size(disp_map,1)/2-1;
  %show_ell.ty = size(disp_map,2)/2-1;
  show_ell.tx = spatialSamples/2;
  show_ell.ty = spatialSamples/2;
  
  figure,imagesc(disp_map), axis off, axis image;
  set(gca,'xlim',[min(c) max(c)])
  set(gca,'ylim',[min(r) max(r)])
  %set(gcf,'color',[0 0 0]);
  %set(gcf,'inverthardcopy','off');
  
  % build a good colormap;
  cm = hot(12);
  cm = cm(1:end-4,:);
  cm(1,:) = [1 1 1];
  colormap(cm);
  
  hold on;
  opts = {'color',[0.5 0.5 0.5],'linewidth',3};
  plot_ellipse(show_ell,opts);
  
  % probability colorbar
  ytick = linspace(1,8,15);
  cba = colorbar('box','off','ylim', [1 8],'ytick',ytick(2:2:end-1), ...
		 'yticklabel',round(100*linspace(1/8,1,7))/100,'xcolor','w');

  % misalignment on the colorbar must be fixed manually. the indices of
  % the cdata of the child of the colorbar must be increased by one. 
  cdat = get(get(cba,'children'),'cdata');
  cdat = cdat+1;
  set(get(cba,'children'),'cdata',cdat);
  
  if(printfig)
    print -depsc2 ../FIGURES/macaqueV1overlap.eps
  end
  
  % generate the percent overlaps
  
  % generate combinations
  ave_overlap = [];
  for(s=2:length(samples))
    comb = combnk(1:length(samples),s);
  
    over = [];
    
    % get a single percentage overlap
    for(c=1:size(comb,1))
      subset = indiv_map(:,:,comb(c,:));
      over(end+1) = 100*sum(sum(prod(subset,3)))*size(comb,2)/sum(subset(:));
    end
    
    ave_overlap(end+1) = sum(over)/size(comb,1);
  end

  figure,h=bar(ave_overlap,'edgecolor','none','linestyle','none','facecolor','k');
  colormap(gray);
   
  %p = get(h,'children');
  %cm2 = cm(round((1:length(count)-2)/(length(count)-2).*size(cm,1)),:);
  %set(p,'facevertexcdata',(1:length(count)-2)');
  %colormap(cm2);
  %
  %set(gca,'color',[0 0 0]);
  %set(gcf,'color',[0 0 0]);
  %set(gcf,'inverthardcopy','off');
  xlabel('group size','fontweight','bold','fontsize',18);
  set(gca,'xticklabel',2:length(count)-1);
  %set(gca,'xcolor',[0.99 0.99 0.99]);
  ylabel('average % overlap','fontweight','bold','fontsize',18);
  %set(gca,'ycolor',[0.99 0.99 0.99]);
  set(gca,'fontweight','bold');
  set(gca,'ygrid','on');
  
  if(printfig)
    print -depsc2 ../FIGURES/macaqueV1percent.eps
  end
  
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/macaqueOverlapFigs.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
