% distortion_correction calculates the effect of gradient
% nonlinearity and susceptibility distortion on the geometry of the
% stria in contours. 
%
% as of 2005-12-09, the vertex files loaded for this example are from
% ex_vivo22: 
% uncorrected.verts = flash20_180um_2channel_NEG_run5.mgh,
% slice 156 
% grad_corrected.verts = flash20_180um_2channel_NEG_run5_GRAD_UNWARP.mgh, 
% slice 156
% opp_readout_uncorrected.verts = flash20_180um_2channel_POS_run6.mgh,
% slice 156
%
% Oliver Hinds <oph@bu.edu>
% 2005-12-07

function distortion_correction(printfig)

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
	  mean(scale*d_susc/2), sqrt(var(scale*d_susc/2)));
  
  % plot the uncorrected and corrected contours, 
  figure;
  
  im = imread('uncorrected.jpg');
  imshow(flipud(im));
  hold on;
  
  plot(uncorrected(:,1),uncorrected(:,2),'b.-');
  plot(grad_corrected(:,1),grad_corrected(:,2),'r.-');
  plot(opp_readout_uncorrected(:,1),opp_readout_uncorrected(:,2),'g.-');
  
  % plot the closest points on the corrected contours from the uncorrected
  plot(p_grad(:,1),p_grad(:,2),'ks');  
  plot(p_susc(:,1),p_susc(:,2),'ks');

  % make lines from the uncorrected to closest point on the corrected
  for(v=1:size(uncorrected,1))
    plot([uncorrected(v,1) p_grad(v,1)], [uncorrected(v,2) p_grad(v,2)], 'k');

    plot([uncorrected(v,1) p_susc(v,1)], [uncorrected(v,2) p_susc(v,2)], 'k');
  end
  
  xlim = [285 378];
  ylim = [232 346];
  set(gca,'xlim',xlim);
  set(gca,'ylim',ylim);

  leg = {'uncorrected', 'gradient unwarped', 'opposite readout'};
  legend(leg,'location','northwest');
  
  
  xlabel('distance (mm)');
  ylabel('distance (mm)');
  
  axis on;
  
  % make axis ticks and tixk labels
  dx = diff(xlim);
  xticks = mean(xlim)+(-floor(dx*scale/2):2:floor(dx*scale/2))/scale;
  set(gca,'xtick',xticks);
  set(gca,'xticklabel',-floor(dx*scale/2):2:floor(dx*scale/2));
  
  dy = diff(ylim);
  yticks = mean(ylim)+(-floor(dy*scale/2):2:floor(dy*scale/2))/scale;
  set(gca,'ytick',yticks);
  set(gca,'yticklabel',-floor(dy*scale/2):2:floor(dy*scale/2));
return

