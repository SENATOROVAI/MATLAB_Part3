function [t_state, states] = alarm_fsm(events, fs_evt)
    if nargin < 2, fs_evt = 100; end
    Tmax = max([events.time]) + 2;
    n = round(Tmax * fs_evt);
    t_state = (0:n-1)'/fs_evt;
    states = ones(n,1);
    cur = 1; alarm_t = NaN;
    ei = 1; nev = numel(events);
    for k = 1:n
        tk = t_state(k);
        while ei <= nev && events(ei).time <= tk
            switch events(ei).type
                case {'fire','intrusion'}, cur = 2; alarm_t = events(ei).time;
                case 'operator_test',      cur = 4;
                case 'fault',              cur = 5;
                case 'reset',              cur = 1; alarm_t = NaN;
            end
            ei = ei + 1;
        end
        if cur == 2 && ~isnan(alarm_t) && (tk - alarm_t) >= 0.5
            cur = 3;
        end
        states(k) = cur;
    end
end
