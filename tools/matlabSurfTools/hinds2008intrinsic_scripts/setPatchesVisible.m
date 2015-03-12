% setPatchesVisible(h,<0,1>)
% Oliver Hinds <oph@bu.edu>
% 2005-11-08

function setPatchesVisible(h,vis)
  
  if(nargin < 2)
    fprintf('usage: setPatchesVisible(h,vis)\n');
  end
  
  if(vis == 0)
    vstr = 'off';
  else
    vstr = 'on';
  end
  
  ch = get(h,'children');  
  for(i=1:length(ch))
    if(strcmp(get(ch(i),'type'),'patch'))
      set(ch(i),'visible',vstr);
    end
  end
return

%************************************************************************%
%%% $Source: /home/oph/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/setPatchesVisible.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
