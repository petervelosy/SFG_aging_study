function logWithTimestamp(varargin)
    timestamp = datestr(now,'HH:MM:SS.FFF');
    disp(['[', timestamp, ']: ', varargin{:}]);
end