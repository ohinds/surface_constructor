%Script gives a sample usage of the random walker function for image
%segmentation
%
%
%10/31/05 - Leo Grady

clear
close all

addpath('graphAnalysisToolbox-1.0');
addpath('/home/ohinds/projects/surface_constructor/tools/matlabSurfTools/');

%Read image
slices = 185:189;
[vol M] = load_mgh('/home/ohinds/z/mgh/ex_vivo_v1_recons/ex_vivo07/flash20_200um.mgz');
img = permute(vol(:, :, slices + 1), [2 1 3]);

[X Y Z]=size(img);

%read seeds from files

fp = fopen('/home/ohinds/z/mgh/ex_vivo_v1_recons/ex_vivo07/surfRecon/bf_ex_vivo07_mgh_sfn.ds');
s1x = [];
s1y = [];
s1z = [];
s2x = [];
s2y = [];
s2z = [];

tline = fgets(fp);
while ischar(tline)
  tline = fgets(fp);

  if length(tline) < 3
     continue
  end

  if strcmp(tline(1:3), 'fg:')
     x = sscanf(tline, 'fg: (%d, %d, %d)\n');
     if sum(x(3) == slices)
        s1x(end+1) = x(1) + 1;
        s1y(end+1) = x(2) + 1;
        s1z(end+1) = x(3) + 1 - slices(1);
     end
  end

  if strcmp(tline(1:3), 'bg:')
     x = sscanf(tline, 'bg: (%d, %d, %d)\n');
     if sum(x(3) == slices)
        s2x(end+1) = x(1) + 1;
        s2y(end+1) = x(2) + 1;
        s2z(end+1) = x(3) + 1 - slices(1);
    end
  end

end

%Apply the random walker algorithms
[mask,probabilities] = random_walker_3d(img,[sub2ind([X Y Z],s1y,s1x,s1z), ...
    sub2ind([X Y Z],s2y,s2x,s2z)],[ones(1, length(s1x)), 2 * ones(1, length(s2x))]);


seg_vol = zeros(size(vol));
seg_vol(:, :, slices) = permute(mask, [2 1 3]);
save_mgh(seg_vol, '/tmp/segvol.mgz', M);


% boundaries = bwboundaries(mask)
% keyboard
%
% disp_img = img;
% disp_img(mask == 1) = max(img(:));
% imagesc(disp_img);
% colormap(gray)
%
% [B,L,N,A] = bwboundaries(mask - 1);
% figure, imshow(img ./ max(img(:))); hold on;
% colors=['b' 'g' 'r' 'c' 'm' 'y'];
% for k=1:length(B)
%     boundary = B{k};
%     cidx = mod(k,length(colors))+1;
%     plot(boundary(:,2), boundary(:,1),...
%          colors(cidx),'LineWidth',2);
% end
%


%  %Display results
%  figure
%  imagesc(img);
%  colormap('gray')
%  axis equal
%  axis tight
%  axis off
%  hold on
%  plot(s1x,s1y,'g.','MarkerSize',24)
%  plot(s2x,s2y,'b.','MarkerSize',24)
%  title('Image with foreground (green) and background (blue) seeds')
%
%  figure
%  imagesc(mask)
%  colormap('gray')
%  axis equal
%  axis tight
%  axis off
%  hold on
%  plot(s1x,s1y,'g.','MarkerSize',24)
%  plot(s2x,s2y,'b.','MarkerSize',24)
%  title('Output mask');
%
%  figure
%  [imgMasks,segOutline,imgMarkup]=segoutput(img,mask);
%  imagesc(imgMarkup ./ max(imgMarkup(:)));
%  colormap('gray')
%  axis equal
%  axis tight
%  axis off
%  hold on
%  plot(s1x,s1y,'g.','MarkerSize',24)
%  plot(s2x,s2y,'b.','MarkerSize',24)
%  title('Outlined mask')
%
%  figure
%  imagesc(probabilities(:,:,1))
%  colormap('gray')
%  axis equal
%  axis tight
%  axis off
%  hold on
%  plot(s1x,s1y,'g.','MarkerSize',24)
%  plot(s2x,s2y,'b.','MarkerSize',24)
%  title(strcat('Probability at each pixel that a random walker released ', ...
%      'from that pixel reaches the foreground seed'));
