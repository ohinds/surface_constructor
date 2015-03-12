function show_disp_map(disp_map,boundary_mask,xaxstr,unitstr)

  [r,c] = find(disp_map > 0);  
  border = 5;
  disp_map(find(flipud(boundary_mask)==0)) = -inf;
  
  
  % get a transformed ellipse for this image
  show_ell.a = spatial_samples/(rect_size*2);
  show_ell.b = ave_ellipse.b*show_ell.a;
  show_ell.r = 0;
  %show_ell.tx = size(disp_map,1)/2-1;
  %show_ell.ty = size(disp_map,2)/2-1;
  show_ell.tx = spatial_samples/2;
  show_ell.ty = spatial_samples/2;
    
  figure,imagesc(disp_map), axis off, axis image, axis tight;
  
  hold on;
  opts = {'color',[0.5 0.5 0.5],'linewidth',3};
  plot_ellipse(show_ell,opts);
  
  cm = jet;
  cm(1,:) = [1 1 1];
  colormap(cm);
  
  mc = disp_map(isfinite(disp_map(:)));
  mx = max(abs(mc));
  caxis([-(mx+2*mx/(size(cm,1)-2)) mx]);
  
  cba = colorbar('ylim',[-mx mx],'position',[0.7617 0.3938 0.0380 0.5255]);
  colorbar_label_text(gcf, '%+0.2f mm^{-1}');
  
  % misalignment on the colorbar must be fixed manually. the indices of
  % the cdata of the child of the colorbar must be increased by one. 
  tmwc = findall(get(cba,'children'),'tag','TMW_COLORBAR');
  set(tmwc,'cdata',get(tmwc,'cdata')+1);
  
  set(gca,'ylim',[min(r)-border max(r)+border]);
  set(gca,'xlim',[min(c)-border max(c)+border]);
  set(gca,'position',[0 0.25 0.775 0.815]);
  
  % mean curvature histogram
  numbins = 11;
  centers = linspace(-mx-(mx/(numbins+1)),mx+(mx/(numbins+1)),numbins+2);
  
  ax2 = axes('plotboxaspectratio',[1 0.3 1],'position',[0.1966 -0.1695 0.4624 0.8150]);
  n=hist(ax2,mc,centers);
  set(gca,'xlim',[-mx mx]);
  bh = bar(centers, n, 1);
  set(get(bh, 'Children'), 'FaceVertexCData', centers.')
  
  ylabel('count');
  
  set(gca,'xlim',[-mx mx]);
  set(gca,'plotboxaspectratio',[1 0.3 1]);
