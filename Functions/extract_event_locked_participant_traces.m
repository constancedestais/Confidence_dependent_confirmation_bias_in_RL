function out = extract_event_locked_participant_traces(d, variable_name, cond_idx, pre, post)
% Build participant-locked reversal-centered traces for one variable.
%
% Requirements satisfied:
%   - keeps edge reversals (NaN padding)
%   - event-weighted pooling across requested conditions (so we average over ALL reversals/event, NOT within conditions and then over the conditions)
%   - accepts scalar or vector cond_idx
%
% Inputs:
%   d            : data struct, containing variable "reversal" and variable_name
%   variable_name : field name in d, array [P x S x C x T]
%   cond_idx      : conditions to include (scalar or vector)
%   pre, post    : window lengths
%
% Output:
%   out.per_participant : [P x nLags] participant-level traces
%   out.mean, out.sem  : across-participant summary (participant-locked)
%   out.N              : number of participants contributing at each lag
%   out.n_reversals_per_participant : how many reversal events were pooled per participant


% ---- Validate required fields ----
if ~isfield(d, 'reversal')
    error('Dataset d must contain field d.reversal of size [P x S x C x T].');
end
if ~isfield(d, variable_name)
    error('Dataset d must contain field d.%s.', variable_name);
end

X   = d.(variable_name);
rev = d.reversal;

if ~isequal(size(X), size(rev))
    error('Size mismatch: d.%s is %s but d.reversal is %s. They must match.', ...
        variable_name, mat2str(size(X)), mat2str(size(rev)));
end

% ----
X   = d.(variable_name); % [P x S x C x T]
rev = d.reversal;       % [P x S x C x T]

[P,S,C,T] = size(X);

if nargin < 3 || isempty(cond_idx)
    cond_idx = 1:C;
end

lags  = -pre:post;
nLags = numel(lags);

per_participant = nan(P, nLags);
n_reversals_per_participant = zeros(P,1);

for p = 1:P
    eventWindows = []; % stacked [nEvents x nLags] across sessions+conditions

    for c = cond_idx(:)'        % iterate requested conditions
        for s = 1:S
            reversalTrials = find(squeeze(rev(p,s,c,:)) > 0);

            for e = 1:numel(reversalTrials)
                t0  = reversalTrials(e);
                idx = t0 + lags;

                % keep edge reversals: pad out-of-bounds with NaN
                window = nan(1, nLags);
                inBounds = (idx >= 1) & (idx <= T);
                if any(inBounds)
                    window(inBounds) = squeeze(X(p,s,c,idx(inBounds)));
                end

                eventWindows = [eventWindows; window]; %#ok<AGROW>
            end
        end
    end

    if ~isempty(eventWindows)
        per_participant(p,:) = mean(eventWindows, 1, 'omitnan');
        n_reversals_per_participant(p) = size(eventWindows,1);
    end
end

% Participant-locked group summary
meanTrace = mean(per_participant, 1, 'omitnan');
N         = sum(~isnan(per_participant), 1);
sd        = std(per_participant, 0, 1, 'omitnan');
semTrace  = sd ./ sqrt(N);

out = struct();
out.variable_name = variable_name;
out.cond_idx = cond_idx;
out.lags = lags;
out.per_participant = per_participant;
out.mean = meanTrace;
out.sem  = semTrace;
out.N    = N;
out.n_reversals_per_participant = n_reversals_per_participant;
end
