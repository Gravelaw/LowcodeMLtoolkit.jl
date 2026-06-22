module JuliaFlowDataScienceProjectLocalSources

export local_data_import_audit_source_details,
    local_data_import_roots,
    local_data_import_sample,
    local_data_ref_path_for_write,
    path_within_root,
    resolve_local_data_ref_path,
    sensitive_import_path,
    split_env_paths,
    validate_local_data_import_file!,
    validate_local_data_import_sample!,
    validate_local_data_import_source!

function split_env_paths(value::AbstractString)
    separator = Sys.iswindows() ? ';' : ':'
    return [strip(path) for path in split(String(value), separator) if !isempty(strip(path))]
end

function local_data_import_roots(local_home::AbstractString, data_root::AbstractString; import_roots = get(ENV, "JULIAFLOW_IMPORT_ROOTS", ""))
    roots = String[String(data_root)]
    if !isempty(strip(String(import_roots)))
        append!(roots, split_env_paths(String(import_roots)))
    end
    normalized = String[]
    for root in roots
        isempty(strip(root)) && continue
        path = normpath(abspath(root))
        path in normalized || push!(normalized, path)
    end
    return normalized
end

function path_within_root(path::AbstractString, root::AbstractString)
    relative = relpath(path, root)
    parts = splitpath(relative)
    return !isabspath(relative) && !isempty(parts) && first(parts) != ".."
end

function sensitive_import_path(path::AbstractString)
    filename = lowercase(basename(path))
    sensitive_names = Set([".env", "id_rsa", "id_dsa", "id_ecdsa", "id_ed25519", "credentials", "credentials.json", "secrets.json"])
    filename in sensitive_names && return true
    return occursin("secret", filename) || occursin("password", filename) || occursin("token", filename) || occursin("credential", filename)
end

function local_data_import_sample(path::AbstractString; max_bytes::Integer = 16_384)
    open(path, "r") do io
        bytes = read(io, min(max_bytes, filesize(path)))
        try
            return lowercase(String(copy(bytes)))
        catch
            error("local data import source sample is not valid UTF-8 text")
        end
    end
end

function validate_local_data_import_sample!(path::AbstractString)
    sample = local_data_import_sample(path)
    credential_markers = [
        "api_key",
        "apikey",
        "access_token",
        "refresh_token",
        "secret_key",
        "client_secret",
        "private_key",
        "password",
        "authorization:",
        "bearer ",
    ]
    any(marker -> occursin(marker, sample), credential_markers) && error("local data import source appears to contain credential content")
    pii_markers = [
        "ssn",
        "social_security",
        "passport",
        "driver_license",
        "credit_card",
        "card_number",
        "date_of_birth",
        "dob",
    ]
    any(marker -> occursin(marker, sample), pii_markers) && error("local data import source appears to contain sensitive PII columns")
    return nothing
end

function normalized_import_format(source_format::AbstractString)
    normalized = lowercase(strip(String(source_format)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return "csv"
    return first(normalized, min(lastindex(normalized), 80))
end

function validate_local_data_import_file!(path::AbstractString, source_format::AbstractString; max_bytes::Integer)
    sensitive_import_path(path) && error("local data import source appears to contain credentials or secrets")
    size = filesize(path)
    size > 0 || error("local data import source file is empty")
    size <= max_bytes || error("local data import source file exceeds size limit")
    format = normalized_import_format(source_format)
    allowed_formats = Set(["csv", "json", "jsonl", "parquet", "arrow_ipc", "arrow", "ipc", "feather"])
    format in allowed_formats || error("local data import format must be csv, json, jsonl, parquet, arrow_ipc, arrow, ipc, or feather")
    extension = lowercase(splitext(path)[2])
    allowed_extensions = Set([".csv", ".json", ".jsonl", ".parquet", ".arrow", ".ipc", ".feather"])
    extension in allowed_extensions || error("local data import source extension is not supported")
    extension in Set([".csv", ".json", ".jsonl"]) && validate_local_data_import_sample!(path)
    return nothing
end

function validate_local_data_import_source!(
    source_uri::AbstractString;
    local_home::AbstractString,
    data_root::AbstractString,
    validate_local_ref::Function,
    import_roots = get(ENV, "JULIAFLOW_IMPORT_ROOTS", ""),
)
    uri = strip(String(source_uri))
    isempty(uri) && error("local data import sourceUri cannot be empty")
    (occursin('\0', uri) || occursin('\n', uri) || occursin('\r', uri)) && error("local data import sourceUri contains invalid characters")
    normalized = replace(uri, "\\" => "/")
    lower = lowercase(normalized)
    if startswith(lower, "local://")
        validate_local_ref(uri, "import sourceUri")
        return uri
    end
    occursin(r"^[a-z][a-z0-9+.-]*://"i, uri) && error("local data import sourceUri must be a local file path or local:// managed artifact ref")
    isfile(uri) || error("local data import source file not found")
    source_path = realpath(uri)
    roots = [realpath(root) for root in local_data_import_roots(local_home, data_root; import_roots) if isdir(root)]
    isempty(roots) && error("local data import root not configured")
    any(root -> path_within_root(source_path, root), roots) || error("local data import source escapes allowed import roots")
    return source_path
end

function local_data_import_audit_source_details(source_uri)
    details = Dict{String,Any}("sourceKind" => "managed")
    source_uri === nothing && return details
    uri = strip(String(source_uri))
    isempty(uri) && return Dict{String,Any}("sourceKind" => "empty")
    normalized = replace(uri, "\\" => "/")
    lower = lowercase(normalized)
    if startswith(lower, "local://")
        details["sourceKind"] = "managed"
        details["sourceRef"] = uri
        return details
    end
    if occursin(r"^[a-z][a-z0-9+.-]*://"i, uri)
        details["sourceKind"] = "remote"
        details["scheme"] = first(split(uri, "://"))
        return details
    end
    details["sourceKind"] = "file"
    details["sourceBasename"] = basename(uri)
    details["sourceExtension"] = lowercase(splitext(uri)[2])
    if isfile(uri)
        details["sourceBytes"] = filesize(uri)
    end
    return details
end

function resolve_local_data_ref_path(
    source_ref::AbstractString;
    local_home::AbstractString,
    data_root::AbstractString,
    validate_local_ref::Function,
)
    ref = strip(String(source_ref))
    normalized = replace(ref, "\\" => "/")
    lower = lowercase(normalized)
    startswith(lower, "local://data/") || return nothing
    validate_local_ref(ref, "dataset sourceUri")
    relative = normalized[nextind(normalized, firstindex(normalized), length("local://data/")):end]
    isempty(strip(relative, ['/'])) && return nothing
    isdir(data_root) || return nothing
    root = realpath(data_root)
    candidate = normpath(joinpath(root, split(relative, '/'; keepempty = false)...))
    path_within_root(candidate, root) || error("statistical analysis dataset source escapes local data estate")
    return isfile(candidate) ? candidate : nothing
end

function local_data_ref_path_for_write(
    local_ref::AbstractString;
    local_home::AbstractString,
    data_root::AbstractString,
    validate_local_ref::Function,
)
    ref = strip(String(local_ref))
    normalized = replace(ref, "\\" => "/")
    startswith(lowercase(normalized), "local://") || error("local artifact ref must use local://")
    validate_local_ref(ref, "artifactRef")
    relative = normalized[nextind(normalized, firstindex(normalized), length("local://")):end]
    mkpath(data_root)
    root = realpath(data_root)
    candidate = normpath(joinpath(root, split(relative, '/'; keepempty = false)...))
    path_within_root(candidate, root) || error("local artifact ref escapes local data estate")
    return candidate
end

end
