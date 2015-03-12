% calculate the error of the fit of a set of analytically determined
% ellipses. 
%
% 
%
% Oliver Hinds <oph@bu.edu>
% 2006-02-16

function e = ellipseErrOverlap(x,ref_ellipse,aspect_ratio)
  
  ellipse.a = x;
  ellipse.b = ellipse.a/aspect_ratio;
  ref_ellipse_area = pi*ref_ellipse.a*ref_ellipse.b;
  ellipse_area = pi*ellipse.a*ellipse.b;
    
  overlap_area = getEllipseOverlapArea(ref_ellipse,ellipse);
    
  e = (ref_ellipse_area - overlap_area) + (ellipse_area - overlap_area);

return;

