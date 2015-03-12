function varargout = colorbar_label_text(varargin)
% COLORBAR_LABEL_TEXT
%
% COLORBAR_LABEL_TEXT(FIG, FORMAT)
%
% (assumes that colorbar is vertically oriented and located on right of figure)  
%
%
% example:
%
%   handles = colorbar_label_text(gcf, '%+0.1f mm^{-2}')

% jonathan polimeni <jonnyreb@alaya.bu.edu>, 03/03/2006
% $Id: colorbar_label_text.m,v 1.1 2006/03/06 15:37:45 oph Exp $
%**************************************************************************%


% TODO: break this function out into subfunctions so that top-level
% function takes an axis handle and a string (with an 'append' option),
% where the X and Y axes are both handled.


  if ( nargin >= 1 ),
    fig = varargin{1};
  else,
    fig = gcf;
  end;

  if ( nargin >= 2 ),
    format = varargin{2};
  else,
    format = '%0.1d^\circ';    
  end;
  
  h = [];

  
  % find handle for colorbar
  cba = findall(fig, 'Tag', 'Colorbar');

  if ( isempty(cba) ),
    errstr = 'figure contains no colorbar!';
    error('\n!!! [%s]: %s', mfilename, errstr);    
  end;
  
  
  YTick      = get(cba, 'YTick');
  YTickLabel = get(cba, 'YTickLabel');
  FontSize   = get(cba, 'FontSize');


  
  if ( ~isempty(YTickLabel) ),

    % set label to blank so function will return if called twice on same colorbar
    set(cba, 'YTickLabel', '');
    
    %     YTickLabel = {regexprep(YTickLabel, '\s\D.*', '')};
    
    YTickValues = str2num(YTickLabel);

    % nudge zero values epsilon over to the positive axis
    YTickValues(find(YTickValues == 0)) = abs(sqrt(eps));
    
    for ind = 1:size(YTickLabel,1),
      LabelCell{ind} = sprintf(format, YTickValues(ind));
    end;

    % concatenate cells (with padding)
    YTickLabelText = strvcat(LabelCell);

    set(cba, 'YTickMode', 'manual');

    hyLabel = get(cba,'YLabel');
    set(hyLabel,'Units','data');
    yLabelPosition = get(hyLabel,'Position');

    % extract horizontal position from original labels
    x = yLabelPosition(1);
    X = repmat(x, size(YTick,2), 1);

    % generate text boxes
    h = text(X, YTick, YTickLabelText, 'Parent', cba, 'FontSize', FontSize, ...
	     'HorizontalAlignment', 'right');

    % find widths chosen for text boxes
    extent = cell2mat(get(h, 'Extent'));

    % (width is third column of extent matrix)
    width = extent(:,3);
    width = max(width);

    % shift text labels over by width (plus a little extra)
    for ind = 1:size(YTickLabel,1),
      pos = get(h(ind), 'Position');
      set(h(ind), 'Position', [pos(1) + width*1.01, pos(2)]);
    end;
    
  else,
    errstr = 'colorbar tick labels are empty';
    error('\n!!! [%s]: %s', mfilename, errstr);
  end;

  if ( nargout >= 1 ),
    varargout{1} = h;
  end;


  %************************************************************************%
  %%% $Source: /home/cvs/WRITINGS/ARTICLES/EX_VIVO_STRIA/MATLAB/colorbar_label_text.m,v $
  %%% Local Variables:
  %%% mode: Matlab
  %%% fill-column: 76
  %%% comment-column: 0
  %%% End:
