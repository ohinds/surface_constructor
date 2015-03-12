% computes spatial maps of distance and area flattening distortions 
% 
% Oliver Hinds <oph@bu.edu>
% 2006-02-20

function flattening_distortion(samples,printfig)
  % parameters for map computation
  spatial_samples = 100;
  rect_size = 1.75;
  
  if(nargin < 2)
    printfig = 0;
  end

  % load the display stuff
  flat_surfs = {};
  verts = {};
  ellipses = {};
  aspects = [];
  dist_errs = {};
  area_errs = {};
  for(s=1:length(samples))
    eval(sprintf('load display%s.mat',samples{s}));
    eval(sprintf('load surfStats%s.mat',samples{s}));        
  
    % normalize the vertices into the ellipse of the surface
    eval(sprintf('fs = smoothedFlatSurf%s;',samples{s}));
    eval(sprintf('v = smoothedFlatSurf%s.vertices;',samples{s}));
    eval(sprintf('e = ellipse%s;',samples{s}));

    % save the distance error per vertex
    try
      eval(sprintf('fe = errcdata%s;',samples{s}));
    catch
      fprintf('FAILED TO LOAD ERROR CDATA FOR %s, IGNORING!!!\n',samples{s});
      fe = zeros(size(v,1),1);
    end
    
    % save the area error per vertex
    try
      eval(sprintf('ae = area_errcdata%s;',samples{s}));
    catch
      fprintf('FAILED TO LOAD AREA ERROR CDATA FOR %s, IGNORING!!!\n',samples{s});
      ae = zeros(size(v,1),1);
    end
    
    % save the vars
    flat_surfs{end+1} = fs;
    verts{end+1} = v;
    ellipses{end+1} = e;
    aspects(end+1) = e.a/e.b;
    dist_errs{end+1} = fe;
    area_errs{end+1} = ae;
  end
  clear v e fe ae;
    

  % get the average ellipse
  ave_ellipse.a = 1.0;
  ave_ellipse.b = mean(1./aspects);
  ave_ellipse.r = 0;
  ave_ellipse.tx = 0;
  ave_ellipse.ty = 0;
  ave_aspect = ave_ellipse.a/ave_ellipse.b;

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

    flat_surfs{s}.vertices = v;
  end
  
  %%% compute average error maps
  [err_maps boundary_mask] = computeAverageMap(flat_surfs,{dist_errs, ...
		    area_errs}, spatial_samples,rect_size);

  %%% distance distortion map
  dist_err_map = err_maps{1}.medianmap;
  
  % threshold the error map
  %thresh = 40;
  %num_thresh = sum(map(:) > thresh);
  %map(find(map>thresh)) = thresh;
  %
  %fprintf('%d outliers were thresholded at %d%% disttening error\n',...
  %	  num_thresh,thresh);
  %

  % limit the figure to just nonzero rows and cols
  disp_map = flipud(dist_err_map);
  [r,c] = find(disp_map > 0);  
  border = 5;
  %disp_map(find(flipud(boundary_mask)==0)) = -inf;
  
  % get a transformed ellipse for this image
  show_ell.a = spatial_samples/(rect_size*2);
  show_ell.b = ave_ellipse.b*show_ell.a;
  show_ell.r = 0;
  %show_ell.tx = size(disp_map,1)/2-1;
  %show_ell.ty = size(disp_map,2)/2-1;
  show_ell.tx = spatial_samples/2;
  show_ell.ty = spatial_samples/2;
    
  
  figure,imagesc(disp_map), axis off, axis image, axis tight;
  
  cm = hot;
  cm(1,:) = [1 1 1];
  cm(end-8:end,:) = [];
  
  colormap(cm);
  
  hold on;
  opts = {'color',[0.5 0.5 0.5],'linewidth',3};
  plot_ellipse(show_ell,opts);

  cba = colorbar('ylim',[1 inf], 'ytick', [3:2:15], 'position', [0.7617 0.3938 0.0380 0.5255]);
  
  % add units to labels
  colorbar_label_text(gcf, '%0.0f %%');
  
  set(gca,'ylim',[min(r)-border max(r)+border]);
  set(gca,'xlim',[min(c)-border max(c)+border]);
  set(gca,'position',[0 0.25 0.775 0.815]);
  
  
  % distance error histogram
  mx = max(abs(disp_map(:)));
  numbins = 20;
  centers = linspace(0, mx, numbins);
  
  disp_map(find(flipud(boundary_mask)==0)) = -inf;
  dd = disp_map(boundary_mask(:)~=0);

  ax2 = axes('plotboxaspectratio',[1 0.3 1],'position',[0.1966 -0.1695 0.4624 0.8150]);
  n=hist(ax2,dd,centers);
  bh = bar(centers, n, 1);
  set(get(bh, 'Children'), 'FaceVertexCData', centers.')

  %set(gca,'ylim',[0 20]);
  
  xlabel('distance distortion (%)');
  ylabel('count');

  set(gca,'xlim',[2 Inf]);
  set(gca,'ylim',[0 750]);

  set(gca,'plotboxaspectratio',[1 0.3 1]);

  if(printfig)
    print -depsc2 ../FIGURES/humanV1ave_dist_err.eps
  end
  
  %%% average area error 
  area_err_map = err_maps{2}.medianmap;
  
  % threshold the error map
  thresh = 40;
  num_thresh = sum(area_err_map(:) > thresh);
  area_err_map(find(area_err_map>thresh)) = thresh;
  
  fprintf('%d outliers were thresholded at %d%% area error\n',...
  	  num_thresh,thresh);
  
 % limit the figure to just nonzero rows and cols
  disp_map = flipud(area_err_map);
  [r,c] = find(disp_map > 0);  
  border = 5;

  % get a transformed ellipse for this image
  show_ell.a = spatial_samples/(rect_size*2);
  show_ell.b = ave_ellipse.b*show_ell.a;
  show_ell.r = 0;
  %show_ell.tx = size(disp_map,1)/2-1;
  %show_ell.ty = size(disp_map,2)/2-1;
  show_ell.tx = spatial_samples/2;
  show_ell.ty = spatial_samples/2;
    
  
  figure,imagesc(disp_map), axis off, axis image, axis tight;
  
  cm = hot;
  cm(1,:) = [1 1 1];
  cm(end-8:end,:) = [];
  
  colormap(cm);
  
  hold on;
  opts = {'color',[0.5 0.5 0.5],'linewidth',3};
  plot_ellipse(show_ell,opts);

  cba = colorbar('ylim',[1 inf],'position',[0.7617 0.3938 0.0380 0.5255]);

  % add units to labels
  colorbar_label_text(gcf, '%0.0f%%');

  set(gca,'ylim',[min(r)-border max(r)+border]);
  set(gca,'xlim',[min(c)-border max(c)+border]);
  set(gca,'position',[0 0.25 0.775 0.815]);

  % area error histogram
  mx = max(abs(disp_map(:)));
  centers = linspace(0, mx, numbins);
  
  ad = disp_map(boundary_mask(:)~=0);
  ax2 = axes('plotboxaspectratio',[1 0.3 1],'position',[0.1966 -0.1695 0.4624 0.8150]);
  n=hist(ax2,ad,centers);
  bh = bar(centers, n, 1);
  set(get(bh, 'Children'), 'FaceVertexCData', centers.')

  %set(gca,'ylim',[0 20]);
  
  xlabel('area distortion (%)');
  ylabel('count');

  set(gca,'xlim',[2 Inf]);
  set(gca,'ylim',[0 325]);
  set(gca,'plotboxaspectratio',[1 0.3 1]);

  if(printfig)
    print -depsc2 ../FIGURES/humanV1ave_area_err.eps
  end
   
return;

