% Oliver Hinds <oph@bu.edu>
% 2006-02-16


function area = getEllipseOverlapArea(e1,e2)
  if(e1.a > e2.a) 
    a1 = e1.a;
    b1 = e1.b;
    a2 = e2.a;
    b2 = e2.b;
  else
    a2 = e1.a;
    b2 = e1.b;
    a1 = e2.a;
    b1 = e2.b;
  end
  
  % get the intersection point
  [x0, y0] = findEllipseIntersection(e1,e2);
   
  % evaluate the integrated expressions for area
  t1 = (1/2) * (x0 * sqrt(a1^2 - x0^2) + a1^2 * asin(x0/a1));
  t2 = (1/2) * ((pi/2*a2^2) - (x0 * sqrt(a2^2 - x0^2) + a2^2 * asin(x0/a2)));
 
  area = 4*( (b1/a1) * t1 + (b2/a2) * t2);
return

function [x, y] = findEllipseIntersection(e1,e2)
  a1 = e1.a;
  b1 = e1.b;
  a2 = e2.a;
  b2 = e2.b;
  
  x = (-a1^2*a2^2*(b1^2-b2^2)/(a1^2*b2^2-a2^2*b1^2))^(1/2);
  y = (b2^2*(a2^2-x^2)/a2^2)^(1/2);
return

