function distances = compute_labeled_vertex_dist_to_surf(ref_surf, ...
                                                         labels, ...
                                                         dest_surf)
  distances = inf(length(labels), 1);
  for i=1:length(labels)
    for j=1:size(dest_surf.faces)
      verts = dest_surf.vertices(dest_surf.faces(j, :), :);
      dist = pointTriangleDistance(verts, ref_surf.vertices(labels(i), :));
      if dist < distances(i)
         distances(i) = dist;
      end
    end
  end

end
