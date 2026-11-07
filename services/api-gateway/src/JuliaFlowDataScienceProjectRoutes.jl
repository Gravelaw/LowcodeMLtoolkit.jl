module JuliaFlowDataScienceProjectRoutes

export match_project_route

const COLLECTION_PATH = ["api", "v1", "data-science-projects"]
const ACTIONS = Dict(
    ("transforms", "fit-apply") => :transform_fit_apply,
    ("statistical-analysis", "run") => :statistical_analysis,
    ("analysis", "profile") => :analysis_profile,
    ("analysis", "workspace") => :analysis_workspace,
    ("analysis", "export") => :analysis_export,
    ("tuning", "run") => :tuning,
    ("evaluation", "run") => :evaluation,
    ("predictions", "export") => :prediction_export,
    ("drift", "run") => :drift,
    ("models", "lifecycle") => :model_lifecycle,
)

function match_project_route(method::AbstractString, segments::AbstractVector{<:AbstractString})
    method == "GET" && segments == COLLECTION_PATH && return (action = :list, project_id = nothing)
    method == "POST" && segments == COLLECTION_PATH && return (action = :create, project_id = nothing)
    length(segments) >= 4 && segments[1:3] == COLLECTION_PATH || return nothing
    project_id = String(segments[4])
    length(segments) == 4 && method == "GET" && return (action = :get, project_id = project_id)
    length(segments) == 4 && method == "PUT" && return (action = :update, project_id = project_id)
    length(segments) == 6 && method == "POST" || return nothing
    action = get(ACTIONS, (String(segments[5]), String(segments[6])), nothing)
    return action === nothing ? nothing : (action = action, project_id = project_id)
end

end
