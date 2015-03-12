% Oliver Hinds <oph@bu.edu>
% 2006-04-03

function compareHumanMacaqueAspects
  mac = {
      'm1l',
      'm1r',
      'm2l',
      'm2r',
      'm3l',
      'm3r',
      'm4l',
      'm4r',
	};
  
  hum = {
      'ev07',   
      'ev08',   
      'ev14_lh',
      'ev14_rh',
      'ev22',   
      'ev19',   
      'ev12_lh',
      'ev12_rh',
      'ev16',   
      'ev21',
	};

  % load the macaque aspects
  mac_aspects = [];
  for(s=1:length(mac))
    m = eval(sprintf('load(''macaqueStats_%s'',''aspect_%s'')',...
				      mac{s},mac{s}));
    mac_aspects(end+1) = eval(sprintf('m.aspect_%s',mac{s}));
  end

  % load the human aspects
  hum_aspects = [];
  for(s=1:length(hum))
    e = eval(sprintf('load(''surfStats_%s'',''ellipse_%s'')', hum{s},hum{s}));
    hum_aspects(end+1) = eval(sprintf('e.ellipse_%s.a/e.ellipse_%s.b',hum{s},hum{s}));
  end
  
  % test for same mean
  [f,p] = anova([mac_aspects hum_aspects], ...
		[zeros(size(mac_aspects)) ones(size(hum_aspects))])

  % print
  fprintf('the mean aspect ratio of human and macaque V1 are the same with p=%f\n',p);
  
return


%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/compareHumanMacaqueAspects.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
