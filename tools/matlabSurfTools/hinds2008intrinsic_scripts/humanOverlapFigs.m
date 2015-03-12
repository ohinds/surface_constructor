% overlaps the v1 estimates found, compuytes a percentage overlap,
% as well as average flattening error after alignment and average
% curvature after alignment
% 
% Oliver Hinds <oph@bu.edu>
% 2005-10-31

function [map, count, ave_ellipse]= humanOverlapFigs(samples,printfig,postfix)
  % parameters for overlap computation
    
  % size of rectangle to compute overlap for, in ratio of ellipse size
  rectSize = 1.2;
  
  % number of spatial samples on a side of the rectangle to compute overlap
  spatialSamples = 1000;
  
  if(nargin < 2)
    printfig = 0;
  end

  if(nargin < 3)
    postfix = '';
  end

  % load the display stuff
  verts = {};
  v1boundary = {};
  ellipses = {};
  labels = {};
  aspects = [];
  for(s=1:length(samples))
    eval(sprintf('load display%s.mat',samples{s}));
    eval(sprintf('load surfStats%s.mat',samples{s}));        
  
    % normalize the vertices into the ellipse of the surface
    eval(sprintf('v = smoothedFlatSurf%s.vertices;',samples{s}));
    eval(sprintf('v1bv = V1smoothedFlatSurf%s.vertices(boundaryVertices(V1smoothedFlatSurf%s),:);',samples{s},samples{s}));
    eval(sprintf('l = smoothedFlatSurf%s.vertexLabels;',samples{s}));
    eval(sprintf('e = ellipse%s;',samples{s}));

    verts{end+1} = v;
    v1boundary{end+1} = v1bv;
    labels{end+1} = l;
    ellipses{end+1} = e;
    aspects(end+1) = e.a/e.b;
  end
  clear v v1bv l e;
    

  % get the average ellipse
  ave_ellipse.a = 1.0;
  ave_ellipse.b = mean(1./aspects);
  ave_ellipse.r = 0;
  ave_ellipse.tx = 0;
  ave_ellipse.ty = 0;
  ave_aspect = ave_ellipse.a/ave_ellipse.b;

  fprintf(['the aspect ratio of the average best fitting ellipse is' ...
	   ' %f\n'],mean(aspects));
  
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

    v1bc = v1boundary{s};
    v1bc = (inv([cos(e.r) sin(e.r); -sin(e.r) cos(e.r)]) ...
			 * (v1bc(:,1:2)-repmat([e.tx e.ty]',1, ...
					      size(v1bc,1))')')'./e.a;
    v1bc = v1bc*scale;
    v1boundary{s} = v1bc;
  end
  
  % generate spatial map of overlap
  map = zeros(spatialSamples);
  indiv_map = zeros(spatialSamples,spatialSamples,length(samples));
  count = zeros(length(samples)+1,1);
  [X,Y] = meshgrid(linspace(-rectSize,rectSize,spatialSamples));
  
  % get the counts for each sample
  for(s=1:length(samples))
    v = v1boundary{s};
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
  
  % limit the figure to just nonzero rows and cols
  [r,c] = find(map > 0);  
  
  %disp_map = map(min(r):max(r),min(c):max(c));
  disp_map = flipud(map);

  % get a transformed ellipse for this image
  show_ell.a = spatialSamples/(rectSize*2);
  show_ell.b = ave_ellipse.b*show_ell.a;
  show_ell.r = 0;
  %show_ell.tx = size(disp_map,1)/2-1;
  %show_ell.ty = size(disp_map,2)/2-1;
  show_ell.tx = spatialSamples/2;
  show_ell.ty = spatialSamples/2;
  
  % print the percent blurring 
  indiv_count = squeeze(sum(sum(indiv_map)));
  per_blur = 100*(sum(map(:) > 0)-mean(indiv_count))/mean(indiv_count);
  fprintf('human percent blur is %0.2f%%\n',per_blur);
  

  figure,imagesc(disp_map), axis off, axis image, axis tight;
  %set(gcf,'color',[0 0 0]);
  %set(gcf,'inverthardcopy','off');
  
  % build a good colormap;
  n = length(samples);
  cm = hot(n+4);
  cm = cm(1:end-3,:);
  cm(1,:) = [1 1 1];
  cm(end,3) = .5;
  colormap(cm);
  
  hold on;
  opts = {'color',[0.5 0.5 0.5],'linewidth',3};
  plot_ellipse(show_ell,opts);

  % probability colorbar
  ytick = linspace(1,n,2*n+1);
  cb = colorbar('ylim', [1 n],'ytick',ytick(2:2:end-1),'yticklabel', ...
	       round(100*linspace(1/n,1,n))/100);
  yticklab = get(cb,'yticklabel');
  yticklab(end,:) = '1.0';
  set(cb,'yticklabel',yticklab);
  
  set(gca,'ylim',[min(r) max(r)]);
  set(gca,'xlim',[min(c) max(c)]);

  if(printfig)
    print('-depsc2',['../FIGURES/humanV1overlap' postfix '.eps']);
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

  fprintf('human overlap for %d samples is %0.1f%%\n',...
	  length(samples),ave_overlap(end));

  figure,h=bar(ave_overlap,'edgecolor','none','linestyle','none', ...
	       'facecolor','k');
  colormap(gray);
   
  %p = get(h,'children');
  %cm2 = cm(round((1:length(count)-2)/(length(count)-2).*size(cm,1)),:);
  %set(p,'facevertexcdata',(1:length(count)-2)');
  %colormap(cm2);
  
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
    print('-depsc2',['../FIGURES/humanV1percent' postfix '.eps']);
  end

return;

