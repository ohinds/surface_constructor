% Oliver Hinds <oph@bu.edu>
% 2006-04-01

function sdm = makeSparseBoundaryNodeDM(surf,dm)
  bv = boundaryVerticesFromLabels(surf,0);
  sdm = sparse(length(bv),length(bv));
  for(i=1:length(bv))
    for(j=1:length(bv))
      sdm(bv(i),bv(j)) = dm(bv(i),bv(j));
    end
  end
return
