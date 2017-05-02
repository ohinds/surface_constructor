% top level script to execute 3D volume segmentation based on Surface
% Constructor determined seeds.
function random_walker_mri(vol_fname, dataset_fname, seg_fname, prob_fname, slices)

  dbstop if error

  % load the volume
  [vol M] = load_mgh(vol_fname);

  if (nargin < 4)
     slices = 1:size(vol, 3);
  end

  % read seeds from the dataset file
  fp = fopen(dataset_fname);
  s1 = [];
  s2 = [];
  st = [];

  slice = -1;
  tline = fgets(fp);
  while ischar(tline)
    tline = fgets(fp);

    if length(tline) < 5
      continue
    end

    if (length(tline) > 17 && strcmp(tline(1:17), 'begin slice tacks'))
       slice = slice + 1;
       continue
    end

    if sum(slice == slices) & strcmp(tline(1:5), 'tack:')
      x = sscanf(tline, 'tack: (%f,%f)\n');
      seed = [round(x(1)) round(x(2)) slice] + 1;
      if (size(st, 1) == 0 | ~sum(ismember(st, seed, 'rows')))
        st(end+1,:) = seed;
      end
    end

    if length(tline) < 3
      continue
    end

    if strcmp(tline(1:3), 'fg:')
      x = sscanf(tline, 'fg: (%d, %d, %d)\n');

      if (sum(x(3) + 1 == slices))
        s1(end+1,:) = x' + 1;
      end
    end

    if strcmp(tline(1:3), 'bg:')
      x = sscanf(tline, 'bg: (%d, %d, %d)\n');

      if (sum(x(3) + 1 == slices))
        s2(end+1,:) = x' + 1;
      end
    end
  end

  % add the tack seeds
  if length(st) > 0
      %slices = s2(1, 3):s2(end, 3);
      st(find(st(:, 3) < slices(1)), :) = [];
      st(find(st(:, 3) > slices(end)), :) = [];
      for i=1:size(st,1)
          if (size(s1, 1) ~= 0 && sum(ismember(s1, st(i, :), 'rows')))
              continue
          end
          s1(end+1, :) = st(i, :);
      end
  end

  % crop the volume
  bounds = {};

  for i=1:3
    bounds{i} = min([s1(:, i); s2(:, i)]):max([s1(:, i); s2(:, i)]);
    s1(:, i) = s1(:, i) - bounds{i}(1) + 1;
    s2(:, i) = s2(:, i) - bounds{i}(1) + 1;
  end

  img = permute(vol(bounds{1}, bounds{2}, bounds{3}), [2 1 3]);
  [X Y Z]=size(img);

  fprintf('Segmenting %d voxels (%dx%dx%d) with %d fg and %d bg seeds\n', ...
          X*Y*Z, X, Y, Z, size(s1, 1), size(s2, 1));

  % run segmentation
  [mask prob] = random_walker_3d(...
      img, [sub2ind([X Y Z], s1(:, 2), s1(:, 1), s1(:, 3)); ...
            sub2ind([X Y Z], s2(:, 2), s2(:, 1), s2(:, 3))], ...
      [ones(1, size(s1, 1)), 2 * ones(1, size(s2, 1))]);


  if (exist(seg_fname, 'file'))
     seg_vol = load_mgh(seg_fname);
  else
    seg_vol = zeros(size(vol));
  end
  seg_vol(bounds{1}, bounds{2}, bounds{3}) = permute(mask, [2 1 3]);
  save_mgh(seg_vol, seg_fname, M);

  if (exist(prob_fname, 'file'))
     prob_vol = load_mgh(prob_fname);
  else
    prob_vol = zeros(size(vol));
  end
  prob_vol(bounds{1}, bounds{2}, bounds{3}) = permute(prob(:,:,:,1), [2 1 3]);
  save_mgh_format(prob_vol, prob_fname, M, [], 3);

end
