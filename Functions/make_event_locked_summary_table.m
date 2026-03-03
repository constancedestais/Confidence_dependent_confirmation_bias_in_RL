function tbl = make_event_locked_summary_table(out, pre, post, reference_lag)
%MAKE_EVENT_LOCKED_SUMMARY_TABLE  Summarize event-locked traces at selected lags with 95% CIs and paired tests.
%
%   builds a compact summary table for an event-locked, participant-locked analysis.
%
%   This function expects OUT to contain participant-level event-locked traces
%   (one row per participant). It then:
%       1) extracts the columns corresponding to REQUESTEDLAGS,
%       2) computes the across-participant mean at each lag,
%       3) computes the 95% confidence interval (CI) for the mean using the
%          Student t distribution (mean ± tcrit * SEM),
%       4) performs paired, one-sided t-tests comparing each lag to the
%          reversal trial ("t", i.e., lag 0), using participants as the unit
%          of observation.
%
%   The unit of inference is PARTICIPANTS (not events).
%   Missing samples (NaNs) are handled per-lag: participants contribute to a
%   lag only if both that lag and the baseline lag (t) are non-NaN.
%
%   INPUTS
%   ------
%   out : struct
%       Output of an event-locked extraction function (e.g.,
%       EXTRACT_EVENT_LOCKED_PARTICIPANT_TRACES). Must contain:
%           - out.lags            : 1 x nLags numeric vector of available lags
%           - out.perParticipant  : nParticipants x nLags numeric matrix
%                                  (participant-level event-locked traces)
%
%   pre: number 
%       number of trials included before reversal
%
%   post: number 
%       number of trials included after reversal
%
%   reference_lag: number 
%       reference trial against which to perform the one-sided t-tests
%       expressed in terms of lag, e.g. "-1" to compare to previous trial, or "0" for reversal trial
%
%   OUTPUT
%   ------
%   tbl : table
%       One row per lag, with the following columns:
%           - Lag           : string label ("t-1","t","t+1",...)
%           - LagValue      : numeric lag value
%           - N             : number of participants contributing to the mean at that lag
%           - Mean          : mean across participants at that lag
%           - CI95_Low      : lower bound of 95% CI of the mean
%           - CI95_High     : upper bound of 95% CI of the mean
%           - Mean_pm_95CI  : formatted string "mean ± halfCI"
%           - df_vs_t       : degrees of freedom for the paired t-test vs t (Npaired-1)
%           - t_vs_t        : t statistic for the paired comparison vs t
%           - p_vs_t        : one-sided p-value for the paired comparison vs t
%
%   NOTES / ASSUMPTIONS
%   -------------------
%   - REQUESTEDLAGS must include 0 (the reversal trial "t") because all tests
%     are performed vs lag 0. If 0 is missing, the function errors.
%   - 95% CI is computed using a t critical value with df = N-1 for each lag
%     separately (since N may differ by lag due to NaNs).
%   - The paired t-test at each lag uses only participants with non-NaN values
%     at BOTH the target lag and lag 0. Therefore df_vs_t can differ by lag.
%
%   EXAMPLES
%   --------
%   % After extracting participant traces:
%   out = extract_event_locked_participant_traces(d, "confidence_rating", [2 4], 4, 4);
%
%   % Create a table for t-1 through t+4; test whether post-reversal is lower than t:
%   tbl = make_event_locked_summary_table(out, [-1 0 1 2 3 4], "lower_than_t");
%   disp(tbl)
%

oneSidedMode = "lower_than_t";

% build requestedLags using pre and post
requestedLags = -pre:post;

% get columns corresponding trials/lags
[ok, cols] = ismember(requestedLags, out.lags);
if ~all(ok)
    missing = requestedLags(~ok);
    error('Requested lags not present in out.lags: %s. Increase pre/post.', mat2str(missing));
end
X = out.per_participant(:, cols); % [P x nRequested]

% Mean and 95% CI across participants
n   = sum(~isnan(X), 1);
mu  = mean(X, 1, 'omitnan');
sd  = std(X, 0, 1, 'omitnan');
sem = sd ./ sqrt(n);

tcrit = nan(size(n));
for k = 1:numel(n)
    if n(k) >= 2
        tcrit(k) = tinv(0.975, n(k)-1);
    end
end
ciHalf = tcrit .* sem;
ciLow  = mu - ciHalf;
ciHigh = mu + ciHalf;

% Pretty labels for common requested lags around t
lagLabel = strings(numel(requestedLags),1);
for i = 1:numel(requestedLags)
    L = requestedLags(i);
    if L < 0
        lagLabel(i) = "t" + string(L);    % e.g., t-1
    elseif L == 0
        lagLabel(i) = "t";
    else
        lagLabel(i) = "t+" + string(L);
    end
end

mean_pm_95CI = strings(numel(requestedLags),1);
for k = 1:numel(requestedLags)
    if isnan(mu(k)) || isnan(ciHalf(k))
        mean_pm_95CI(k) = "NaN";
    else
        mean_pm_95CI(k) = sprintf('%.2f ± %.2f', mu(k), ciHalf(k));
    end
end

% One-sided paired t-tests vs value at reference_lag 
idx_ref = find(requestedLags == reference_lag, 1);
if isempty(idx_ref)
    error('reference_lag (%g) must be included in requestedLags. requestedLags=%s', ...
        reference_lag, mat2str(requestedLags));
end

p_vs_t  = nan(numel(requestedLags),1);
t_vs_t  = nan(numel(requestedLags),1);
df_vs_t = nan(numel(requestedLags),1);

p_vs_ref  = nan(numel(requestedLags),1);
t_vs_ref  = nan(numel(requestedLags),1);
df_vs_ref = nan(numel(requestedLags),1);

for k = 1:numel(requestedLags)

    % OPTIONAL: skip testing the reference row against itself
    if k == idx_ref, continue; end

    a = X(:,k);        % lag k
    b = X(:,idx_ref);  % reference lag
    use = ~isnan(a) & ~isnan(b);

    if sum(use) >= 2 % if there are at least 2 non-NaN values, go ahead with test
        % paired, one-sided t-test: H1: x < ref; 
        [~, p, ~, stats] = ttest(a(use), b(use), 'Tail', 'left');
        %{
        switch one_sided_mode
            case 'lower_than_ref'   % H1: a < ref
                [~, p, ~, stats] = ttest(a(use), b(use), 'Tail', 'left');
            case 'higher_than_ref'  % H1: a > ref
                [~, p, ~, stats] = ttest(a(use), b(use), 'Tail', 'right');
            case 'different_from_ref' % two-sided
                [~, p, ~, stats] = ttest(a(use), b(use), 'Tail', 'both');
            otherwise
                error('Unknown one_sided_mode: %s', one_sided_mode);
        end
        %}

        p_vs_ref(k)  = p;
        t_vs_ref(k)  = stats.tstat;
        df_vs_ref(k) = stats.df;
    end
end



tbl = table( ...
    lagLabel, requestedLags(:), n(:), mu(:), ciLow(:), ciHigh(:), mean_pm_95CI, ...
    df_vs_ref, t_vs_ref, p_vs_ref, ...
    'VariableNames', { ...
        'Lag','LagValue','N','Mean','CI95_Low','CI95_High','Mean_pm_95CI', ...
        'df','t-value (one-sided t-test to ref)','p (one-sided t-test to ref)' ...
    } );
end
