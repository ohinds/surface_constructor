% Oliver Hinds <oph@bu.edu>
% 2005-05-24

function makeScaleBar(a,pa,x,y,wid,len,str,strx,stry)

  delta = 0.1;
  
  v = get(pa,'vertices');
  cp = get(a,'cameraposition');
  ct = get(a,'cameratarget');
  cu = get(a,'cameraupvector');
%   xl = get(a,'xlim');
%   yl = get(a,'ylim');
%   zl = get(a,'zlim');
  
%   mn = min(v(:,1:2))';
%   mx = max(v(:,1:2))';
%   mv = mean(v(:,1:2))';
%   lim = [xl(1) yl(1)]'; 

  theta = atan2(cu(2),cu(1));
  A = inv([cos(theta), sin(theta); -sin(theta), cos(theta)]);
  
  %bl = [mn(1) mx(2)]'  - delta*(lim-mn);
  bl = [x,y]';
  %keyboard
  
  barVerts = [(A*bl)';
	      (A*(bl + [wid 0]'))';
	      (A*(bl + [wid len]'))';
	      (A*(bl + [0 len]'))'];
  barFaces = [1 2 3 4];
  
  patch('vertices',barVerts,'faces',barFaces,'facecolor','black','edgecolor','none');

  s = [strx,stry]';
  tp = (A*s)';
  if(nargin > 4)
    text(tp(1),tp(2),0, str, 'color', 'white', 'fontsize', 10);
  end
  
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/makeScaleBar.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
