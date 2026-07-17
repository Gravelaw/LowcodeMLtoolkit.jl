const DEFAULT_MAX_INPUT_ROWS = 100_000
const DEFAULT_MAX_OUTPUT_ROWS = 250_000
const DEFAULT_MAX_COLUMNS = 1_000
const DEFAULT_MAX_REF_BYTES = 50_000_000

const ARROW_DATAFRAME_EXTENSIONS = Set([".arrow", ".feather", ".ipc"])

const REMOTE_OBJECT_STORE_DEFAULT_SCHEMES = ["s3://", "gs://", "az://", "https://", "http://"]

function remote_object_store_adapter_config(context::NodeContext)
    return metadata_lookup(
        context.metadata,
        "remote_object_store_adapter",
        :remote_object_store_adapter,
        "cloud_object_store_adapter",
        :cloud_object_store_adapter,
        "object_store_service_adapter",
        :object_store_service_adapter,
    )
end

function remote_object_store_enabled(context::NodeContext)
    enabled = metadata_lookup(context.metadata, "enable_remote_object_store_adapter", :enable_remote_object_store_adapter)
    enabled === true || return false
    return remote_object_store_adapter_config(context) !== nothing
end

function remote_object_store_adapter_name(config)
    name = entry_lookup(config, "name", :name, "adapter", :adapter)
    return name === nothing ? "remote_object_store_adapter" : String(name)
end

function remote_object_store_schemes(config)
    schemes = entry_lookup(config, "schemes", :schemes, "supported_schemes", :supported_schemes)
    schemes === nothing && return REMOTE_OBJECT_STORE_DEFAULT_SCHEMES
    schemes isa AbstractVector || error("remote object-store adapter schemes must be a vector")
    return [String(scheme) for scheme in schemes]
end

function remote_object_store_supports_ref(config, ref::String)
    return any(scheme -> startswith(ref, scheme), remote_object_store_schemes(config))
end

function arrow_ipc_base64_from_rows(rows::AbstractVector, context::NodeContext)
    normalized = validate_output_rows([row_to_dict(row) for row in rows], context)
    path = tempname() * ".arrow"
    try
        Arrow.write(path, Tables.columntable(normalized))
        return base64encode(read(path))
    finally
        isfile(path) && rm(path; force = true)
    end
end

function rows_from_arrow_ipc_base64(encoded::AbstractString, context::NodeContext)
    decoded = base64decode(String(encoded))
    length(decoded) <= limit_value(context, "max_ref_bytes", DEFAULT_MAX_REF_BYTES) || error("tabular ref exceeds byte limit")
    table = Arrow.Table(IOBuffer(decoded))
    frame = DataFrame(table)
    rows = [Dict{String,Any}(String(name) => row[name] for name in names(frame)) for row in eachrow(frame)]
    validate_input_rows(rows, context)
    return (rows = rows, schema = names(frame))
end

function remote_object_store_transport(context::NodeContext, config)
    transport = entry_lookup(config, "transport", :transport)
    transport isa Function && return transport
    transport = metadata_lookup(context.metadata, "remote_object_store_transport", :remote_object_store_transport)
    transport isa Function && return transport
    return nothing
end

function remote_object_store_endpoint(config)
    endpoint = entry_lookup(config, "endpoint", :endpoint, "base_url", :base_url)
    endpoint === nothing && error("remote object-store adapter requires endpoint or transport")
    return String(endpoint)
end

function remote_object_store_headers(config)
    headers = ["content-type" => "application/json", "accept" => "application/json"]
    token = entry_lookup(config, "token", :token, "bearer_token", :bearer_token)
    token === nothing || push!(headers, "authorization" => "Bearer $(String(token))")
    return headers
end

function remote_object_store_response_payload(response)
    if response isa AbstractDict || response isa NamedTuple
        return json_to_julia(response)
    elseif response isa HTTP.Response
        200 <= response.status < 300 || error("remote object-store adapter HTTP request failed with status $(response.status)")
        body = String(response.body)
        isempty(strip(body)) && return Dict{String,Any}()
        return json_to_julia(JSON3.read(body))
    elseif response isa AbstractString
        return json_to_julia(JSON3.read(String(response)))
    end
    error("unsupported remote object-store adapter response $(typeof(response))")
end

function remote_object_store_request(context::NodeContext, config, operation::String, ref::String; rows = nothing)
    body = Dict{String,Any}("operation" => operation, "ref" => ref)
    if rows !== nothing
        body["format"] = "arrow_ipc_base64"
        body["data"] = arrow_ipc_base64_from_rows(rows, context)
        body["row_count"] = length(rows)
    end
    transport = remote_object_store_transport(context, config)
    if transport isa Function
        return remote_object_store_response_payload(transport(operation, ref, body, context))
    end
    endpoint = remote_object_store_endpoint(config)
    response = HTTP.request("POST", endpoint, remote_object_store_headers(config), JSON3.write(body))
    return remote_object_store_response_payload(response)
end

function rows_from_remote_object_store(context::NodeContext, ref::String)
    remote_object_store_enabled(context) || return nothing
    config = remote_object_store_adapter_config(context)
    remote_object_store_supports_ref(config, ref) || return nothing
    payload = remote_object_store_request(context, config, "read", ref)
    format = entry_lookup(payload, "format", :format)
    data = entry_lookup(payload, "data", :data, "arrow_ipc_base64", :arrow_ipc_base64)
    adapter = entry_lookup(payload, "adapter", :adapter)
    adapter === nothing && (adapter = remote_object_store_adapter_name(config))
    if data !== nothing && (format === nothing || String(format) == "arrow_ipc_base64")
        result = rows_from_arrow_ipc_base64(String(data), context)
        return (rows = result.rows, schema = result.schema, adapter = adapter)
    end
    return tabular_result(payload; adapter = adapter, context = context)
end

function write_with_remote_object_store(context::NodeContext, destination_uri::String, rows::AbstractVector)
    remote_object_store_enabled(context) || return nothing
    config = remote_object_store_adapter_config(context)
    remote_object_store_supports_ref(config, destination_uri) || return nothing
    payload = remote_object_store_request(context, config, "write", destination_uri; rows = rows)
    adapter = entry_lookup(payload, "adapter", :adapter)
    adapter === nothing && (adapter = remote_object_store_adapter_name(config))
    persisted_ref = entry_lookup(payload, "ref", :ref, "destination_uri", :destination_uri)
    persisted_ref === nothing && (persisted_ref = destination_uri)
    row_count = entry_lookup(payload, "row_count", :row_count)
    row_count === nothing && (row_count = length(rows))
    return (adapter = adapter, ref = persisted_ref, path = entry_lookup(payload, "path", :path), row_count = row_count)
end

function is_arrow_dataframe_path(path::String)
    return lowercase(splitext(path)[2]) in ARROW_DATAFRAME_EXTENSIONS
end

function arrow_dataframe_enabled(context::NodeContext)
    enabled = metadata_lookup(context.metadata, "enable_arrow_dataframe_adapter", :enable_arrow_dataframe_adapter)
    return enabled === true
end

function rows_from_arrow_dataframe_ref(path::String, context::NodeContext)
    filesize(path) <= limit_value(context, "max_ref_bytes", DEFAULT_MAX_REF_BYTES) || error("tabular ref exceeds byte limit")
    table = Arrow.Table(path)
    frame = DataFrame(table)
    rows = [Dict{String,Any}(String(name) => row[name] for name in names(frame)) for row in eachrow(frame)]
    validate_input_rows(rows, context)
    return rows
end

function arrow_dataframe_schema(path::String)
    table = Arrow.Table(path)
    frame = DataFrame(table)
    return names(frame)
end

function write_arrow_dataframe_ref(path::String, rows::AbstractVector, context::NodeContext)
    normalized = validate_output_rows([row_to_dict(row) for row in rows], context)
    mkpath(dirname(path))
    table = Tables.columntable(normalized)
    Arrow.write(path, table)
    return (adapter = "arrow_dataframe_file", ref = nothing, path = path, row_count = length(normalized))
end

function limit_value(context::NodeContext, key::String, default::Int)
    value = metadata_lookup(context.metadata, key, Symbol(key))
    value === nothing && return default
    value isa Integer && value > 0 || error("invalid $(key)")
    return Int(value)
end

function check_row_limit(rows::AbstractVector, context::NodeContext, key::String, default::Int)
    length(rows) <= limit_value(context, key, default) || error("tabular row limit exceeded")
    return rows
end

function check_column_limit(rows::AbstractVector, context::NodeContext)
    max_columns = limit_value(context, "max_columns", DEFAULT_MAX_COLUMNS)
    for row in rows
        row_dict = row_to_dict(row)
        length(row_dict) <= max_columns || error("tabular column limit exceeded")
    end
    return rows
end

function validate_input_rows(rows::AbstractVector, context::NodeContext)
    check_row_limit(rows, context, "max_input_rows", DEFAULT_MAX_INPUT_ROWS)
    check_column_limit(rows, context)
    return rows
end

function validate_output_rows(rows::AbstractVector, context::NodeContext)
    check_row_limit(rows, context, "max_output_rows", DEFAULT_MAX_OUTPUT_ROWS)
    check_column_limit(rows, context)
    return rows
end

function checked_output_push!(rows::Vector, row, context::NodeContext)
    length(rows) < limit_value(context, "max_output_rows", DEFAULT_MAX_OUTPUT_ROWS) || error("node output row limit exceeded")
    row_dict = row_to_dict(row)
    length(row_dict) <= limit_value(context, "max_columns", DEFAULT_MAX_COLUMNS) || error("tabular column limit exceeded")
    push!(rows, row_dict)
    return rows
end

function payload_rows(payload::NamedTuple)
    haskey(payload, :rows) || return nothing
    rows = payload.rows
    rows isa AbstractVector || error("Arrow payload rows field must be a vector")
    return [row_to_dict(row) for row in rows]
end

function metadata_lookup(metadata::AbstractDict, keys...)
    for key in keys
        haskey(metadata, key) && return metadata[key]
    end
    return nothing
end

function json_to_julia(value)
    if value isa AbstractDict
        return Dict{String,Any}(String(key) => json_to_julia(nested) for (key, nested) in pairs(value))
    elseif value isa AbstractVector
        return Any[json_to_julia(item) for item in value]
    end
    return value
end

function rows_from_tabular_entry(entry)
    candidate = entry
    if entry isa NamedTuple
        if haskey(entry, :rows)
            candidate = entry.rows
        else
            error("tabular payload entry missing rows field")
        end
    elseif entry isa AbstractDict
        if haskey(entry, "rows")
            candidate = entry["rows"]
        elseif haskey(entry, :rows)
            candidate = entry[:rows]
        else
            error("tabular payload entry missing rows field")
        end
    end
    candidate isa AbstractVector || error("materialized tabular rows must be a vector")
    return [row_to_dict(row) for row in candidate]
end

function entry_lookup(entry, keys...)
    if entry isa NamedTuple
        for key in keys
            symbol_key = key isa Symbol ? key : Symbol(String(key))
            haskey(entry, symbol_key) && return getfield(entry, symbol_key)
        end
    elseif entry isa AbstractDict
        for key in keys
            haskey(entry, key) && return entry[key]
            string_key = String(key)
            haskey(entry, string_key) && return entry[string_key]
            symbol_key = Symbol(string_key)
            haskey(entry, symbol_key) && return entry[symbol_key]
        end
    end
    return nothing
end

function tabular_result(entry; adapter = nothing, context = nothing)
    rows = rows_from_tabular_entry(entry)
    context === nothing || validate_input_rows(rows, context)
    schema = entry_lookup(entry, "schema", :schema, "fields", :fields, "columns", :columns)
    resolved_adapter = entry_lookup(entry, "adapter", :adapter, "materialization_adapter", :materialization_adapter)
    resolved_adapter === nothing && (resolved_adapter = adapter)
    return (rows = rows, schema = schema, adapter = resolved_adapter)
end

function storage_relative_path(ref::String)
    for scheme in ["object://", "warehouse://", "memory://"]
        if startswith(ref, scheme)
            remainder = ref[length(scheme)+1:end]
            prefix = replace(first(split(scheme, "://")), "://" => "")
            parts = [prefix; storage_path_parts(remainder)]
            relative = joinpath(parts...)
            is_safe_relative_path(relative) || error("tabular ref path must stay within configured storage root")
            return relative
        end
    end
    is_safe_relative_path(ref) || error("tabular ref path must stay within configured storage root")
    return ref
end

function storage_path_parts(path::String)
    return split(replace(path, '\\' => '/'), '/'; keepempty = false)
end

function is_safe_relative_path(path::String)
    isempty(path) && return false
    isabspath(path) && return false
    return !any(part -> part == "..", storage_path_parts(path))
end

function normalized_storage_path(path::String)
    normalized = normpath(path)
    return Sys.iswindows() ? lowercase(normalized) : normalized
end

function path_with_separator(path::String)
    normalized = normalized_storage_path(path)
    separator = Base.Filesystem.path_separator
    return endswith(normalized, separator) ? normalized : normalized * separator
end

function path_is_within(candidate::String, root::String)
    return startswith(path_with_separator(candidate), path_with_separator(root))
end

function safe_storage_path(root::String, ref::String)
    relative = storage_relative_path(ref)
    root_abs = abspath(root)
    path_abs = abspath(joinpath(root_abs, relative))
    path_is_within(path_abs, root_abs) || error("tabular ref path must stay within configured storage root")
    return path_abs
end

function root_realpath(root::String)
    isdir(root) || error("tabular storage root must exist")
    return realpath(root)
end

function reject_existing_symlink(path::String)
    ispath(path) && islink(path) && error("tabular ref path must not be a symlink")
    return nothing
end

function confine_real_path(root::String, path::String, message::String)
    root_real = root_realpath(root)
    candidate = isabspath(path) ? abspath(path) : abspath(joinpath(root_real, storage_relative_path(path)))
    reject_existing_symlink(candidate)
    resolved = ispath(candidate) ? realpath(candidate) : abspath(candidate)
    path_is_within(resolved, root_real) || error(message)
    return resolved
end


function confined_storage_write_path(root::String, ref::String)
    root_real = root_realpath(root)
    relative = storage_relative_path(ref)
    parts = storage_path_parts(relative)
    isempty(parts) && error("tabular sink path must not be empty")

    current = root_real
    for part in parts[1:end-1]
        (part == "." || isempty(part)) && continue
        part == ".." && error("tabular sink path must stay within configured storage root")
        next_path = joinpath(current, part)
        if ispath(next_path)
            islink(next_path) && error("tabular sink path must not traverse a symlink")
            isdir(next_path) || error("tabular sink parent must be a directory")
            next_real = realpath(next_path)
            path_is_within(next_real, root_real) || error("tabular sink path must stay within configured storage root")
            current = next_real
        else
            mkpath(next_path)
            current = realpath(next_path)
            path_is_within(current, root_real) || error("tabular sink path must stay within configured storage root")
        end
    end

    final = joinpath(current, last(parts))
    reject_existing_symlink(final)
    path_is_within(abspath(final), root_real) || error("tabular sink path must stay within configured storage root")
    return final
end

function local_storage_root(context::NodeContext)
    return metadata_lookup(context.metadata, "tabular_ref_root", :tabular_ref_root, "object_store_root", :object_store_root)
end

function safe_file_ref_path(root::String, path::String)
    isempty(path) && error("file tabular ref path must not be empty")
    return confine_real_path(root, path, "file tabular ref path must stay within configured storage root")
end

function ref_storage_path(ref::String, context::NodeContext)
    root = metadata_lookup(context.metadata, "tabular_ref_root", :tabular_ref_root, "object_store_root", :object_store_root)
    if startswith(ref, "file://")
        allow_file = metadata_lookup(context.metadata, "allow_file_refs", :allow_file_refs) === true
        allow_file || error("file:// tabular refs are disabled")
        root === nothing && error("file:// tabular refs require configured storage root")
        return safe_file_ref_path(String(root), ref[8:end])
    end
    root === nothing && return nothing
    path = safe_storage_path(String(root), ref)
    reject_existing_symlink(path)
    if ispath(path)
        root_real = root_realpath(String(root))
        resolved = realpath(path)
        path_is_within(resolved, root_real) || error("tabular ref path must stay within configured storage root")
        return resolved
    end
    return path
end

function rows_from_json_ref(path::String, context::NodeContext)
    filesize(path) <= limit_value(context, "max_ref_bytes", DEFAULT_MAX_REF_BYTES) || error("tabular ref exceeds byte limit")
    rows = if lowercase(splitext(path)[2]) == ".jsonl"
        [row_to_dict(json_to_julia(JSON3.read(line))) for line in eachline(path) if !isempty(strip(line))]
    else
        parsed = json_to_julia(JSON3.read(read(path, String)))
        rows_from_tabular_entry(parsed)
    end
    validate_input_rows(rows, context)
    return rows
end

function tabular_reader(context::NodeContext)
    return metadata_lookup(
        context.metadata,
        "tabular_ref_reader",
        :tabular_ref_reader,
        "arrow_table_reader",
        :arrow_table_reader,
        "dataframe_reader",
        :dataframe_reader,
    )
end

function tabular_writer(context::NodeContext)
    return metadata_lookup(
        context.metadata,
        "tabular_ref_writer",
        :tabular_ref_writer,
        "arrow_table_writer",
        :arrow_table_writer,
        "dataframe_writer",
        :dataframe_writer,
    )
end

function adapter_name(context::NodeContext, default::String)
    configured = metadata_lookup(
        context.metadata,
        "tabular_adapter_name",
        :tabular_adapter_name,
        "tabular_materialization_adapter",
        :tabular_materialization_adapter,
    )
    configured === nothing && return default
    return String(configured)
end

function tabular_adapter_registry(context::NodeContext)
    return metadata_lookup(
        context.metadata,
        "tabular_adapter_registry",
        :tabular_adapter_registry,
        "tabular_materialization_adapters",
        :tabular_materialization_adapters,
        "tabular_service_adapters",
        :tabular_service_adapters,
    )
end

function registry_entry(registry::AbstractDict, key)
    haskey(registry, key) && return registry[key]
    string_key = String(key)
    haskey(registry, string_key) && return registry[string_key]
    symbol_key = Symbol(string_key)
    haskey(registry, symbol_key) && return registry[symbol_key]
    return nothing
end

function adapter_supported_schemes(entry)
    schemes = entry_lookup(entry, "schemes", :schemes, "supported_schemes", :supported_schemes, "refs", :refs)
    schemes === nothing && return nothing
    schemes isa AbstractVector || error("tabular adapter schemes must be a vector")
    return [String(scheme) for scheme in schemes]
end

function adapter_supports_ref(entry, ref::String)
    schemes = adapter_supported_schemes(entry)
    schemes === nothing && return true
    return any(scheme -> startswith(ref, scheme), schemes)
end

function registered_adapter_methods(context::NodeContext, ref::String, method_keys...)
    registry = tabular_adapter_registry(context)
    registry isa AbstractDict || return nothing
    configured = metadata_lookup(
        context.metadata,
        "tabular_adapter_name",
        :tabular_adapter_name,
        "tabular_materialization_adapter",
        :tabular_materialization_adapter,
    )
    candidates = configured === nothing ? collect(keys(registry)) : Any[configured]
    for key in candidates
        entry = registry_entry(registry, key)
        entry === nothing && continue
        adapter_supports_ref(entry, ref) || continue
        method = entry_lookup(entry, method_keys...)
        method isa Function || continue
        name = entry_lookup(entry, "name", :name, "adapter", :adapter, "materialization_adapter", :materialization_adapter)
        name === nothing && (name = String(key))
        return (name = String(name), method = method)
    end
    return nothing
end

function rows_from_registered_reader(context::NodeContext, ref::String)
    adapter = registered_adapter_methods(
        context,
        ref,
        "reader",
        :reader,
        "read",
        :read,
        "read_rows",
        :read_rows,
        "tabular_ref_reader",
        :tabular_ref_reader,
        "arrow_table_reader",
        :arrow_table_reader,
        "dataframe_reader",
        :dataframe_reader,
    )
    adapter === nothing && return nothing
    loaded = adapter.method(ref, context)
    loaded === nothing && return nothing
    return tabular_result(loaded; adapter = adapter.name, context = context)
end

function write_with_registered_adapter(context::NodeContext, destination_uri::String, rows::AbstractVector)
    adapter = registered_adapter_methods(
        context,
        destination_uri,
        "writer",
        :writer,
        "write",
        :write,
        "write_rows",
        :write_rows,
        "tabular_ref_writer",
        :tabular_ref_writer,
        "arrow_table_writer",
        :arrow_table_writer,
        "dataframe_writer",
        :dataframe_writer,
    )
    adapter === nothing && return nothing
    written = adapter.method(destination_uri, rows, context)
    written === nothing && return nothing
    return (adapter = adapter.name, written = written)
end

function rows_from_reader(context::NodeContext, ref::String)
    reader = tabular_reader(context)
    if reader isa Function
        loaded = reader(ref, context)
        loaded === nothing || return tabular_result(loaded; adapter = adapter_name(context, "tabular_ref_reader"), context = context)
    end
    return rows_from_registered_reader(context, ref)
end

function local_ref_path(ref::String, context::NodeContext)
    path = ref_storage_path(ref, context)
    path === nothing && return nothing
    return isfile(path) ? path : nothing
end

function tabular_materialization_result(context::NodeContext, ref::String)
    store = metadata_lookup(
        context.metadata,
        "tabular_payload_store",
        :tabular_payload_store,
        "tabular_rows",
        :tabular_rows,
    )
    if store isa AbstractDict
        if haskey(store, ref)
            return tabular_result(store[ref]; adapter = "metadata_store", context = context)
        elseif haskey(store, Symbol(ref))
            return tabular_result(store[Symbol(ref)]; adapter = "metadata_store", context = context)
        end
    end

    loader = metadata_lookup(context.metadata, "load_tabular_payload", :load_tabular_payload, "load_tabular_rows", :load_tabular_rows)
    if loader isa Function
        loaded = loader(ref)
        loaded === nothing || return tabular_result(loaded; adapter = "metadata_loader", context = context)
    end

    reader_result = rows_from_reader(context, ref)
    reader_result === nothing || return reader_result

    remote_result = rows_from_remote_object_store(context, ref)
    remote_result === nothing || return remote_result

    path = local_ref_path(ref, context)
    path === nothing && return nothing
    if arrow_dataframe_enabled(context) && is_arrow_dataframe_path(path)
        return (rows = rows_from_arrow_dataframe_ref(path, context), schema = arrow_dataframe_schema(path), adapter = "arrow_dataframe_file")
    end
    return (rows = rows_from_json_ref(path, context), schema = nothing, adapter = "local_json_ref")
end

function rows_from_metadata_ref(context::NodeContext, ref::String)
    result = tabular_materialization_result(context, ref)
    result === nothing && return nothing
    return result.rows
end

function normalize_writer_result(written, default_adapter, rows::AbstractVector)
    adapter = entry_lookup(written, "adapter", :adapter, "persistence_adapter", :persistence_adapter)
    adapter === nothing && (adapter = default_adapter)
    persisted_ref = entry_lookup(written, "ref", :ref, "destination_uri", :destination_uri)
    persisted_path = entry_lookup(written, "path", :path, "persisted_path", :persisted_path)
    persisted_ref === nothing && persisted_path === nothing && error("tabular writer must return persisted ref or path")
    row_count = entry_lookup(written, "row_count", :row_count)
    row_count === nothing && (row_count = length(rows))
    return (adapter = adapter, ref = persisted_ref, path = persisted_path, row_count = row_count)
end

function persist_tabular_rows(context::NodeContext, destination_uri::String, rows::AbstractVector)
    writer = tabular_writer(context)
    if writer isa Function
        written = writer(destination_uri, rows, context)
        written === nothing || return normalize_writer_result(written, adapter_name(context, "tabular_ref_writer"), rows)
    end
    registered = write_with_registered_adapter(context, destination_uri, rows)
    registered === nothing || return normalize_writer_result(registered.written, registered.adapter, rows)
    remote = write_with_remote_object_store(context, destination_uri, rows)
    remote === nothing || return remote
    path = ref_storage_path(destination_uri, context)
    if path !== nothing && arrow_dataframe_enabled(context) && is_arrow_dataframe_path(path)
        return write_arrow_dataframe_ref(path, rows, context)
    end
    return nothing
end

function payload_rows(payload::NamedTuple, context::NodeContext)
    inline_rows = payload_rows(payload)
    inline_rows === nothing || return validate_input_rows(inline_rows, context)
    haskey(payload, :ref) || return nothing
    return rows_from_metadata_ref(context, String(payload.ref))
end

function row_value(row, column::String)
    if row isa NamedTuple
        key = Symbol(column)
        haskey(row, key) || error("row missing column $(column)")
        return getfield(row, key)
    elseif row isa AbstractDict
        if haskey(row, column)
            return row[column]
        end
        key = Symbol(column)
        haskey(row, key) || error("row missing column $(column)")
        return row[key]
    end
    error("unsupported row type $(typeof(row))")
end

function row_to_dict(row)
    if row isa NamedTuple
        return Dict{String,Any}(String(key) => getfield(row, key) for key in keys(row))
    elseif row isa AbstractDict
        return Dict{String,Any}(String(key) => value for (key, value) in pairs(row))
    end
    error("unsupported row type $(typeof(row))")
end

function materialized_ref(context::NodeContext, node_key::String)
    safe_node_key = replace(node_key, "." => "_")
    return "memory://materialized/$(context.execution_id)/$(context.node_id)/$(safe_node_key).arrow"
end

function table_payload(base_payload::NamedTuple, context::NodeContext, node_key::String, rows::AbstractVector; schema = nothing)
    normalized_rows = [Dict{String,Any}(String(key) => value for (key, value) in pairs(row)) for row in rows]
    validate_output_rows(normalized_rows, context)
    payload = (
        format = :arrow_ipc,
        ref = materialized_ref(context, node_key),
        rows = normalized_rows,
        row_count = length(normalized_rows),
        materialized = true,
        source_ref = String(base_payload.ref),
    )
    return schema === nothing ? payload : (; payload..., schema = schema)
end

function parse_literal(raw)
    raw isa AbstractString || return raw
    token = strip(String(raw))
    if (startswith(token, "\"") && endswith(token, "\"")) || (startswith(token, "'") && endswith(token, "'"))
        return token[2:end-1]
    elseif lowercase(token) == "true"
        return true
    elseif lowercase(token) == "false"
        return false
    elseif lowercase(token) == "missing" || lowercase(token) == "null"
        return missing
    end

    int_value = tryparse(Int, token)
    int_value === nothing || return int_value
    float_value = tryparse(Float64, token)
    float_value === nothing || return float_value
    return token
end

function comparable_pair(left, right)
    if left isa Number && right isa Number
        return (left, right)
    end
    return (String(left), String(right))
end

function predicate_matches(row, predicate::String)
    stripped = strip(predicate)
    isempty(stripped) && error("predicate must not be empty")
    lowercase(stripped) == "true" && return true

    parsed = match(r"^\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*(==|!=|>=|<=|>|<)\s*(.*?)\s*$", stripped)
    parsed === nothing && error("unsupported predicate syntax: $(predicate)")

    column = String(parsed.captures[1])
    operator = String(parsed.captures[2])
    expected = parse_literal(parsed.captures[3])
    actual = row_value(row, column)

    operator == "==" && return actual == expected
    operator == "!=" && return actual != expected

    left, right = comparable_pair(actual, expected)
    operator == ">" && return left > right
    operator == ">=" && return left >= right
    operator == "<" && return left < right
    operator == "<=" && return left <= right
    error("unsupported predicate operator: $(operator)")
end

function numeric_values(rows, column::String)
    values = Float64[]
    for row in rows
        value = row_value(row, column)
        if value === missing || value === nothing
            continue
        end
        value isa Number || error("column $(column) contains non-numeric value $(value)")
        push!(values, Float64(value))
    end
    return values
end

function mean_value(values::Vector{Float64})
    isempty(values) && return NaN
    return sum(values) / length(values)
end
