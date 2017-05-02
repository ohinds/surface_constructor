% top level script to guess seed locations in some or all volume
% slices for later segmentation.
%
% NOTE: all 0 to 1-based indexing conversion happens in this file

function guess_vol_seeds(vol_fname, slices, out_seed_fname)

  debug = 0;

  % load the volume and extract the slice
  [vol M] = load_mgh(vol_fname);

  if length(slices) == 0
      slices = 0:(size(vol, 3) - 1);
  end

  fp = fopen(out_seed_fname, 'w');
  for slice_num=1:length(slices)
      slc = vol(:, :, slices(slice_num) + 1);

      % blur?
      blurred_slc = imfilter(slc, fspecial('gaussian', 4, 4));

      [~, bright_sorted] = sort(blurred_slc(:), 'descend');

      % pick seeds that aren't too near one another
      num_fg_seeds_to_pick = 20;
      dist_thresh_px = 25;
      sq_dist_thresh_px = dist_thresh_px^2;
      fg_seeds = {};
      for cur_bright=1:length(bright_sorted)
          [cur_r, cur_c] = ind2sub(size(slc), bright_sorted(cur_bright));
          cont_out = 0;
          for already_seed=1:length(fg_seeds)
              sq_dist = (fg_seeds{already_seed}(1) - cur_r)^2 + ...
                        (fg_seeds{already_seed}(2) - cur_c)^2;
              if sq_dist < sq_dist_thresh_px
                  cont_out = 1;
                  break;
              end
          end

          if cont_out
              continue;
          end

          fg_seeds{end+1} = [cur_r, cur_c];

          if length(fg_seeds) >= num_fg_seeds_to_pick
              break;
          end
      end

      % build bg seeds as those with very low intensity in a window
      % around the fg_seeds
      bg_search_win_px = 25;
      bg_seed_proportion = 0.025; % 5%
      bg_seeds = {};
      for fg_i=1:length(fg_seeds)
          fg = fg_seeds{fg_i};
          bg_r = [max([1 fg(1)-bg_search_win_px]):min(size(slc,1), fg(1)+bg_search_win_px)];
          bg_c = [max([1 fg(2)-bg_search_win_px]):min(size(slc,2), fg(2)+bg_search_win_px)];

          bg_win = blurred_slc(bg_r, bg_c);

          [~, dim_sorted] = sort(bg_win(:));

          these_bg_seeds = dim_sorted(...
              1:round(length(dim_sorted)*bg_seed_proportion));

          for seed=1:length(these_bg_seeds)
              [this_seed_r, this_seed_c] = ind2sub(size(bg_win), these_bg_seeds(seed));
              bg_seeds{end+1} = [bg_r(1) + this_seed_r, bg_c(1) + this_seed_c];
          end
      end

      if debug
          show_slc = slc;
          for i=1:length(fg_seeds)
              for r=fg_seeds{i}(1)-1:fg_seeds{i}(1)+1
                  for c=fg_seeds{i}(2)-1:fg_seeds{i}(2)+1
                      show_slc(r, c) = max(slc(:)) + 1;
                  end
              end
          end

          for i=1:length(bg_seeds)
              for r=bg_seeds{i}(1)-1:bg_seeds{i}(1)+1
                  for c=bg_seeds{i}(2)-1:bg_seeds{i}(2)+1
                      show_slc(r, c) = min(slc(:)) - 1;
                  end
              end
          end

          imagesc(show_slc);
      end

      fprintf(fp, 'slice %d\n', slices(slice_num));

      fprintf(fp, 'fg\n');
      for fg=1:length(fg_seeds)
          fprintf(fp, '%d %d\n', fg_seeds{fg}(1) - 1, fg_seeds{fg}(2) - 1);
      end

      fprintf(fp, 'bg\n');
      for bg=1:length(bg_seeds)
          fprintf(fp, '%d %d\n', bg_seeds{bg}(1) - 1, bg_seeds{bg}(2) - 1);
      end
  end

  fclose(fp);
end
