module JuliaFlowDataScienceProjectLocalSources

using SHA

export local_data_import_audit_source_details,
    local_data_import_redaction_preview,
    local_data_import_roots,
    local_data_import_sample,
    local_artifact_checksum,
    write_local_artifact!,
    materialize_profile_source!,
    local_data_ref_path_for_write,
    confined_data_estate_path,
    path_within_root,
    resolve_local_data_ref_path,
    sensitive_import_path,
    split_env_paths,
    validate_local_data_import_file!,
    validate_local_data_import_connector_policy!,
    validate_local_data_import_sample!,
    validate_local_data_import_source!,
    validate_source_identifier!

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

function normalized_filesystem_path(path::AbstractString)
    normalized = replace(normpath(abspath(path)), "\\" => "/")
    return Sys.iswindows() ? lowercase(normalized) : normalized
end

function canonical_data_estate_root(root::AbstractString)
    candidate = normpath(abspath(root))
    missing = String[]
    # The configured root may itself be an intentional alias or not yet exist.
    for _ in 1:length(splitpath(candidate))
        isdir(candidate) && return normpath(joinpath(realpath(candidate), reverse(missing)...))
        (ispath(candidate) || islink(candidate)) && error("local data estate root must be a directory")
        push!(missing, basename(candidate))
        candidate = dirname(candidate)
    end
    error("local data estate root cannot be resolved")
end

function confined_data_estate_path(root::AbstractString, relative::AbstractString)
    normalized = replace(String(relative), "\\" => "/")
    (isabspath(normalized) || occursin(':', normalized) || any(c -> c in ('\0', '\r', '\n'), normalized)) &&
        error("local artifact path must be relative to the data estate")
    parts = split(normalized, '/'; keepempty = false)
    ".." in parts && error("local artifact path escapes local data estate")
    root_path = canonical_data_estate_root(root)
    candidate = root_path
    for part in parts
        part == "." && continue
        candidate = joinpath(candidate, part)
        # Check every existing parent, including dangling links, before creating outputs.
        islink(candidate) && error("local artifact path cannot contain a symlink or junction")
        if ispath(candidate)
            resolved = realpath(candidate)
            path_within_root(resolved, root_path) || error("local artifact path escapes local data estate")
            normalized_filesystem_path(candidate) == normalized_filesystem_path(resolved) ||
                error("local artifact path cannot contain a symlink or junction")
        end
    end
    path_within_root(candidate, root_path) || error("local artifact path escapes local data estate")
    return candidate
end

function sensitive_import_path(path::AbstractString)
    filename = lowercase(basename(path))
    sensitive_names = Set([".env", "id_rsa", "id_dsa", "id_ecdsa", "id_ed25519", "credentials", "credentials.json", "secrets.json"])
    filename in sensitive_names && return true
    return occursin("secret", filename) || occursin("password", filename) || occursin("token", filename) || occursin("credential", filename)
end

function validate_source_identifier!(value::AbstractString, label::AbstractString)
    identifier = String(value)
    isempty(identifier) && error("$(label) cannot be empty")
    ncodeunits(identifier) <= 63 || error("$(label) must be 63 bytes or fewer")
    occursin(r"^[A-Za-z_][A-Za-z0-9_]*$", identifier) || error("$(label) must use only letters, numbers, and underscores, and must not start with a number")
    return identifier
end

function validate_local_data_import_connector_policy!(body::AbstractDict, source_uri::AbstractString)
    normalized_source = lowercase(replace(strip(String(source_uri)), "\\" => "/"))
    managed_source = startswith(normalized_source, "local://")
    default_connector = managed_source ? "managed_local" : "local_file"
    connector = lowercase(String(get(body, "connector", default_connector)))
    connector in Set(["managed_local", "local_file", "duckdb", "postgresql", "disabled_remote"]) ||
        error("local data import connector is not supported")
    if connector == "managed_local"
        managed_source || error("managed_local connector requires a local:// sourceUri")
    elseif connector == "local_file"
        managed_source && error("local_file connector requires a filesystem sourceUri")
        occursin(r"^[a-z][a-z0-9+.-]*://"i, normalized_source) && error("local_file connector requires a filesystem sourceUri")
    elseif connector == "postgresql"
        haskey(body, "databaseSchema") || error("PostgreSQL databaseSchema is required")
        haskey(body, "databaseTable") || error("PostgreSQL databaseTable is required")
        validate_source_identifier!(String(body["databaseSchema"]), "PostgreSQL source schema")
        validate_source_identifier!(String(body["databaseTable"]), "PostgreSQL source table")
        error("PostgreSQL local source import is unavailable until query execution and redacted connection evidence are implemented")
    elseif connector == "duckdb"
        error("DuckDB source import is unavailable; import a managed local file and use the project DuckDB read mode")
    elseif haskey(body, "databaseSchema") || haskey(body, "databaseTable")
        error("databaseSchema and databaseTable are only available for PostgreSQL local source imports")
    end
    connector == "disabled_remote" && error("remote/provider source connectors are unavailable in local-appliance mode")
    return connector
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

function local_artifact_checksum(path::AbstractString)
    isfile(path) || error("local artifact file not found")
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

function write_local_artifact!(path::AbstractString, content::AbstractString)
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, content)
    end
    return Dict{String,Any}(
        "checksumSha256" => local_artifact_checksum(path),
        "sizeBytes" => filesize(path),
        "checksumMode" => "streaming_file_sha256",
    )
end

"""
    materialize_profile_source!(source_path, checksum; data_root, zone, max_bytes)

Copy bounded, checksum-verified source bytes to a confined content-addressed CSV.
Reuse an existing matching copy, reject conflicts, and return its managed reference.
The original source is never changed; temporary output is removed on failure.
"""
function materialize_profile_source!(source_path::AbstractString, checksum::AbstractString;
    data_root::AbstractString, zone::AbstractString, max_bytes::Integer)
    occursin(r"^[0-9a-f]{64}$", checksum) || error("local data import invalid source checksum")
    occursin(r"^[A-Za-z0-9_-]+$", zone) || error("local data import invalid target zone")
    content = open(source_path, "r") do io
        read(io, max_bytes + 1)
    end
    length(content) <= max_bytes || error("local data import CSV profile supports files up to 8 MiB")
    bytes2hex(sha256(content)) == checksum || error("source evidence unavailable: source changed before managed copy")
    relative = "$(zone)/imports/$(checksum).csv"
    destination = confined_data_estate_path(data_root, relative)
    if isfile(destination)
        local_artifact_checksum(destination) == checksum || error("source evidence unavailable: managed CSV checksum conflict")
        return "local://data/$(relative)"
    end
    mkpath(dirname(destination))
    temporary, io = mktemp(dirname(destination))
    try
        write(io, content)
        close(io)
        confined_data_estate_path(data_root, relative) == destination || error("local data import destination changed")
        mv(temporary, destination; force = false)
    finally
        isopen(io) && close(io)
        isfile(temporary) && rm(temporary)
    end
    return "local://data/$(relative)"
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
    requested_path = normpath(abspath(uri))
    source_path = realpath(uri)
    normalized_filesystem_path(requested_path) == normalized_filesystem_path(source_path) || error("local data import source cannot be a symlink or junction")
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

function local_data_import_redaction_preview(source_uri)
    preview = Dict{String,Any}(
        "fullPathRedacted" => true,
        "sampleValuesRedacted" => true,
        "recordedFields" => ["sourceKind"],
    )
    source_uri === nothing && return preview
    uri = strip(String(source_uri))
    isempty(uri) && return preview
    normalized = replace(uri, "\\" => "/")
    lower = lowercase(normalized)
    if startswith(lower, "local://")
        preview["recordedFields"] = ["sourceKind", "sourceRef"]
        preview["sourceRefPolicy"] = "managed-local-ref-only"
        return preview
    end
    if occursin(r"^[a-z][a-z0-9+.-]*://"i, uri)
        preview["recordedFields"] = ["sourceKind", "scheme"]
        preview["sourceRefPolicy"] = "remote-uri-redacted"
        return preview
    end
    preview["recordedFields"] = ["sourceKind", "sourceBasename", "sourceExtension", "sourceBytes"]
    preview["sourceRefPolicy"] = "filesystem-path-redacted"
    return preview
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
    candidate = confined_data_estate_path(data_root, relative)
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
    candidate = confined_data_estate_path(data_root, relative)
    return candidate
end

end
