% computes spatial maps of average mean and gaussian curvature
% 
% Oliver Hinds <oph@bu.edu>
% 2006-02-20

function average_curvature(samples,printfig)
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
  mean_curvs = {};
  gaus_curvs = {};
  for(s=1:length(samples))
    eval(sprintf('load display%s.mat',samples{s}));
    eval(sprintf('load surfStats%s.mat',samples{s}));        
  
    % normalize the vertices into the ellipse of the surface
    eval(sprintf('fs = smoothedFlatSurf%s;',samples{s}));
    eval(sprintf('v = smoothedFlatSurf%s.vertices;',samples{s}));
    eval(sprintf('e = ellipse%s;',samples{s}));

    % save the mean curvature per vertex
    try
      eval(sprintf('mc = meanCurv%s;',samples{s}));
    catch
      fprintf('FAILED TO LOAD MEAN CURVATURE CDATA FOR %s, IGNORING!!!\n',samples{s});
      mc = zeros(size(v,1),1);
    end
    
    % save the area error per vertex
    try
      eval(sprintf('gc = gaussCurv%s;',samples{s}));
    catch
      fprintf('FAILED TO LOAD GAUSSIAN CURVATURE CDATA FOR %s, IGNORING!!!\n',samples{s});
      gc = zeros(size(v,1),1);
    end
    
    % save the vars
    flat_surfs{end+1} = fs;
    verts{end+1} = v;
    ellipses{end+1} = e;
    aspects(end+1) = e.a/e.b;
    mean_curvs{end+1} = mc;
    gaus_curvs{end+1} = gc;
  end
  clear v fs e mc gc;
    

  % get the average ellipse
  ave_ellipse.a = 1.0;
  ave_ellipse.b = mean(1./aspects);
  ave_ellipse.r = 0;
  ave_ellipse.tx = 0;
  ave_ellipse.ty = 0;
  ave_aspect = ave_ellipse.a/ave_ellipse.b;
  
  % get a transformed ellipse to show 
  show_ell.a = spatial_samples/(rect_size*2);
  show_ell.b = ave_ellipse.b*show_ell.a;
  show_ell.r = 0;
  %show_ell.tx = size(disp_map,1)/2-1;
  %show_ell.ty = size(disp_map,2)/2-1;
  show_ell.tx = spatial_samples/2;
  show_ell.ty = spatial_samples/2;
    
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
  [curv_maps boundary_mask] = computeAverageMap(flat_surfs,...
					       {mean_curvs, gaus_curvs},...
					       spatial_samples,rect_size);

  
  %%% mean curvature map
  disp_map = flipud(curv_maps{1}.meanmap);  
  
  % show the disp map
  show_disp_map(disp_map,show_ell,boundary_mask,'mean curvature (mm^{-1})','%+0.2f mm^{-1}',0);
  
  if(printfig)
    print -depsc2 ../FIGURES/humanV1ave_mean_curv.eps
  end

  % variance map
  disp_map = flipud(curv_maps{1}.sdmeanmap);  

  % prints stats of the sd
  sdval = curv_maps{1}.sdmeanmap(find(boundary_mask(:)~=0));
  fprintf('mean curvature standard deviation is %0.2f +/- %0.3f\n',...
	  mean(sdval),sqrt(var(sdval)));  
  
  show_disp_map(disp_map,show_ell,boundary_mask,'mean curvature standard deviation (mm^{-1})','%+0.2f mm^{-1}',1,20);
  
  if(printfig)
    print -depsc2 ../FIGURES/humanV1ave_mean_curv_var.eps
  end

%  %%% mean radius of curvature map
%  disp_map = flipud(curv_maps{1}.meanradmap);  
%  
%  % show the disp map
%  show_disp_map(disp_map,show_ell,boundary_mask,'mean radius of curvature (mm)','%+0.2f mm^{-1}',0);
%  
%  if(printfig)
%    print -depsc2 ../FIGURES/humanV1ave_mean_rad_curv.eps
%  end
%
%  % variance map
%  disp_map = flipud(curv_maps{1}.sdmeanradmap);  
%
%  % prints stats of the sd
%  sdval = curv_maps{1}.sdmeanradmap(find(boundary_mask(:)~=0));
%  fprintf('mean radius of curvature standard deviation is %0.2f +/- %0.3f\n',...
%	  mean(sdval),sqrt(var(sdval)));  
%  
%  show_disp_map(disp_map,show_ell,boundary_mask,'mean radius of curvature standard deviation (mm)','%+0.2f mm^{-1}',1,20);
%  
%  if(printfig)
%    print -depsc2 ../FIGURES/humanV1ave_mean_rad_curv_var.eps
%  end
%
  %%% average gaussian curvature
  disp_map = flipud(curv_maps{2}.meanmap);
  
  % limit the figure to just nonzero rows and cols
  show_disp_map(disp_map,show_ell,boundary_mask,'Gaussian curvature (mm^{-2})','%+0.2f mm^{-2}',0);
  
  if(printfig)
    print -depsc2 ../FIGURES/humanV1ave_gaus_curv.eps
  end

  %%% average gaussian curvature
  disp_map = flipud(curv_maps{2}.sdmeanmap);

  % prints stats of the sd
  sdval = curv_maps{2}.sdmeanmap(find(boundary_mask(:)~=0));
  fprintf('gaussian curvature standard deviation is %0.2f +/- %0.3f\n',...
	  mean(sdval),sqrt(var(sdval)));
  
  % limit the figure to just nonzero rows and cols
  show_disp_map(disp_map,show_ell,boundary_mask,'Gaussian curvature standard deviation (mm^{-2})','%+0.2f mm^{-2}',1,20,0.25);

  if(printfig)
    print -depsc2 ../FIGURES/humanV1ave_gaus_curv_var.eps
  end

return;

