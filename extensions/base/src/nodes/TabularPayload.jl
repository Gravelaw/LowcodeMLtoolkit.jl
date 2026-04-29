const DEFAULT_MAX_INPUT_ROWS = 100_000
const DEFAULT_MAX_OUTPUT_ROWS = 250_000
const DEFAULT_MAX_COLUMNS = 1_000
const DEFAULT_MAX_REF_BYTES = 50_000_000

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
            parts = [prefix; split(remainder, '/'; keepempty = false)]
            relative = joinpath(parts...)
            is_safe_relative_path(relative) || error("tabular ref path must stay within configured storage root")
            return relative
        end
    end
    is_safe_relative_path(ref) || error("tabular ref path must stay within configured storage root")
    return ref
end

function is_safe_relative_path(path::String)
    isempty(path) && return false
    isabspath(path) && return false
    return !any(part -> part == "..", split(path, '/'; keepempty = false))
end

function safe_storage_path(root::String, ref::String)
    relative = storage_relative_path(ref)
    root_abs = abspath(root)
    path_abs = abspath(joinpath(root_abs, relative))
    startswith(path_abs * "/", root_abs * "/") || error("tabular ref path must stay within configured storage root")
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
    startswith(resolved * "/", root_real * "/") || error(message)
    return resolved
end


function confined_storage_write_path(root::String, ref::String)
    root_real = root_realpath(root)
    relative = storage_relative_path(ref)
    parts = split(relative, Base.Filesystem.path_separator; keepempty = false)
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
            startswith(next_real * "/", root_real * "/") || error("tabular sink path must stay within configured storage root")
            current = next_real
        else
            mkpath(next_path)
            current = realpath(next_path)
            startswith(current * "/", root_real * "/") || error("tabular sink path must stay within configured storage root")
        end
    end

    final = joinpath(current, last(parts))
    reject_existing_symlink(final)
    startswith(abspath(final) * "/", root_real * "/") || error("tabular sink path must stay within configured storage root")
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
        startswith(resolved * "/", root_real * "/") || error("tabular ref path must stay within configured storage root")
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

function rows_from_reader(context::NodeContext, ref::String)
    reader = tabular_reader(context)
    reader isa Function || return nothing
    loaded = reader(ref, context)
    loaded === nothing && return nothing
    return tabular_result(loaded; adapter = adapter_name(context, "tabular_ref_reader"), context = context)
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

    path = local_ref_path(ref, context)
    path === nothing && return nothing
    return (rows = rows_from_json_ref(path, context), schema = nothing, adapter = "local_json_ref")
end

function rows_from_metadata_ref(context::NodeContext, ref::String)
    result = tabular_materialization_result(context, ref)
    result === nothing && return nothing
    return result.rows
end

function persist_tabular_rows(context::NodeContext, destination_uri::String, rows::AbstractVector)
    writer = tabular_writer(context)
    writer isa Function || return nothing
    written = writer(destination_uri, rows, context)
    written === nothing && return nothing
    adapter = entry_lookup(written, "adapter", :adapter, "persistence_adapter", :persistence_adapter)
    adapter === nothing && (adapter = adapter_name(context, "tabular_ref_writer"))
    persisted_ref = entry_lookup(written, "ref", :ref, "destination_uri", :destination_uri)
    persisted_path = entry_lookup(written, "path", :path, "persisted_path", :persisted_path)
    persisted_ref === nothing && persisted_path === nothing && error("tabular writer must return persisted ref or path")
    row_count = entry_lookup(written, "row_count", :row_count)
    row_count === nothing && (row_count = length(rows))
    return (adapter = adapter, ref = persisted_ref, path = persisted_path, row_count = row_count)
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
