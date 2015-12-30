% Oliver Hinds <oph@bu.edu>
% 2006-03-06

function show_disp_map(disp_map,show_ell,boundary_mask,xaxstr,unitstr,positive,numbins,thresh)

  if(nargin < 6)
    positive = 0;
  end

  if(nargin < 7)
    numbins = 11;
  end

  if(nargin < 8)
    nothresh = 1;
  else
    nothresh = 0;
  end


  %threshold
  if(~nothresh)
    disp_map(find(disp_map(:) > thresh)) = thresh;
    if(~positive)
      disp_map(find(disp_map(:) < -thresh)) = -thresh;
    end
  end


  [r,c] = find(disp_map > 0);
  border = 5;
  disp_map(find(flipud(boundary_mask)==0)) = -inf;

  figure,imagesc(disp_map), axis off, axis image, axis tight;

  hold on;
  %opts = {'color',[0.5 0.5 0.5],'linewidth',3};
  %plot_ellipse(show_ell,opts);

  if(positive)
    cm = hot;
    cm = cm(1:end-3,:);
  else
    cm = jet;
  end

  cm(1,:) = [1 1 1];
  colormap(cm);

  mc = disp_map(isfinite(disp_map(:)));

  mx = max(abs(mc));

  if(~positive)
    caxis([-(mx+2*mx/(size(cm,1)-2)) mx]);
    cba = colorbar('ylim',[-mx mx],'position',[0.7617 0.3938 0.0380 0.5255]);
  else
    caxis([-mx/(size(cm,1)-2) mx]);
    cba = colorbar('ylim',[0 mx],'position',[0.7617 0.3938 0.0380 0.5255]);
  end

  %colorbar_label_text(gcf, unitstr);

  % misalignment on the colorbar must be fixed manually. the indices of
  % the cdata of the child of the colorbar must be increased by one.
  tmwc = findall(get(cba,'children'),'tag','TMW_COLORBAR');
  set(tmwc,'cdata',get(tmwc,'cdata')+1);

  set(gca,'ylim',[min(r)-border max(r)+border]);
  set(gca,'xlim',[min(c)-border max(c)+border]);
  set(gca,'position',[0 0.25 0.775 0.815]);

  % mean curvature histogram
  numbins = 11;

  if(positive)
    centers = linspace(-(mx/(numbins+1)),mx+(mx/(numbins+1)),numbins+1);
  else
    centers = linspace(-mx-(mx/(numbins+1)),mx+(mx/(numbins+1)),numbins+2);
  end

  ax2 = axes('plotboxaspectratio',[1 0.3 1],'position',[0.1966 -0.1695 0.4624 0.8150]);
  n=hist(ax2,mc,centers);
  set(gca,'xlim',[-mx mx]);
  bh = bar(centers, n, 1);
  set(get(bh, 'Children'), 'FaceVertexCData', centers.')

  xlabel(xaxstr);
  ylabel('count');

  if(positive)
    set(gca,'xlim',[-(mx/(numbins+1)) mx]);
  else
    set(gca,'xlim',[-mx mx]);
  end

  set(gca,'plotboxaspectratio',[1 0.3 1]);
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/show_disp_map.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
