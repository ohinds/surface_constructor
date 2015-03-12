% estimate3Daspect attempts to characterise the aspect ratio of a
% shape in 3D via estimating the ratio of the furthest points to
% various measures.
%
% aspect = estimate3Daspect(surf,dm,boundaryVertices);
%
% Oliver Hinds <oph@bu.edu>
% 2006-03-31

function [aspect_ratio_3D major_axis_len minor_axis_len] = ...
      estimate3Daspect(flatSurfStruct,dm,ellipse)

  if(nargin < 3)
    bv = boundaryVerticesFromLabels(flatSurfStruct,1);

    % find the two vertices with the maximum 3D distance
    major_axis_verts = findMajorAxisFromMaxLen(dm,bv);
    minor_axis_verts = findMinorAxisFromHalfLen(dm,bv,major_axis_verts);
  else
    bv = boundaryVerticesFromLabels(flatSurfStruct,0);
    major_axis_verts = findMajorAxisFromEllipse(flatSurfStruct,bv,ellipse);
    minor_axis_verts = findMinorAxisFromEllipse(flatSurfStruct,bv,ellipse);    
  end

  major_axis_len = dm(major_axis_verts(1),major_axis_verts(2));
  minor_axis_len = dm(minor_axis_verts(1),minor_axis_verts(2));
  aspect_ratio_3D = major_axis_len/minor_axis_len;
return

function end_points = findMajorAxisFromEllipse(surfStruct,bv,ellipse)
  % find the end points of the major axis of the ellipse
  ell_end_pts = [-1 0; 1 0];
  ell_end_pts = ([cos(ellipse.r) sin(ellipse.r); 
		 -sin(ellipse.r) cos(ellipse.r)]...
      * (ell_end_pts.*ellipse.a)' ...
      +repmat([ellipse.tx ellipse.ty]',1,2))';

  % find the boundary verts closest to the end points of the major axis
  min_bv = [-1 -1];
  min_dist = [Inf Inf];
  for(i=1:length(bv))
    cur_dist(1) = sum((surfStruct.vertices(bv(i),1:2)-ell_end_pts(1,:)).^2);
    cur_dist(2) = sum((surfStruct.vertices(bv(i),1:2)-ell_end_pts(2,:)).^2);
    
    if(cur_dist(1) < min_dist(1))
      min_bv(1) = i;
      min_dist(1) = cur_dist(1);
    end

    if(cur_dist(2) < min_dist(2))
      min_bv(2) = i;
      min_dist(2) = cur_dist(2);
    end
  end

  end_points = bv(min_bv);
return

function end_points = findMinorAxisFromEllipse(surfStruct,bv,ellipse)
  % find the end points of the minor axis of the ellipse
  ar = ellipse.b/ellipse.a;
  ell_end_pts = [0 -ar; 0 ar];
  ell_end_pts = ([cos(ellipse.r) sin(ellipse.r); 
		 -sin(ellipse.r) cos(ellipse.r)]...
      * (ell_end_pts.*ellipse.a)' ...
      +repmat([ellipse.tx ellipse.ty]',1,2))';

  % find the boundary verts closest to the end points of the minor axis
  min_bv = [-1 -1];
  min_dist = [Inf Inf];
  for(i=1:length(bv))
    cur_dist(1) = sum((surfStruct.vertices(bv(i),1:2)-ell_end_pts(1,:)).^2);
    cur_dist(2) = sum((surfStruct.vertices(bv(i),1:2)-ell_end_pts(2,:)).^2);
    
    if(cur_dist(1) < min_dist(1))
      min_bv(1) = i;
      min_dist(1) = cur_dist(1);
    end

    if(cur_dist(2) < min_dist(2))
      min_bv(2) = i;
      min_dist(2) = cur_dist(2);
    end
  end

  end_points = bv(min_bv);
return

function end_points = findMajorAxisFromMaxLen(dm,bv)
  % find the largest entry in the dm for any pair of boundary
  % vertices
  end_points = [0 0];
  max_dist = -Inf;
  for(i=1:length(bv)-1)
    for(j=i+1:length(bv))
      if(isfinite(dm(bv(i),bv(j))) & dm(bv(i),bv(j)) > max_dist)
	end_points = [bv(i) bv(j)];
	max_dist = dm(bv(i),bv(j));
      end
    end    
  end
return

function end_points = findMinorAxisFromHalfLen(dm,bv,major_axis_end_points)
  % find the mid points of the distance along the boundary in both
  % directions from the major axis end points
  major_axis_bv_ind(1) = find(bv == major_axis_end_points(1));
  major_axis_bv_ind(2) = find(bv == major_axis_end_points(2));
  cur_v = major_axis_bv_ind(1)+1;
  accum_dist = dm(bv(cur_v-1),bv(cur_v));
  
  % find the cummulative distance for each vertex along the border
  while(cur_v ~= major_axis_bv_ind(1))
    cur_v = cur_v+1;
    if(cur_v > length(bv))
      cur_v = 1;
      accum_dist(end+1) = accum_dist(end) + dm(bv(end),bv(1));
    else
      accum_dist(end+1) = accum_dist(end) + dm(bv(cur_v-1),bv(cur_v));
    end
  end

  border_len(1) = accum_dist(major_axis_bv_ind(2));
  border_len(2) = accum_dist(end) - border_len(1);

  % find the vertices nearest the middle of the border

  % upper border
  upper_pts(1) = find(accum_dist<border_len(1)/2,1,'last');
  upper_pts(2) = find(accum_dist>border_len(1)/2,1,'first');
  [dist upper_pts_ind] = min(abs(upper_pts-border_len(1)/2));
  end_points(1) = upper_pts(upper_pts_ind);

  % lower border
  lower_pts(1) = find(accum_dist<border_len(1)+border_len(2)/2,1,'last');
  lower_pts(2) = find(accum_dist>border_len(1)+border_len(2)/2,1,'first');
  [dist lower_pts_ind] = min(abs(lower_pts-border_len(1)+border_len(2)/2));
  end_points(2) = lower_pts(lower_pts_ind);
return
