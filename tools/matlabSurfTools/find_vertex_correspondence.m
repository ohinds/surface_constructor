function rpIndex = find_vertex_correspondence(ref_surf, dest_surf)

  rpIndex = zeros(ref_surf.V, 1);

  for i=1:ref_surf.V
    for j=1:dest_surf.V
      dist = norm(ref_surf.vertices(i, :) - dest_surf.vertices(j, :));
      if dist < eps
         rpIndex(i) = j;
         break;
      end
    end
  end

end
