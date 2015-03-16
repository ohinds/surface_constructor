% calculates the surface area of a surfStruct
%
% a = surfaceArea(SURFSTRUCT)
%
% Oliver Hinds <oph@bu.edu>
% 2004-11-05

function a = surfaceArea(surfStruct, labelOnly)
  % check for args
  if(nargin < 1)
    fprintf('usage: a = faceArea(surfStruct)');
  end

  if(nargin < 2)
    labelOnly = 0;
  end

  a = 0;
  for(f=1:size(surfStruct.faces,1))
    fa = faceArea(surfStruct.vertices(surfStruct.faces(f,:),:));

    if(labelOnly && sum(surfStruct.vertexLabels(surfStruct.faces(f,:))) < 3)
      continue
    end

    a = a+fa;
  end

return

function a = faceArea(verts)

  a = 0.5*sqrt(-2*verts(1,1)*verts(1,1)*verts(2,3)*verts(3,3)-2*verts(1,1)*verts(2,2)*verts(2,2)*verts(3,1)-2*verts(1,1)*verts(3,2)*verts(3,2)*verts(2,1)-2*verts(1,2)*verts(1,2)*verts(2,3)*verts(3,3)-2*verts(1,1)*verts(1,1)*verts(2,2)*verts(3,2)+2*verts(2,1)*verts(1,2)*verts(3,1)*verts(2,2)+2*verts(2,1)*verts(3,2)*verts(3,1)*verts(1,2)-2*verts(2,1)*verts(3,2)*verts(3,1)*verts(2,2)-2*verts(1,2)*verts(2,3)*verts(2,2)*verts(1,3)+2*verts(1,2)*verts(2,3)*verts(2,2)*verts(3,3)+2*verts(1,2)*verts(2,3)*verts(3,2)*verts(1,3)+2*verts(1,2)*verts(3,3)*verts(2,2)*verts(1,3)-2*verts(1,2)*verts(3,3)*verts(3,2)*verts(1,3)+2*verts(1,2)*verts(3,3)*verts(3,2)*verts(2,3)+2*verts(2,2)*verts(1,3)*verts(3,2)*verts(2,3)-2*verts(2,2)*verts(3,3)*verts(3,2)*verts(2,3)-2*verts(1,1)*verts(2,3)*verts(2,1)*verts(1,3)+2*verts(1,1)*verts(2,3)*verts(2,1)*verts(3,3)+2*verts(1,1)*verts(2,3)*verts(3,1)*verts(1,3)+2*verts(1,1)*verts(3,3)*verts(2,1)*verts(1,3)-2*verts(1,1)*verts(3,3)*verts(3,1)*verts(1,3)+2*verts(1,1)*verts(3,3)*verts(3,1)*verts(2,3)+2*verts(2,1)*verts(1,3)*verts(3,1)*verts(2,3)+2*verts(2,1)*verts(3,3)*verts(3,1)*verts(1,3)-2*verts(2,1)*verts(3,3)*verts(3,1)*verts(2,3)-2*verts(2,1)*verts(2,1)*verts(1,2)*verts(3,2)-2*verts(2,1)*verts(1,2)*verts(1,2)*verts(3,1)-2*verts(3,1)*verts(3,1)*verts(1,2)*verts(2,2)-2*verts(1,2)*verts(2,3)*verts(2,3)*verts(3,2)-2*verts(1,2)*verts(3,3)*verts(3,3)*verts(2,2)-2*verts(2,2)*verts(2,2)*verts(1,3)*verts(3,3)-2*verts(2,2)*verts(1,3)*verts(1,3)*verts(3,2)+2*verts(1,1)*verts(3,2)*verts(3,1)*verts(2,2)-2*verts(1,1)*verts(3,2)*verts(3,1)*verts(1,2)+2*verts(1,1)*verts(3,2)*verts(2,1)*verts(1,2)+2*verts(1,1)*verts(2,2)*verts(3,1)*verts(1,2)+2*verts(1,1)*verts(2,2)*verts(2,1)*verts(3,2)-2*verts(1,1)*verts(2,2)*verts(2,1)*verts(1,2)+verts(1,1)*verts(1,1)*verts(2,2)*verts(2,2)+verts(1,1)*verts(1,1)*verts(3,2)*verts(3,2)+verts(2,1)*verts(2,1)*verts(1,2)*verts(1,2)+verts(2,1)*verts(2,1)*verts(3,2)*verts(3,2)+verts(3,1)*verts(3,1)*verts(1,2)*verts(1,2)+verts(3,1)*verts(3,1)*verts(2,2)*verts(2,2)+verts(1,2)*verts(1,2)*verts(2,3)*verts(2,3)+verts(1,2)*verts(1,2)*verts(3,3)*verts(3,3)+verts(2,2)*verts(2,2)*verts(1,3)*verts(1,3)+verts(2,2)*verts(2,2)*verts(3,3)*verts(3,3)+verts(3,2)*verts(3,2)*verts(1,3)*verts(1,3)+verts(3,2)*verts(3,2)*verts(2,3)*verts(2,3)+verts(1,1)*verts(1,1)*verts(2,3)*verts(2,3)+verts(1,1)*verts(1,1)*verts(3,3)*verts(3,3)+verts(2,1)*verts(2,1)*verts(1,3)*verts(1,3)+verts(2,1)*verts(2,1)*verts(3,3)*verts(3,3)+verts(3,1)*verts(3,1)*verts(1,3)*verts(1,3)+verts(3,1)*verts(3,1)*verts(2,3)*verts(2,3)-2*verts(3,2)*verts(3,2)*verts(1,3)*verts(2,3)+2*verts(2,2)*verts(3,3)*verts(3,2)*verts(1,3)-2*verts(1,1)*verts(2,3)*verts(2,3)*verts(3,1)-2*verts(1,1)*verts(3,3)*verts(3,3)*verts(2,1)-2*verts(2,1)*verts(2,1)*verts(1,3)*verts(3,3)-2*verts(2,1)*verts(1,3)*verts(1,3)*verts(3,1)-2*verts(3,1)*verts(3,1)*verts(1,3)*verts(2,3));
return
