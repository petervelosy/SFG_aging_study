function varargout = sendTrigger(varargin)
    [varargout{1:nargout}] = lptwrite(varargin{:});
    fprintf('Sent trigger %d with length %.03f through port %d\n', varargin{2}, varargin{3}, varargin{1});
end