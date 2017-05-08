% deduce a slice contours from a segmentation volume, slice by slice
% Oliver Hinds <ohinds@gmail.com> 2017-05-03

function [slices, contour_closure] = isoContours(seg)
    slices = {};
    contour_closure = {};

    parfor sl=1:size(seg,3)
        fprintf('searching for contours on slice %d\n', sl);
        slices{sl} = isoContour(seg(:,:,sl), sl);
        contour_closure{sl} = ones(1,length(slices{sl}));
        %fprintf('found %d contours\n', length(slices{sl}));
    end

return

function contours = isoContour(im, sl_ind)
    contours = {};
    im(:,[1 end]) = 0;
    im([1 end], :) = 0;
    for r=1:size(im, 1)
        for c=1:size(im, 2)
            if im(r, c) && ~in_contours(r, c, contours)
                %fprintf('searching for a contour starting at %d %d\n', r, c);
                contour = build_contour(im, r, c);
                contour(:, end + 1) = sl_ind;
                contours{end + 1} = contour;
                %fprintf('found %d vertices\n', size(contours{end}, 1));
            end
        end
    end

return

function in = in_contours(r, c, contours)
    in = 0;

    for i=1:length(contours)
        if inpolygon(r, c, contours{i}(:,1), contours{i}(:,2))
            in = 1;
            return
        end
    end

return

function [contour, visited] = build_contour(im, start_r, start_c)
    contour = [start_r + 1, start_c;
               start_r, start_c];

    [next_r, next_c, dir] = find_next(im, start_r, start_c, 1);
    while ~(next_r == start_r && next_c == start_c)
        contour(end + 1, :) = [next_r, next_c];
        [next_r, next_c, dir] = find_next(im, next_r, next_c, dir);
    end
return

function next_dir = make_dir(dir)
    % fuck matlab
    next_dir = mod(dir, 4);
    if next_dir == 0
        next_dir = 4;
    end
return

function [next_r, next_c, next_dir] = find_next(im, start_r, start_c, dir)
   dir_map = [ 0, -1  % w
              -1,  0  % n
               0,  1  % e
               1,  0  % s
               ];


   for d=1:3
       next_dir = make_dir(d + dir);

       next_r = start_r + dir_map(next_dir, 1);
       next_c = start_c + dir_map(next_dir, 2);
       if is_boundary(im, next_r, next_c)
           % reverse the direction to indicate where we came from
           next_dir = make_dir(next_dir + 2);
           return
       end
   end

   keyboard
return

function px = get_px(im, r, c)
    if r <= 1 || r >= size(im, 1) || c <= 1 || c >= size(im, 2)
        px = 0;
        return
    end

    px = im(r, c);
return

function boundary = is_boundary(im, r, c)
    surround_sum = ...
        get_px(im, r - 1, c - 1) + ...
        get_px(im, r - 1, c) + ...
        get_px(im, r, c - 1) + ...
        get_px(im, r, c);

    boundary = surround_sum > 0 && surround_sum < 4;
return
