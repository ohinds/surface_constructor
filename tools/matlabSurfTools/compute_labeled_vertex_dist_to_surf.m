function distances = compute_labeled_vertex_dist_to_surf(ref_surf, ...
                                                         labels, ...
                                                         dest_surf)
  distances = inf(length(labels), 1);
  centroids = compute_face_centroids(dest_surf);
  num_centroids_to_test = 100;

  for i=1:length(labels)
    if ~mod(i, round(length(labels) / 100))
      if round(i / length(labels) * 100) ~= 1
         fprintf('\b\b\b\b');
      end
      fprintf('%3d%%', round(i / length(labels) * 100));
    end

    closest_centroids = zeros(size(dest_surf.faces, 1), 1);
    for j=1:size(dest_surf.faces)
      closest_centroids(j) = norm(centroids(j, :) - ...
                                  ref_surf.vertices(labels(i), :));
    end

    [closest_centroids inds] = sortrows(closest_centroids);

    for j=1:num_centroids_to_test
      index = inds(j);
      verts = dest_surf.vertices(dest_surf.faces(index, :), :);
      dist = pointTriangleDistance(verts, ref_surf.vertices(labels(i), :));
      if dist < distances(i)
         distances(i) = dist;
      end
    end
  end
  fprintf('\n');

end

function centroids = compute_face_centroids(surf)
  centroids = zeros(size(surf.faces, 1), 3);

  for f=1:size(surf.faces, 1)
      centroids(f, :) = mean(surf.vertices(surf.faces(f, :), :));
  end
end
