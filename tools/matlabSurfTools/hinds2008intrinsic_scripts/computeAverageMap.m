% computeAverageMap() takes aligned flat V1 surfaces and computes
% the spatial map of some cdata via averaging across samples
%
% FLATSURFS is a cell array of flat surfaces of each sample
% CDATA is 2D cell array, with the first dimension indexing the
%       type of cdata, and the second indexing sample. so you can
%       pass more than one feature to be computed at one, for
%       efficiency
% SPATIALSAMPLES is the number of pixels on a side of the map
%                generated
% RECTSIZE is the length of the window on a side to sample
%
% MAPS is a cell array of structs, each with meanmap, medianmap, and varmap
% images, one for each first dimension of CDATA
%
% Oliver Hinds <oph@bu.edu>
% 2006-02-20

function [maps boundary_mask] ...
      = computeAverageMap(flatSurfs,cdata,spatial_samples,rect_size)

  if(nargin < 2)
    fprintf('usage: maps = computeAverageMap(flatSurfs,cdata[,spatial_samples,rect_size])\n');
    return;
  end

  if(nargin < 3)
    spatial_samples = 100;
  end

  if(nargin < 4)
    rect_size = 2.0;
  end

  num_maps = length(cdata);
  num_samples = length(flatSurfs);

  % build the maps
  maps = {};
  for(m=1:num_maps)
    maps{m}.meanmap = zeros(spatial_samples);
    maps{m}.medianmap = zeros(spatial_samples);
    maps{m}.meansdmap = zeros(spatial_samples);
    maps{m}.sdmeanmap = zeros(spatial_samples);
    maps{m}.meanradmap = zeros(spatial_samples);

    for(s=1:num_samples)
      indiv_maps{m}{s}.raw = cell(spatial_samples,spatial_samples);
    end
  end
  count = zeros(spatial_samples,spatial_samples,num_samples);
  boundary_mask = zeros(spatial_samples,spatial_samples);

  % iterate over samples, building a sampled dist error map for
  % each
  for(s=1:num_samples)
    indiv_count = zeros(spatial_samples,spatial_samples);

    % find the pixel containing each vertex, accumulate cdata
    v = flatSurfs{s}.vertices;
    bv = flatSurfs{s}.vertices(boundaryVertices(flatSurfs{s}),:);

    % get the cdata for this sample
    cd = {};
    for(m=1:num_maps)
      cd{end+1} = cdata{m}{s};
    end

    % index each vertex into a pixel
    for(ind=1:size(v,1))
      i = floor((spatial_samples-1)/(2*rect_size)*v(ind,2)...
		+(spatial_samples/2+1));
      j = floor((spatial_samples-1)/(2*rect_size)*v(ind,1)...
		+(spatial_samples/2+1));

      indiv_count(i,j) = indiv_count(i,j)+1;

      % accumulate cdata for each map
      for(m=1:num_maps)
	indiv_maps{m}{s}.raw{i,j}(end+1) = cd{m}(ind);
      end
    end

    % find the pixels within the verts boundary that got no
    % votes due to nonuniform vertex density
    [zero_votes_r zero_votes_c] = find(indiv_count == 0);

    % find the zero vote pixels inside the vertex boundary
    Y = 2*rect_size*(zero_votes_r - (spatial_samples/2+1))/(spatial_samples-1);
    X = 2*rect_size*(zero_votes_c - (spatial_samples/2+1))/(spatial_samples-1);
    in_surf = inpolygon(X,Y,bv(:,1),bv(:,2));
    are_in_surf = find(in_surf == 1);

    % make votes for the empty pixels
    for(ind=1:length(are_in_surf))
      p = [X(are_in_surf(ind)) Y(are_in_surf(ind)) 0]';
      f = findFaceContainingPoint(flatSurfs{s},p);

      d = dist([p(1:2) v(flatSurfs{s}.faces(f,:),:)']);
      d = d(2:4,1)./sum(d(2:4,1));

      indiv_count(zero_votes_r(are_in_surf(ind)),...
		zero_votes_c(are_in_surf(ind))) = 1;

      % for each map
      for(m=1:num_maps)
	indiv_maps{m}{s}.raw{zero_votes_r(are_in_surf(ind)),...
		     zero_votes_c(are_in_surf(ind))} = ...
	    cd{m}(flatSurfs{s}.faces(f,:))'*d;
      end
    end

    count(:,:,s) = indiv_count ~= 0;

    % make the spatially sampled maps for this sample
    indiv_count(find(indiv_count == 0)) = 1;

    % build individual mean, median and variance maps
    for(m=1:num_maps)
      for(i=1:spatial_samples)
	for(j=1:spatial_samples)
	  if(isempty(indiv_maps{m}{s}.raw{i,j}))
	    indiv_maps{m}{s}.meanmap(i,j) = 0;
	    indiv_maps{m}{s}.medianmap(i,j) = 0;
	    indiv_maps{m}{s}.meansdmap(i,j) = 0;
	    indiv_maps{m}{s}.meanradmap(i,j) = 0;
	  else
	    indiv_maps{m}{s}.meanmap(i,j) = mean(indiv_maps{m}{s}.raw{i,j});
	    indiv_maps{m}{s}.medianmap(i,j) = median(indiv_maps{m}{s}.raw{i,j});
	    indiv_maps{m}{s}.meansdmap(i,j) = sqrt(var(indiv_maps{m}{s}.raw{i,j}));

	    rad_curv = indiv_maps{m}{s}.raw{i,j};
	    rad_curv(find(rad_curv == 0)) = eps;
	    rad_curv = 1./rad_curv;
	    
	    indiv_maps{m}{s}.meanradmap(i,j) = mean(rad_curv);
	  end
	end
      end
    end
  end
  
  % eliminate pixels with less than all votes
  count = sum(count,3);
  boundary_mask(find(count==num_samples))=1;



  % make the final maps by averaging over samples
  for(m=1:num_maps)
    for(s=1:num_samples)
      maps{m}.meanmap = maps{m}.meanmap + indiv_maps{m}{s}.meanmap;
      sdtmpmap(:,:,s) = indiv_maps{m}{s}.meanmap;
      maps{m}.medianmap = maps{m}.medianmap + indiv_maps{m}{s}.medianmap;
      maps{m}.meansdmap = maps{m}.meansdmap + indiv_maps{m}{s}.meansdmap;
      maps{m}.meanradmap = maps{m}.meanradmap + indiv_maps{m}{s}.meanradmap;
      sdradtmpmap(:,:,s) = indiv_maps{m}{s}.meanradmap;
    end
    
    % apply the boundary masks
    maps{m}.meanmap = maps{m}.meanmap./num_samples;
    maps{m}.meanmap(find(boundary_mask~=1)) = 0;

    maps{m}.medianmap = maps{m}.medianmap./num_samples;
    maps{m}.medianmap(find(boundary_mask~=1)) = 0;

    maps{m}.meansdmap = maps{m}.meansdmap./num_samples;
    maps{m}.meansdmap(find(boundary_mask~=1)) = 0;
    
    maps{m}.sdmeanmap = sqrt(var(sdtmpmap,0,3));
    maps{m}.sdmeanmap(find(boundary_mask~=1)) = 0;

    maps{m}.meanradmap = maps{m}.meanradmap./num_samples;
    maps{m}.meanradmap(find(boundary_mask~=1)) = 0;
  
    maps{m}.sdmeanradmap = sqrt(var(sdradtmpmap,0,3));
    maps{m}.sdmeanradmap(find(boundary_mask~=1)) = 0;
  end

return

function f = findFaceContainingPoint(flatSurf,p)
  found = 0;
  for(f=1:size(flatSurf.faces,1))
    if(inpolygon(p(1),p(2),flatSurf.vertices(flatSurf.faces(f,:),1),...
		 flatSurf.vertices(flatSurf.faces(f,:),2)))
      found = 1;
      break;
    end
  end

  if(found == 0)
    fprintf(['findFaceContainingPoint coulnt find a face containing' ...
	     ' the point\n']);
    keyboard
    f = -1;
  end
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/computeAverageMap.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
