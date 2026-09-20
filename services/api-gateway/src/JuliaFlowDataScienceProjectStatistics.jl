module JuliaFlowDataScienceProjectStatistics

export local_csv_statistical_evidence_from_path,
    statistical_analysis_code_artifact,
    statistical_analysis_methods,
    requested_feature_columns,
    parse_simple_csv,
    simple_numeric_columns,
    candidate_numeric_feature_columns,
    sample_mean,
    sample_std,
    pearson_correlation,
    spearman_correlation,
    simple_linear_ols,
    simple_multi_linear_ols,
    simple_binary_centroid_classifier,
    binary_centroid_probabilities,
    two_sample_t_test,
    one_way_anova,
    chi_square_independence

const STATISTICAL_ANALYSIS_METHODS = Set([
    "summary",
    "correlation",
    "pearson_correlation",
    "spearman_correlation",
    "t_test",
    "chi_square",
    "anova",
    "ols",
])

function safe_statistical_method_id(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "_")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return ""
    return first(normalized, min(lastindex(normalized), 80))
end

function statistical_analysis_methods(body::AbstractDict)
    raw_methods = haskey(body, "methods") ? body["methods"] : ["summary", "correlation"]
    raw_methods isa AbstractVector || error("statistical analysis methods must be an array")
    methods = [safe_statistical_method_id(String(method)) for method in raw_methods]
    methods = [method for method in methods if !isempty(method)]
    isempty(methods) && error("statistical analysis method required")
    unsupported = [method for method in methods if !(method in STATISTICAL_ANALYSIS_METHODS)]
    isempty(unsupported) || error("statistical analysis unsupported methods: $(join(unsupported, ", "))")
    return methods
end

function parse_simple_csv(path::AbstractString; max_rows::Integer = 1_000)
    lines = readlines(path)
    isempty(lines) && return nothing
    headers = [strip(header) for header in split(first(lines), ',')]
    isempty(headers) && return nothing
    rows = Vector{Vector{String}}()
    for line in Iterators.take(lines[2:end], max_rows)
        isempty(strip(line)) && continue
        values = [strip(value) for value in split(line, ',')]
        length(values) < length(headers) && append!(values, fill("", length(headers) - length(values)))
        push!(rows, values[1:length(headers)])
    end
    return Dict{String,Any}("headers" => headers, "rows" => rows)
end

function simple_numeric_columns(table::AbstractDict)
    headers = Vector{String}(table["headers"])
    rows = table["rows"]
    columns = Dict{String,Vector{Float64}}()
    missing_counts = Dict{String,Int}()
    for (index, header) in enumerate(headers)
        values = Float64[]
        missing_count = 0
        nonmissing_count = 0
        numeric = true
        for row in rows
            value = strip(String(row[index]))
            if isempty(value) || lowercase(value) in ("missing", "na", "null", "nothing")
                missing_count += 1
                continue
            end
            nonmissing_count += 1
            parsed = tryparse(Float64, value)
            if parsed === nothing || !isfinite(parsed)
                numeric = false
                break
            end
            push!(values, parsed)
        end
        if numeric && nonmissing_count > 0
            columns[header] = values
            missing_counts[header] = missing_count
        end
    end
    return columns, missing_counts
end

function candidate_numeric_feature_columns(numeric_columns::AbstractDict, target_column::AbstractString; max_features::Integer = 5)
    target = String(target_column)
    function eligible(column)
        normalized = lowercase(strip(String(column)))
        column != target || return false
        normalized in ("id", "row_id", "index", "rowindex", "row_number") && return false
        endswith(normalized, "_id") && return false
        endswith(normalized, "-id") && return false
        return true
    end
    features = sort([String(column) for column in keys(numeric_columns) if eligible(String(column))])
    return first(features, min(Int(max_features), length(features)))
end

function simple_column_values(table::AbstractDict, column::AbstractString)
    headers = Vector{String}(table["headers"])
    column_index = findfirst(header -> header == String(column), headers)
    column_index === nothing && return String[]
    return [String(strip(String(row[column_index]))) for row in table["rows"]]
end

function sample_mean(values::Vector{Float64})
    return isempty(values) ? 0.0 : sum(values) / length(values)
end

function sample_std(values::Vector{Float64})
    length(values) <= 1 && return 0.0
    mean_value = sample_mean(values)
    return sqrt(sum((value - mean_value)^2 for value in values) / (length(values) - 1))
end

function pearson_correlation(left::Vector{Float64}, right::Vector{Float64})
    n = min(length(left), length(right))
    n <= 1 && return 0.0
    left_values = left[1:n]
    right_values = right[1:n]
    left_mean = sample_mean(left_values)
    right_mean = sample_mean(right_values)
    numerator = sum((left_values[index] - left_mean) * (right_values[index] - right_mean) for index in 1:n)
    left_denominator = sqrt(sum((value - left_mean)^2 for value in left_values))
    right_denominator = sqrt(sum((value - right_mean)^2 for value in right_values))
    denominator = left_denominator * right_denominator
    denominator == 0.0 && return 0.0
    return round(numerator / denominator; digits = 6)
end

function rank_values(values::Vector{Float64})
    indexed = sort(collect(enumerate(values)); by = item -> item[2])
    ranks = zeros(Float64, length(values))
    index = 1
    while index <= length(indexed)
        next_index = index
        while next_index < length(indexed) && indexed[next_index + 1][2] == indexed[index][2]
            next_index += 1
        end
        rank = (index + next_index) / 2
        for grouped_index in index:next_index
            ranks[indexed[grouped_index][1]] = rank
        end
        index = next_index + 1
    end
    return ranks
end

function spearman_correlation(left::Vector{Float64}, right::Vector{Float64})
    n = min(length(left), length(right))
    n <= 1 && return 0.0
    return pearson_correlation(rank_values(left[1:n]), rank_values(right[1:n]))
end

function simple_linear_ols(target::Vector{Float64}, feature::Vector{Float64})
    n = min(length(target), length(feature))
    n <= 1 && return nothing
    y = target[1:n]
    x = feature[1:n]
    x_mean = sample_mean(x)
    y_mean = sample_mean(y)
    ssx = sum((value - x_mean)^2 for value in x)
    ssx == 0.0 && return nothing
    slope = sum((x[index] - x_mean) * (y[index] - y_mean) for index in 1:n) / ssx
    intercept = y_mean - slope * x_mean
    predictions = [intercept + slope * value for value in x]
    residuals = [y[index] - predictions[index] for index in 1:n]
    sse = sum(value^2 for value in residuals)
    sst = sum((value - y_mean)^2 for value in y)
    r_squared = sst == 0.0 ? 0.0 : 1.0 - (sse / sst)
    return Dict{String,Any}(
        "model" => "simple_linear_ols",
        "n" => n,
        "intercept" => round(intercept; digits = 6),
        "slope" => round(slope; digits = 6),
        "rSquared" => round(r_squared; digits = 6),
        "sse" => round(sse; digits = 6),
    )
end

function simple_multi_linear_ols(target::Vector{Float64}, features::AbstractVector{<:Pair})
    isempty(features) && return nothing
    n = length(target)
    for pair in features
        n = min(n, length(pair.second))
    end
    feature_count = length(features)
    n <= 1 && return nothing
    y = target[1:n]
    x = zeros(Float64, n, feature_count + 1)
    x[:, 1] .= 1.0
    for (feature_index, pair) in enumerate(features)
        values = pair.second
        for row in 1:n
            x[row, feature_index + 1] = values[row]
        end
    end
    xtx = transpose(x) * x
    for index in 1:size(xtx, 1)
        xtx[index, index] += 1.0e-8
    end
    beta = xtx \ (transpose(x) * y)
    predictions = x * beta
    residuals = [y[index] - predictions[index] for index in 1:n]
    sse = sum(value^2 for value in residuals)
    y_mean = sample_mean(y)
    sst = sum((value - y_mean)^2 for value in y)
    r_squared = sst == 0.0 ? 0.0 : 1.0 - (sse / sst)
    feature_names = [String(pair.first) for pair in features]
    slopes = Dict{String,Any}(
        feature_names[index] => round(beta[index + 1]; digits = 6)
        for index in eachindex(feature_names)
    )
    return Dict{String,Any}(
        "model" => feature_count == 1 ? "simple_linear_ols" : "simple_multi_linear_ols",
        "n" => n,
        "featureColumns" => feature_names,
        "intercept" => round(beta[1]; digits = 6),
        "slopes" => slopes,
        "rSquared" => round(r_squared; digits = 6),
        "sse" => round(sse; digits = 6),
    )
end

function simple_binary_centroid_classifier(target::Vector{Float64}, features::AbstractVector{<:Pair})
    isempty(features) && return nothing
    n = length(target)
    for pair in features
        n = min(n, length(pair.second))
    end
    n <= 1 && return nothing
    labels = sort(unique(target[1:n]))
    length(labels) == 2 || return nothing
    negative_label = labels[1]
    positive_label = labels[2]
    positive_indices = [index for index in 1:n if target[index] == positive_label]
    negative_indices = [index for index in 1:n if target[index] == negative_label]
    (isempty(positive_indices) || isempty(negative_indices)) && return nothing
    feature_names = [String(pair.first) for pair in features]
    positive_means = Dict{String,Any}()
    negative_means = Dict{String,Any}()
    scales = Dict{String,Any}()
    for pair in features
        name = String(pair.first)
        values = pair.second[1:n]
        positive_mean = sample_mean(values[positive_indices])
        negative_mean = sample_mean(values[negative_indices])
        positive_means[name] = round(positive_mean; digits = 6)
        negative_means[name] = round(negative_mean; digits = 6)
        scales[name] = round(max(abs(positive_mean - negative_mean), sample_std(values), 1.0e-6); digits = 6)
    end
    prior = length(positive_indices) / n
    prior = min(max(prior, 1.0e-6), 1.0 - 1.0e-6)
    model = Dict{String,Any}(
        "model" => "simple_binary_centroid_classifier",
        "n" => n,
        "featureColumns" => feature_names,
        "negativeLabel" => negative_label,
        "positiveLabel" => positive_label,
        "positivePrior" => round(prior; digits = 6),
        "positiveMeans" => positive_means,
        "negativeMeans" => negative_means,
        "featureScales" => scales,
    )
    probabilities = binary_centroid_probabilities(model, features, 1:n)
    predictions = [probability >= 0.5 ? positive_label : negative_label for probability in probabilities]
    accuracy = sum(predictions[index] == target[index] for index in 1:n) / n
    model["trainAccuracy"] = round(accuracy; digits = 6)
    return model
end

function binary_centroid_probabilities(model::AbstractDict, features::AbstractVector{<:Pair}, rows)
    feature_map = Dict(String(pair.first) => pair.second for pair in features)
    feature_columns = [String(column) for column in get(model, "featureColumns", String[])]
    isempty(feature_columns) && return Float64[]
    positive_means = get(model, "positiveMeans", Dict{String,Any}())
    negative_means = get(model, "negativeMeans", Dict{String,Any}())
    scales = get(model, "featureScales", Dict{String,Any}())
    prior = min(max(Float64(get(model, "positivePrior", 0.5)), 1.0e-6), 1.0 - 1.0e-6)
    intercept = log(prior / (1.0 - prior))
    probabilities = Float64[]
    for row in rows
        score = intercept
        usable = 0
        for column in feature_columns
            haskey(feature_map, column) || continue
            values = feature_map[column]
            index = min(Int(row), length(values))
            positive_mean = Float64(get(positive_means, column, 0.0))
            negative_mean = Float64(get(negative_means, column, 0.0))
            midpoint = (positive_mean + negative_mean) / 2
            direction = positive_mean >= negative_mean ? 1.0 : -1.0
            scale = max(Float64(get(scales, column, 1.0)), 1.0e-6)
            score += direction * (Float64(values[index]) - midpoint) / scale
            usable += 1
        end
        usable > 0 && (score /= usable)
        push!(probabilities, round(1.0 / (1.0 + exp(-score)); digits = 6))
    end
    return probabilities
end

function two_sample_t_test(target_values::Vector{Float64}, group_values::AbstractVector)
    n = min(length(target_values), length(group_values))
    n <= 2 && return nothing
    groups = Dict{String,Vector{Float64}}()
    for index in 1:n
        group = isempty(group_values[index]) ? "(missing)" : String(group_values[index])
        push!(get!(groups, group, Float64[]), target_values[index])
    end
    length(groups) == 2 || return nothing
    ordered_groups = sort(collect(keys(groups)))
    left = groups[ordered_groups[1]]
    right = groups[ordered_groups[2]]
    (length(left) <= 1 || length(right) <= 1) && return nothing
    left_mean = sample_mean(left)
    right_mean = sample_mean(right)
    standard_error = sqrt(sample_std(left)^2 / length(left) + sample_std(right)^2 / length(right))
    standard_error == 0.0 && return nothing
    return Dict{String,Any}(
        "method" => "welch_t_test",
        "groups" => ordered_groups,
        "n" => Dict(ordered_groups[1] => length(left), ordered_groups[2] => length(right)),
        "mean" => Dict(ordered_groups[1] => round(left_mean; digits = 6), ordered_groups[2] => round(right_mean; digits = 6)),
        "meanDifference" => round(left_mean - right_mean; digits = 6),
        "tStatistic" => round((left_mean - right_mean) / standard_error; digits = 6),
    )
end

function one_way_anova(target_values::Vector{Float64}, group_values::AbstractVector)
    n = min(length(target_values), length(group_values))
    n <= 1 && return nothing
    groups = Dict{String,Vector{Float64}}()
    for index in 1:n
        group = isempty(group_values[index]) ? "(missing)" : String(group_values[index])
        push!(get!(groups, group, Float64[]), target_values[index])
    end
    length(groups) <= 1 && return nothing
    overall = sample_mean(target_values[1:n])
    group_value_vectors = collect(values(groups))
    ss_between = sum(length(group_values) * (sample_mean(group_values) - overall)^2 for group_values in group_value_vectors)
    ss_within = sum(sum((value - sample_mean(group_values))^2 for value in group_values) for group_values in group_value_vectors)
    df_between = length(groups) - 1
    df_within = n - length(groups)
    df_within <= 0 && return nothing
    ms_between = ss_between / df_between
    ms_within = ss_within / df_within
    f_statistic = ms_within == 0.0 ? 0.0 : ms_between / ms_within
    return Dict{String,Any}(
        "method" => "one_way_anova",
        "n" => n,
        "groups" => sort(collect(keys(groups))),
        "dfBetween" => df_between,
        "dfWithin" => df_within,
        "fStatistic" => round(f_statistic; digits = 6),
        "ssBetween" => round(ss_between; digits = 6),
        "ssWithin" => round(ss_within; digits = 6),
    )
end

function chi_square_independence(left_values::AbstractVector, right_values::AbstractVector)
    n = min(length(left_values), length(right_values))
    n <= 1 && return nothing
    left_levels = sort(unique([isempty(String(value)) ? "(missing)" : String(value) for value in left_values[1:n]]))
    right_levels = sort(unique([isempty(String(value)) ? "(missing)" : String(value) for value in right_values[1:n]]))
    (length(left_levels) <= 1 || length(right_levels) <= 1) && return nothing
    observed = [0 for _ in left_levels, _ in right_levels]
    left_index = Dict(level => index for (index, level) in enumerate(left_levels))
    right_index = Dict(level => index for (index, level) in enumerate(right_levels))
    for index in 1:n
        left = isempty(String(left_values[index])) ? "(missing)" : String(left_values[index])
        right = isempty(String(right_values[index])) ? "(missing)" : String(right_values[index])
        observed[left_index[left], right_index[right]] += 1
    end
    row_totals = [sum(observed[row, :]) for row in 1:length(left_levels)]
    column_totals = [sum(observed[:, column]) for column in 1:length(right_levels)]
    statistic = 0.0
    for row in 1:length(left_levels), column in 1:length(right_levels)
        expected = row_totals[row] * column_totals[column] / n
        expected == 0.0 && continue
        statistic += (observed[row, column] - expected)^2 / expected
    end
    return Dict{String,Any}(
        "method" => "chi_square_independence",
        "n" => n,
        "leftLevels" => left_levels,
        "rightLevels" => right_levels,
        "degreesOfFreedom" => (length(left_levels) - 1) * (length(right_levels) - 1),
        "chiSquareStatistic" => round(statistic; digits = 6),
        "observed" => observed,
    )
end

function requested_feature_columns(body::AbstractDict)
    raw_features = haskey(body, "featureColumns") ? body["featureColumns"] : Any[]
    raw_features isa AbstractVector || return String[]
    return [String(feature) for feature in raw_features if !isempty(strip(String(feature)))]
end

function local_csv_statistical_evidence_from_path(
    dataset::AbstractDict,
    source_path::AbstractString,
    body::AbstractDict,
    methods::AbstractVector,
)
    table = parse_simple_csv(source_path)
    table === nothing && return nothing
    numeric_columns, missing_counts = simple_numeric_columns(table)
    isempty(numeric_columns) && return nothing
    summaries = [
        Dict(
            "column" => column,
            "count" => length(values),
            "missingCount" => get(missing_counts, column, 0),
            "mean" => round(sample_mean(values); digits = 6),
            "std" => round(sample_std(values); digits = 6),
            "min" => minimum(values),
            "max" => maximum(values),
        ) for (column, values) in sort(collect(numeric_columns); by = item -> item[1])
    ]
    ordered_columns = [String(summary["column"]) for summary in summaries]
    correlations = [
        [left == right ? 1.0 : pearson_correlation(numeric_columns[left], numeric_columns[right]) for right in ordered_columns]
        for left in ordered_columns
    ]
    spearman = [
        [left == right ? 1.0 : spearman_correlation(numeric_columns[left], numeric_columns[right]) for right in ordered_columns]
        for left in ordered_columns
    ]
    target_column = haskey(body, "targetColumn") ? String(body["targetColumn"]) : ""
    feature_columns = requested_feature_columns(body)
    inferential = Dict{String,Any}()
    categorical_features = [feature for feature in feature_columns if feature in Vector{String}(table["headers"]) && !haskey(numeric_columns, feature)]
    if !isempty(target_column) && haskey(numeric_columns, target_column)
        numeric_features = [feature for feature in feature_columns if haskey(numeric_columns, feature) && feature != target_column]
        if "ols" in methods && !isempty(numeric_features)
            ols = simple_linear_ols(numeric_columns[target_column], numeric_columns[first(numeric_features)])
            ols === nothing || (inferential["ols"] = merge(ols, Dict("targetColumn" => target_column, "featureColumn" => first(numeric_features))))
        end
        if "anova" in methods && !isempty(categorical_features)
            anova = one_way_anova(numeric_columns[target_column], simple_column_values(table, first(categorical_features)))
            anova === nothing || (inferential["anova"] = merge(anova, Dict("targetColumn" => target_column, "groupColumn" => first(categorical_features))))
        end
        if "t_test" in methods && !isempty(categorical_features)
            t_test = two_sample_t_test(numeric_columns[target_column], simple_column_values(table, first(categorical_features)))
            t_test === nothing || (inferential["tTest"] = merge(t_test, Dict("targetColumn" => target_column, "groupColumn" => first(categorical_features))))
        end
    end
    if "chi_square" in methods && length(categorical_features) >= 2
        chi_square = chi_square_independence(simple_column_values(table, categorical_features[1]), simple_column_values(table, categorical_features[2]))
        chi_square === nothing || (inferential["chiSquare"] = merge(chi_square, Dict("leftColumn" => categorical_features[1], "rightColumn" => categorical_features[2])))
    end
    if "spearman_correlation" in methods
        inferential["spearmanCorrelation"] = Dict(
            "method" => "spearman_correlation",
            "columns" => ordered_columns,
            "matrix" => spearman,
        )
    end
    return Dict{String,Any}(
        "executionMode" => "local_csv",
        "sourceKind" => "managed_local_csv",
        "sourceRef" => String(get(dataset, "sourceUri", "")),
        "rowCount" => length(table["rows"]),
        "numericColumns" => ordered_columns,
        "summaries" => summaries,
        "correlationMatrix" => correlations,
        "spearmanCorrelationMatrix" => spearman,
        "inferentialTests" => inferential,
    )
end

function statistical_analysis_code_artifact(dataset_id::AbstractString, methods::AbstractVector, body::AbstractDict)
    target = haskey(body, "targetColumn") ? String(body["targetColumn"]) : ""
    features = requested_feature_columns(body)
    return join(
        [
            "# JuliaFlow local statistical EDA artifact",
            "# dataset: $(dataset_id)",
            "# methods: $(join([String(method) for method in methods], ", "))",
            "# targetColumn: $(target)",
            "# featureColumns: $(join(features, ", "))",
            "using Statistics",
            "# Result evidence is persisted beside this code artifact as results.json.",
        ],
        "\n",
    ) * "\n"
end

end
