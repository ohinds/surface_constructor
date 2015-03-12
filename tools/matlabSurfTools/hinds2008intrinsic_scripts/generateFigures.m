% generate the striate figures for the ex vivo stria neuroimage article
% Oliver Hinds <oph@bu.edu>
% 2005-10-30

function generateFigures
  
  sample_ids = {'_ev07',   
      		'_ev08',   
      		'_ev14_lh',
      		'_ev14_rh',
      		'_ev22',   
      		'_ev19',   
      		'_ev12_lh',
      		'_ev12_rh',
      		'_ev16',   
      		'_ev21',   };
  
  sample_names = {'LH1',
      		  'RH1',
      		  'LH2',
      		  'RH2',
      		  'LH3',
      		  'RH3',
      		  'LH4',
      		  'RH4',
      		  'LH5',
      		  'RH5',};
  
  % mr_distortion
  fprintf('generating mr distortion figures...\n');
  mr_distortion(1);close all;
  
  % generate the surface stats and ellipse fits
  fprintf('generating surface statistics...\n');
  generateStats(sample_ids,sample_names);
  
  % surface figures
  fprintf('generating surface figures...\n');
  for(s=1:length(sample_ids))    
    exvivoFig(sample_ids{s},sample_names{s},1);close all;
  end
  
  % human probability map and overlap figures -- left hemis only
  sample_ids_lh = {};
  for(i=1:2:length(sample_ids))
    sample_ids_lh{end+1} = sample_ids{i};
  end
  fprintf('generating left hemi overlap figures and V1 probability maps...\n');
  humanOverlapFigs(sample_ids_lh,1,'_lh');close all;
  
  % human probability map and overlap figures -- right hemis only
  sample_ids_rh = {};
  for(i=2:2:length(sample_ids))
    sample_ids_rh{end+1} = sample_ids{i};
  end
  fprintf('generating right hemi overlap figures and V1 probability maps...\n');
  humanOverlapFigs(sample_ids_rh,1,'_rh');close all;
  
  % human probability map and overlap figures
  fprintf('generating overlap figures and V1 probability maps...\n');
  humanOverlapFigs(sample_ids,1);close all;
  
  % human flattening distortion and curvature maps  
  fprintf('generating average flattening distortion figures...\n');
  flattening_distortion(sample_ids,1);close all;

  fprintf('generating average curvature figures...\n');
  average_curvature(sample_ids,1);close all;
  
  % macaque probability map and overlap figures
  fprintf('generating macaque overlap figures and probability maps...\n');
  macaqueOverlapFigs(1);close all;

  % ellipse and wedge-dipole overlap figure
  fprintf('generating ellipse/wedge-dipole overlap figure...\n');
  ellipse_dipole(sample_ids,1);
  
return

%************************************************************************%
%%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/generateFigures.m,v $
%%% Local Variables:
%%% mode: Matlab
%%% fill-column: 76
%%% comment-column: 0
%%% End:
