function zz = inv_wedge_dipole_v1(ww, a, b, alpha, k, r, t)
  % The inverse of the wedge-dipole map function in V1.
  %
  % zz = inv_wedge_dipole(ww, a, b, alpha)
  %
  % Given a matrix of complex numbers ww and the wedge dipole
  % parameters a, b, alpha, this functions maps the points in ww
  % (corresponding to visual cortex) back to the retina.

  if nargin < 5
     k = 1;
  end

  if nargin < 6
     r = 0;
  end

  if nargin < 7
     t = complex(0, 0);
  end

  ww = ww - t;

  ww = ww * exp(-i*r);

  % First the inverse dipole map:

  zz = a*b*(1 - exp(ww / k))./(a*exp(ww / k) - b);

  rr = abs(zz);
  thW = angle(zz);
  th = thW/alpha;

  zz = rr.*exp(i*th);
