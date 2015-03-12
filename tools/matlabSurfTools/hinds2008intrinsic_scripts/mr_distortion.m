% mr_distortion shows the effect of gradient nonlinearity and
% susceptibility distortion on the geometry of the stria in contours.
%
% as of 2005-12-09, the vertex files loaded for this example are from ex_vivo22:
% uncorrected.verts = flash20_180um_2channel_NEG_run5.mgh, slice 156
% grad_corrected.verts = flash20_180um_2channel_NEG_run5_GRAD_UNWARP.mgh, slice 156
% opp_readout_uncorrected.verts = flash20_180um_2channel_POS_run6.mgh, slice 156
%
% Oliver Hinds <oph@bu.edu>
% 2005-12-07

function mr_distortion(printfig)
  
  if(nargin < 1)
    printfig = 0;
  end
  
  % whether to make lines for the different versions
  makelines = [0 1];
  
  % load the contours
  load('uncorrected.verts');

  %load('grad_corrected.verts');
  load flash20_180um_2channel_NEG_run5_slice156_GRAD_UNWARP.mat;
  grad_corrected = [R_gradunwarp' C_gradunwarp'];
  
  
  load('opp_readout_uncorrected.verts');
  scale = load('uncorrected_Mvxl2lph.scalar');
  trans = mean(uncorrected);
  
  %uncorrected = scale*(uncorrected-repmat(trans,size(uncorrected,1),1));
  %grad_corrected = scale*...
  %    (grad_corrected-repmat(trans,size(grad_corrected,1),1));
  %opp_readout_uncorrected = scale*...
  %    (opp_readout_uncorrected-repmat(trans,size(opp_readout_uncorrected,1),1));
  
  % compute the displacements
  %[d_grad p_grad] = contourDisplacement(uncorrected,grad_corrected);
  d_grad = (sum((grad_corrected-uncorrected).^2,2)).^(1/2);
  p_grad = grad_corrected;
  
  [d_susc p_susc] = contourDisplacement(uncorrected,opp_readout_uncorrected);
  
  % print the stats
  fprintf('gradient unwarping displacement: %0.3fmm +/- %0.4fmm\n',...
	  mean(scale*d_grad), sqrt(var(scale*d_grad)));
  fprintf('opposite readout polarity displacement: %0.3fmm +/- %0.4fmm\n',...
	  mean(scale*d_susc), sqrt(var(scale*d_susc)));
  
  % plot the uncorrected and corrected contours, 
  h(1) = figure;
  h(2) = figure;

  for(f=1:length(h))
    figure(h(f));
    im = imread('uncorrected.jpg');
    imshow(flipud(im));
    hold on;
    
    % make lines from the uncorrected to closest point on the corrected
    if(makelines(f))
      for(v=1:size(uncorrected,1))
	plot([uncorrected(v,1) p_grad(v,1)], [uncorrected(v,2) p_grad(v,2)],...
	     'w-');
	
	plot([uncorrected(v,1) p_susc(v,1)], [uncorrected(v,2) p_susc(v,2)],...
	     'w-');
      end      
    end
    
    % plot the contours themselves
    if(makelines(f))
      plot(uncorrected(:,1),uncorrected(:,2),'b.-','markersize',16);
      plot(grad_corrected(:,1),grad_corrected(:,2),'r.-','markersize',16);
      plot(opp_readout_uncorrected(:,1),opp_readout_uncorrected(:, ...
						  2),'g.-','markersize',16);
    else
      plot(uncorrected(:,1),uncorrected(:,2),'b-');
      plot(grad_corrected(:,1),grad_corrected(:,2),'r-');
      plot(opp_readout_uncorrected(:,1),opp_readout_uncorrected(:, 2),'g-');
    end    
    
    % plot the closest points on the corrected contours from the uncorrected
    if(makelines(f))
      plot(p_grad(:,1),p_grad(:,2),'ks');  
      plot(p_susc(:,1),p_susc(:,2),'ks');

    end

  end
  
  figure(h(1));
  
  xlim = [283 376];
  ylim = [233 344];
  set(gca,'xlim',xlim);
  set(gca,'ylim',ylim);

  leg = {'pos read-out', 'grad unwarp', 'neg read-out'};
  legend(leg,'location',[0.247 0.77 0.296 0.153]');
%  keyboard
  xlabel('distance (mm)');
  ylabel('distance (mm)');
  
  axis on;
  
  % make axis ticks and tick labels
  tick_freq = 3; %mm
  dx = diff(xlim);
  xticks = mean(xlim)+(-floor(dx*scale/2):tick_freq:floor(dx*scale/2))/scale;
  set(gca,'xtick',xticks);
  set(gca,'xticklabel',-floor(dx*scale/2):tick_freq:floor(dx*scale/2));
  
  dy = diff(ylim);
  yticks = mean(ylim)+(-floor(dy*scale/2):tick_freq:floor(dy*scale/2))/scale;
  set(gca,'ytick',yticks);
  set(gca,'yticklabel',floor(dy*scale/2):-tick_freq:-floor(dy*scale/2));

  
  
  %% now make a zoomed in version 

  figure(h(2));
  
  xlim_box = [337 369];
  ylim_box = [252 289];
  set(gca,'xlim',xlim_box);
  set(gca,'ylim',ylim_box);

  xlabel('distance (mm)');
  ylabel('distance (mm)');
  
  axis on;
  
  % make axis ticks and tixk labels
  tick_freq = 1; %mm
  dx = diff(xlim_box);
  xticks = mean(xlim_box)+(-floor(dx*scale/2):tick_freq:floor(dx*scale/2))/scale;
  set(gca,'xtick',xticks);
  set(gca,'xticklabel',-floor(dx*scale/2):tick_freq:floor(dx*scale/2));
  
  dy = diff(ylim_box);
  yticks = mean(ylim_box)+(-floor(dy*scale/2):tick_freq:floor(dy*scale/2))/scale;
  set(gca,'ytick',yticks);
  set(gca,'yticklabel',floor(dy*scale/2):-tick_freq:-floor(dy*scale/2));
  
  
  % make a box on the big version showing where the small version
  % came from
  figure(h(1));
  
  line([xlim_box(1) xlim_box(1)],[ylim_box(1) ylim_box(2)],'linewidth',2,'color','w');
  line([xlim_box(1) xlim_box(2)],[ylim_box(2) ylim_box(2)],'linewidth',2,'color','w');
  line([xlim_box(2) xlim_box(2)],[ylim_box(2) ylim_box(1)],'linewidth',2,'color','w');
  line([xlim_box(2) xlim_box(1)],[ylim_box(1) ylim_box(1)],'linewidth',2,'color','w');
  
  if(printfig)
%    fprintf('select File->Page Setup->Use manual size and position\n');
%    pause;
    
    figure(h(1));
    print -depsc2 ../FIGURES/mr_distortion.eps

    figure(h(2));
    print -depsc2 ../FIGURES/mr_distortion_box.eps
    
  end
  
return

