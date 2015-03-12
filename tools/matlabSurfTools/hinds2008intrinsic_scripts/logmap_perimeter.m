function [h boundary] = logmap_perimeter(varargin)
%==--------------------------------------------------------------------==%
%%% set parameter values arbitrarily

k = 15;             % global dipole map parameter "k"
a = 0.6;            % global dipole map parameter "a"
b = 80;             % global dipole map parameter "b"

alpha1 = 0.8;

if(nargin > 1)
  a = varargin{1};
end

if(nargin > 2)
  b = varargin{2};
end

if(nargin > 3)
  alpha1 = varargin{3};
end


ecc_parafovea  =  16;         % extent of visual field eccentricity
ecc_periphery  =  64;         % extent of visual field eccentricity
Necc =  16;         % number of steps in eccentricity
Npol =  8;         % number of steps in polar angle

% number of points along "high resolution" contour directions
N = 100;

%==--------------------------------------------------------------------==%
%%% compute coord params
% create r, a vector of points exponentially spaced in [0, ecc]
radius_parafovea_polar = linspace(log(a), log(ecc_parafovea+a), Necc)';
radius_parafovea_eccen = linspace(log(a), log(ecc_parafovea+a), N)';
radius_periphery_polar = linspace(log(a), log(ecc_periphery+a), Necc)';
%%%radius_periphery_eccen = linspace(log(a), log(ecc_periphery+a), N)';

% convert parameters from degrees to radians. this conversion is required
% to enforce the visual field into the lower hemisphere of the Riemann
% sphere and thus is more true to "retinal" coordinates.
r_parafovea_polar = [0, 2.^(-2:4)].';
r_parafovea_eccen = ( exp(radius_parafovea_eccen) - a );
%%%r_periphery_polar = [0, 2.^(-2:6)].';
%%%r_periphery_eccen = ( exp(radius_periphery_eccen) - a );

% create theta, a vector of points linearly spaced in [-pi/2, +pi/2]
theta_eccen = linspace(-pi/2,+pi/2,Npol);
theta_polar = linspace(-pi/2,+pi/2,N);

%==--------------------------------------------------------------------==%
%%% compute coordinates

% wandell: max vertical extent of human visual field is 135 degrees
% (measured from fixation)
VM_max = 135 / 2;

% compute the furthest extent of the dipole along the real axis
% (hint: its the representation of the end of the vertical meridian)
u_max = real(  log( (VM_max*exp(i*pi/2*alpha1)+a) ./ (VM_max*exp(i*pi/2*alpha1)+b) )  );
r_max = ( b*exp(u_max) - a ) ./ ( 1 - exp(u_max) );

A = exp(2*u_max) - 1;
C = exp(2*u_max)*(b^2) - a^2;

B_eccen = 2*cos(theta_eccen*alpha1) * ( exp(2*u_max)*b - a);
B_polar = 2*cos(theta_polar*alpha1) * ( exp(2*u_max)*b - a);

% store array of boundary radii (for later comparison)
r_perimeter_eccen = ( -B_eccen - sqrt(B_eccen.^2 - 4*A*C) ) / 2/A;
z_perimeter_eccen = r_perimeter_eccen .* exp(i*theta_eccen);

r_perimeter_polar = ( -B_polar - sqrt(B_polar.^2 - 4*A*C) ) / 2/A;
z_perimeter_polar = r_perimeter_polar .* exp(i*theta_polar);

half_vertical_meridian = [linspace(0,log10(a),N/30) logspace(log(a),log10(ecc_periphery),N/4)];
z_vertical_meridian = i*[-fliplr(half_vertical_meridian) half_vertical_meridian(2:end)];

z_periphery_subsampled = fliplr(z_perimeter_polar(round(linspace(1,length(z_perimeter_polar),2*log(N)))));

boundary_polar = [z_vertical_meridian z_periphery_subsampled(2:end-1)];

for ind = 1:Npol,
  radius_periphery_eccen(:,ind) = linspace(log(a), log(r_perimeter_eccen(ind)+a), N)';
end;

r = [ 2.^[-2:5], VM_max];


for ind = 1:N,
  r_periphery_polar(:,ind) = [r, r_perimeter_polar(ind)].';
end;


r_periphery_eccen = ( exp(radius_periphery_eccen) - a );
%r_periphery_polar = ( exp(radius_periphery_polar) - a );


%%%%%


% create and plot z, a matrix of points corresponding to the rays


z_parafovea_eccen   = r_parafovea_eccen*exp(i*theta_eccen);
z_parafovea_polar   = r_parafovea_polar*exp(i*theta_polar);

%z_periphery_eccen   = r_periphery_eccen*exp(i*theta_eccen);
%z_periphery_polar   = r_periphery_polar*exp(i*theta_polar);
z_periphery_eccen   = r_periphery_eccen.*exp(i*repmat(theta_eccen, [N,1]));
z_periphery_polar   = r_periphery_polar.*exp(i*repmat(theta_polar, [length(r)+1,1]));

Z_parafovea = [z_parafovea_eccen, z_parafovea_polar.'];
Z_periphery = [z_periphery_eccen, z_periphery_polar.'];

%Wa =  k*wedgemonopole( Z_parafovea, a,    alpha1, 0, 0);
Wb =  -k*wedgedipole(   Z_periphery, a, b, alpha1);
boundary =  -k*wedgedipole(   boundary_polar, a, b, alpha1);
%Wb = k*log(Z_periphery+a)-log(Z_periphery+b)-log(real(a))+log(real(b));
%Wp =  k*wedgedipole(   z_perimeter_eccen, a, b, alpha1, 0, 0);


xmin = 0;
%xmax = max(real(Wb(:)))*1.05;
xmax = 68;
%ymin = min(imag(Wa(:)))*1.1;
%ymax = max(imag(Wa(:)))*1.1;
ymin = -25;
ymax = +25;

% $$$ figure; my_polar(angle(Z_periphery), abs(Z_periphery), 'b'); hold on;
% $$$ my_polar(angle(Z_parafovea), abs(Z_parafovea), 'r')

%figure; my_polar(angle(Z_parafovea), abs(Z_parafovea), 'r')

%figure; my_polar(angle(Z_periphery), abs(Z_periphery), 'm', 120);

% $$$ figure; plot(Wa, 'r-');
% $$$ axis equal; axis([xmin, xmax, ymin, ymax]);
% $$$ xlabel('cortical distance (mm)');
% $$$ ylabel('cortical distance (mm)');
% $$$ title(sprintf('k=%2.0f, a=%2.1f', k, a));
% $$$ set(get(gca, 'XLabel'), 'FontSize', 18)
% $$$ set(get(gca, 'YLabel'), 'FontSize', 18)
% $$$ set(get(gca, 'Title'), 'FontSize', 18)

h = figure; plot(Wb, 'k-','linewidth',3); %hold on; plot(Wb, 'w-');
%axis equal; axis([xmin xmax ymin ymax]);
%xlabel('cortical distance (mm)');
%ylabel('cortical distance (mm)');
%title(sprintf('k=%2.0f, a=%2.1f, b=%2.1f, \\alpha1=%2.1f', k, a, b, alpha1));
%set(get(gca, 'XLabel'), 'FontSize', 18)
%set(get(gca, 'YLabel'), 'FontSize', 18)
%set(get(gca, 'Title'), 'FontSize', 18)




function hpol = my_polar(varargin)
%POLAR  Polar coordinate plot.
%   POLAR(THETA, RHO) makes a plot using polar coordinates of
%   the angle THETA, in radians, versus the radius RHO.
%   POLAR(THETA,RHO,S) uses the linestyle specified in string S.
%   See PLOT for a description of legal linestyles.
%
%   POLAR(AX,...) plots into AX instead of GCA.
%
%   H = POLAR(...) returns a handle to the plotted object in H.
%
%   Example:
%      t = 0:.01:2*pi;
%      polar(t,sin(2*t).*cos(2*t),'--r')
%
%   See also PLOT, LOGLOG, SEMILOGX, SEMILOGY.

%   Copyright 1984-2003 The MathWorks, Inc.
%   $Revision: 1.4 $  $Date: 2006/02/16 18:44:22 $

% Parse possible Axes input
[cax,args,nargs] = axescheck(varargin{:});
error(nargchk(1,4,nargs));

if nargs < 1 | nargs > 4
    error('Requires 2 or 3 data arguments.')
elseif nargs == 2
    theta = args{1};
    rho = args{2};
    if isstr(rho)
        line_style = rho;
        rho = theta;
        [mr,nr] = size(rho);
        if mr == 1
            theta = 1:nr;
        else
            th = (1:mr)';
            theta = th(:,ones(1,nr));
        end
    else
        line_style = 'auto';
    end
elseif nargs == 1
    theta = args{1};
    line_style = 'auto';
    rho = theta;
    [mr,nr] = size(rho);
    if mr == 1
        theta = 1:nr;
    else
        th = (1:mr)';
        theta = th(:,ones(1,nr));
    end
else % nargs == 3
    [theta,rho,line_style] = deal(args{1:3});
end
if isstr(theta) | isstr(rho)
    error('Input arguments must be numeric.');
end
if ~isequal(size(theta),size(rho))
    error('THETA and RHO must be the same size.');
end

% get hold state
cax = newplot(cax);

next = lower(get(cax,'NextPlot'));
hold_state = ishold(cax);

% get x-axis text color so grid is in same color
tc = get(cax,'xcolor');
ls = get(cax,'gridlinestyle');

% Hold on to current Text defaults, reset them to the
% Axes' font attributes so tick marks use them.
fAngle  = get(cax, 'DefaultTextFontAngle');
fName   = get(cax, 'DefaultTextFontName');
fSize   = get(cax, 'DefaultTextFontSize');
fWeight = get(cax, 'DefaultTextFontWeight');
fUnits  = get(cax, 'DefaultTextUnits');
set(cax, 'DefaultTextFontAngle',  get(cax, 'FontAngle'), ...
    'DefaultTextFontName',   get(cax, 'FontName'), ...
    'DefaultTextFontSize',   14, ...
    'DefaultTextFontWeight', get(cax, 'FontWeight'), ...
    'DefaultTextUnits','data')

% only do grids if hold is off
if ~hold_state

% make a radial grid
    hold(cax,'on');
    if ( nargin == 4 ),
      maxrho = varargin{4};
    else,
      maxrho = 80;
    end;
    hhh=line([-maxrho -maxrho maxrho maxrho],[-maxrho maxrho maxrho -maxrho],'parent',cax);
    set(cax,'dataaspectratio',[1 1 1],'plotboxaspectratiomode','auto')
    v = [get(cax,'xlim') get(cax,'ylim')];
    v = [-maxrho +maxrho -maxrho +maxrho];
    ticks = sum(get(cax,'ytick')>=0);
    delete(hhh);
% check radial limits and ticks
    rmin = 0; rmax = v(4); rticks = max(ticks-1,2);
    if rticks > 5   % see if we can reduce the number
        if rem(rticks,2) == 0
            rticks = rticks/2;
        elseif rem(rticks,3) == 0
            rticks = rticks/3;
        end
    end

% define a circle
    th = 0:pi/50:2*pi;
    xunit = cos(th);
    yunit = sin(th);
% now really force points on x/y axes to lie on them exactly
    inds = 1:(length(th)-1)/4:length(th);
    xunit(inds(2:2:4)) = zeros(2,1);
    yunit(inds(1:2:5)) = zeros(3,1);
% plot background if necessary
    if ~isstr(get(cax,'color')),
       patch('xdata',xunit*rmax,'ydata',yunit*rmax, ...
             'edgecolor',tc,'facecolor',get(cax,'color'),...
             'handlevisibility','off','parent',cax);
    end

% plot spokes
    th = (1:6)*2*pi/12;
    cst = cos(th); snt = sin(th);
    cs = [-cst; cst];
    sn = [-snt; snt];
    line(rmax*cs,rmax*sn,'linestyle','-','color',tc,'linewidth',1,...
         'handlevisibility','off','parent',cax, ...
		   'Color', [0.831 0.816 0.784])

% draw radial circles
    c82 = cos(170*pi/180);
    s82 = sin(170*pi/180);
    rinc = (rmax-rmin)/rticks;
    for i=(rmin+rinc):rinc:rmax
        hhh = line(xunit*i,yunit*i,'linestyle','-','color',tc,'linewidth',1,...
                   'handlevisibility','off','parent',cax, ...
		   'Color', [0.831 0.816 0.784]);
        text((i+rinc/20)*c82,(i)*s82, ...
            ['  ' num2str(i) '^o'],'verticalalignment','bottom',...
            'handlevisibility','off','parent',cax)
    end
    set(hhh,'linestyle','-', 'linewidth', 2.0, 'Color', 'k') % Make outer circle solid

% annotate spokes in degrees
    rt = 1.1*rmax;
    for i = 1:length(th)
        text(rt*cst(i),rt*snt(i),[int2str(i*30) '^o'],...
             'horizontalalignment','center',...
             'handlevisibility','off','parent',cax);
        if i == length(th)
            loc = int2str(0);
        else
            loc = int2str(180+i*30);
        end
        text(-rt*cst(i),-rt*snt(i),[loc '^o'],'horizontalalignment','center',...
             'handlevisibility','off','parent',cax)
    end

% set view to 2-D
    view(cax,2);
% set axis limits
    axis(cax,rmax*[-1 1 -1.15 1.15]);
end

% Reset defaults.
set(cax, 'DefaultTextFontAngle', fAngle , ...
    'DefaultTextFontName',   fName , ...
    'DefaultTextFontSize',   fSize, ...
    'DefaultTextFontWeight', fWeight, ...
    'DefaultTextUnits',fUnits );

% transform data to Cartesian coordinates.
xx = rho.*cos(theta);
yy = rho.*sin(theta);

% plot data on top of grid
if strcmp(line_style,'auto')
    q = plot(xx,yy,'parent',cax);
else
    q = plot(xx,yy,line_style,'parent',cax);
end

if nargout == 1
    hpol = q;
end

if ~hold_state
    set(cax,'dataaspectratio',[1 1 1]), axis(cax,'off'); set(cax,'NextPlot',next);
end
set(get(cax,'xlabel'),'visible','on')
set(get(cax,'ylabel'),'visible','on')


function w = wedgedipole(z, a, b, alpha1)
% WEDGEDIPOLE  wedge-dipole mapping function
%
% W = WEDGEDIPOLE(Z, A, B, ALPHA1)
  
% ( based on wedge_dipole.m by mukundb )
% jonathan polimeni <jonnyreb@athlete-2.bu.edu>, 10/22/2002
% $Id: logmap_perimeter.m,v 1.4 2006/02/16 18:44:22 oph Exp $
%**************************************************************************%

z = abs(z).*exp(i*alpha1*angle(z));

if ( isfinite(b) ),
  w = log(z + a) - log(z + b) - log(a/b);
else,
  w = log(z + a) - log(a);
end;


return;
