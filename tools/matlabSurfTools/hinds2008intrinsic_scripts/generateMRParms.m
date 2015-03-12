% generates the mr parms table for ex vivo stria article
%
% Oliver Hinds <oph@bu.edu>
% 2006-01-12

function generateMRParms()

  fp = fopen('../MAIN/mr_parm_tab.tex','w');

  map = {
      { 'I12', 'LH1'},
      { 'I11', 'RH1'},
      { 'I17', 'LH2'},
      { 'I17', 'RH2'},
      { 'HD3', 'LH3'},
      { 'HD2', 'RH3'},
      { 'I15', 'LH4'},
      { 'I15', 'RH4'},
      { 'G1',  'LH5'},
      { 'I19', 'RH5'},
	};

  % generate the parms for each sample
  for(ind=1:size(map,1))
    di = load(sprintf('../DATA/%s_%s_dicom_info.mat',map{ind}{1}, map{ind}{2}));
    di = eval(sprintf('di.%s_%s_dicom_info',map{ind}{1}, map{ind}{2}));
    fprintf(fp,printOne(map{ind}{2},di));
    clear di;
  end

  fclose(fp);
return

function str = printOne(ind, di)
  %keyboard
  str = sprintf('%s & $%d$ & $\\\\unit{%0.1f} \\\\hour$ & $%0.2f \\\\times %0.2f \\\\times %0.2f$ & $%0.2f$ & $\\\\times$ & $%0.2f$  & $\\\\unit{%d} \\\\milli\\\\second$ \\\\\\\\ \n',...
		ind, di.Runs, ...
		di.Runs*(di.RunTime(1)+di.RunTime(2)/60+di.RunTime(3)/3600),...
		di.PixelSpacing(1), di.PixelSpacing(2), ...
		di.SliceThickness, di.PixelSpacing(1)*di.Width,...
		di.PixelSpacing(2)*di.Height, di.RepetitionTime);
  fprintf('%s TE = %0.1f flip angle = %0.1f pixel BW = %0.1f coil = %s\n', ind, di.EchoTime,di.FlipAngle, di.PixelBandwidth, strrep(di.TransmitCoilName,'_',' '));
return

