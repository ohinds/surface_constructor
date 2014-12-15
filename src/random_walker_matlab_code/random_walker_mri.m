% top level script to execute 3D volume segmentation based on Surface
% Constructor determined seeds.
function random_walker_mri(vol_fname, dataset_fname, seg_fname)
  addpath('graphAnalysisToolbox-1.0');
  addpath('../../tools/matlabSurfTools/');

  % load the volume
  [vol M] = load_mgh(vol_fname);

  % read seeds from the dataset file
  fp = fopen(dataset_fname);
  s1 = [];
  s2 = [];

  tline = fgets(fp);
  while ischar(tline)
    tline = fgets(fp);

    if length(tline) < 3
      continue
    end

    if strcmp(tline(1:3), 'fg:')
      x = sscanf(tline, 'fg: (%d, %d, %d)\n');
      s1(end+1,:) = x' + 1;
    end

    if strcmp(tline(1:3), 'bg:')
      x = sscanf(tline, 'bg: (%d, %d, %d)\n');
      s2(end+1,:) = x' + 1;
    end
  end

  slices = min(s1(1, 3), s2(1, 3)):max(s1(end, 3), s2(end, 3));
  img = vol(:, :, slices);
  img = permute(vol(:, :, slices), [2 1 3]);
  [X Y Z]=size(img);

  s1(:, 3) = s1(:, 3) - slices(1) + 1;
  s2(:, 3) = s2(:, 3) - slices(1) + 1;

  % run segmentation
  mask = random_walker_3d(...
             img, [sub2ind([X Y Z], s1(:, 2), s1(:, 1), s1(:, 3)); ...
                   sub2ind([X Y Z], s2(:, 2), s2(:, 1), s2(:, 3))], ...
             [ones(1, size(s1, 1)), 2 * ones(1, size(s2, 1))]);


  seg_vol = zeros(size(vol));
  seg_vol(:, :, slices) = permute(mask, [2 1 3]);
  save_mgh(seg_vol, seg_fname, M);
