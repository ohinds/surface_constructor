% generates the surface stats table for the SFN2005 ex vivo stria poster
% 
% Oliver Hinds <oph@bu.edu>
% 2005-05-25

function generateStats(sample_ids,sample_names,dothese);
  
  dm_path = '/net/MRI/FreeSurfer/subjects/subjects_eslab/stria/dm_links';
  fp = fopen('../MAIN/stats_tab.tex','w');
  
  num_samples = length(sample_ids);
  
  if(nargin < 3)
    dothese = ones(num_samples,1);
  end

  % generate the stats for each sample
  for(ind=1:num_samples)
    if(dothese(ind))
      fixFlatmapOrientation(sample_ids{ind});
      
      d = load(sprintf('display%s.mat',sample_ids{ind}));
      eval(sprintf('v1 = d.V1smoothedSurf%s;',sample_ids{ind}));
      eval(sprintf('flat = d.smoothedFlatSurf%s;',sample_ids{ind}));
      eval(sprintf('v1flat = d.V1smoothedFlatSurf%s;',sample_ids{ind}));
      eval(sprintf('ocv = d.occPoleVertex%s;',sample_ids{ind}));
      eval(sprintf('sdm = d.sdm%s;',sample_ids{ind}));
      fprintf('generating stats for ev%s == %s\n',sample_ids{ind},sample_names{ind});
      
      [flaterr(ind), area(ind), peri(ind), fperi(ind), aspect(ind), aspect3d(ind), ellipse{ind}, str{ind}] = ...
	  printOne(sample_names{ind}, v1, v1flat, flat.vertices(ocv,:),sdm,flat);  
      saveStats(flaterr(ind), area(ind), peri(ind), fperi(ind), ellipse{ind},sample_ids{ind});
    
      clear d;
      fprintf('\n');      
    end
  end
  
  if(sum(dothese) < num_samples)
    return
  end
  
  % make some vectors and print the strings 
  for(i=1:num_samples)
    %ar(i) = aspect{i}.ratio;
    a(i) = ellipse{i}.a;
    b(i) = ellipse{i}.b;
    ear(i) = a(i)/b(i);
    
    fprintf(fp,str{i});
  end
  
  % calculate means and standard deviations
 fprintf(fp,'\\midrule\n\\textbf{mean} $\\boldsymbol{\\pm}$ \\textbf{std.} & \\multicolumn{1}{c}{$%0.1f\\%%\\pm%0.1f\\%%$} & $\\boldsymbol{%0.0f\\pm%0.0f}$ & $\\boldsymbol{%0.0f\\pm%0.0f}$ & $\\boldsymbol{%0.1f\\pm%0.1f}$ & $\\boldsymbol{%0.1f\\pm%0.1f}$ & $\\boldsymbol{%0.2f\\pm%0.2f}$ & $\\boldsymbol{%0.2f\\pm%0.2f}$ \\\\\n', ...
	 mean(flaterr), sqrt(var(flaterr)), mean(area), sqrt(var(area)), ...
	 mean(peri), sqrt(var(peri)), ...
	 mean(a), sqrt(var(a)), mean(b), ...
	 sqrt(var(b)), mean(ear), sqrt(var(ear)), ...
	 mean(aspect3d), sqrt(var(aspect3d)) ...
	 );

 p = anova1([aspect3d' ear']);
 fprintf('the means of the 3d and 2d aspect ratios are equal with p=%f\n', p);

% fprintf(fp,'\\midrule\n\\textbf{mean} $\\boldsymbol{\\pm}$ \\textbf{std.} & \\multicolumn{1}{c}{$%0.1f\\%%\\pm%0.1f\\%%$} & $\\boldsymbol{%0.0f\\pm%0.0f}$ & $\\boldsymbol{%0.0f\\pm%0.0f}$ & $\\boldsymbol{%0.1f\\pm%0.1f}$ & $\\boldsymbol{%0.1f\\pm%0.1f}$ & $\\boldsymbol{%0.2f\\pm%0.2f}$ \\\\\n', ...
%	 mean(flaterr), sqrt(var(flaterr)), mean(area), sqrt(var(area)), ...
%	 mean(peri), sqrt(var(peri)), ...
%	 mean(a), sqrt(var(a)), mean(b), ...
%	 sqrt(var(b)), mean(ear), sqrt(var(ear)), ...
%	 );

  fclose(fp);
return

function [flaterr, area, peri, fperi, aspect, aspect3d, ellipse, str]...
      = printOne(ind, v1surf, v1flatsurf, occPoleVert, dm, flat) 
  [area, peri, fperi, aspect, aspect3d, ellipse] = ...
      surfStats(v1surf, v1flatsurf, occPoleVert, dm, flat); 
  %  str = sprintf('%s & %0.1f\\\\%%%% & %0.0f & %0.0f & %0.1f & %0.1f & %0.2f \\\\\\\\\\n',...
  str = sprintf('%s & %0.1f\\\\%%%% & %0.0f & %0.0f & %0.1f & %0.1f & %0.2f & %0.2f \\\\\\\\\\n',...
  ind, v1flatsurf.WRMSE, area, peri, ...
      ellipse.a, ellipse.b, ...
      ellipse.a / ellipse.b, ...
      aspect3d ...
      );
  flaterr = v1flatsurf.WRMSE;
return

function saveStats(flaterr, area, peri, fperi, ellipse, postfix)
  eval(sprintf('flaterr%s = flaterr;',postfix));
  eval(sprintf('area%s = area;',postfix));
  eval(sprintf('peri%s = peri;',postfix));
  eval(sprintf('fperi%s = fperi;',postfix));
  eval(sprintf('ellipse%s = ellipse;',postfix));
  
  eval(sprintf('save surfStats%s flaterr%s area%s peri%s fperi%s ellipse%s',...
	       postfix, postfix, postfix, postfix, postfix, postfix));

return
