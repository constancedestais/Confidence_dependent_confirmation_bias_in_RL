function results = event_locked_participant_pipeline(d, variableNames, condIdx, pre, post, reference_lags)
% Compute event-locked, participant-locked summaries for multiple variables.
%
% Inputs:
%   d            : struct holding variables as arrays [P x S x C x T]
%   variableNames: string array of field names in d, e.g. ["confidence_rating","correct"]
%   condIdx      : scalar or vector of conditions to include (event-weighted pooling)
%   pre, post    : window size around reversal
%
% Output:
%   results.<varName> : struct with fields:
%       lags, perParticipant, mean, sem, N
%       summaryTable (t-1, t, t+1..t+4) with 95% CI and 1-sided paired t-tests vs t

% CONSTANCE
% this loops over variable_names and returns a struct like results.<var_name> = out
% helpful if you routinely compute many variables at once and want one object back

if nargin < 3 || isempty(condIdx)
    % default: include all conditions found in the data
    dataAny = d.(variableNames(1));
    condIdx = 1:size(dataAny, 3);
end

results = struct();

for v = 1:numel(variableNames)
    varName = variableNames(v);
    reference_lag = reference_lags(v);

    % Extract participant-level traces (event-weighted within participant)
    out = extract_event_locked_participant_traces(d, varName, condIdx, pre, post);

    % Add summary table with one-sided tests vs reversal trial (lag 0)
    out.summaryTable = make_event_locked_summary_table(out, pre, post, reference_lag);

    results.(varName) = out;
end
end
