sources = JuliaFlowApiGateway.JuliaFlowDataScienceProjectLocalSources
core = JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore
validate_ref = core.validate_project_local_ref!
root = mktempdir()
mkpath(joinpath(root, "raw"))
csv_path = joinpath(root, "raw", "source.csv")
write(csv_path, "x,y\n1,2\n")
read_ref(ref; data_root = root) = sources.resolve_local_data_ref_path(ref; local_home = data_root, data_root, validate_local_ref = validate_ref)
write_ref(ref; data_root = root) = sources.local_data_ref_path_for_write(ref; local_home = data_root, data_root, validate_local_ref = validate_ref)
@test read_ref("local://data/raw/source.csv") == realpath(csv_path)
@test read_ref("LOCAL://data\\raw\\source.csv") == realpath(csv_path)
@test read_ref("local://data/raw/missing.csv") === nothing
@test read_ref("remote://data/raw/source.csv") === nothing
output = write_ref("local://analysis/new/nested/result.json")
@test output == joinpath(realpath(root), "analysis", "new", "nested", "result.json")
result = sources.write_local_artifact!(output, "{\"ok\":true}")
@test result["checksumSha256"] == sources.local_artifact_checksum(output)
@test result["checksumMode"] == "streaming_file_sha256"
@test write_ref("local://data/raw/result.csv") == joinpath(realpath(root), "data", "raw", "result.csv")
for relative in ["../outside.csv", "raw/../../outside.csv", "/outside.csv", "C:/outside.csv", "raw/source.csv:stream", "raw/\0.csv"]
    @test_throws ErrorException sources.confined_data_estate_path(root, relative)
    @test_throws ErrorException JuliaFlowApiGateway.safe_backup_artifact_path(root, relative)
end
@test JuliaFlowApiGateway.safe_backup_artifact_path(root, "raw/source.csv") == realpath(csv_path)
@test any(record -> record["checksumSha256"] == sources.local_artifact_checksum(csv_path), JuliaFlowApiGateway.local_data_estate_artifact_records(root))
@test sources.confined_data_estate_path(joinpath(root, "not-created"), "nested/output.csv") == joinpath(realpath(root), "not-created", "nested", "output.csv")

for kind in (:file, :directory, :relative_directory, :internal_directory, :dangling_file, :dangling_directory)
    managed = mktempdir()
    outside = mktempdir()
    sentinel = joinpath(outside, "source.csv")
    write(sentinel, "outside sentinel")
    target = kind == :file ? sentinel : kind == :dangling_file ? joinpath(outside, "missing.csv") :
        kind == :dangling_directory ? joinpath(outside, "missing") : outside
    if kind == :internal_directory
        target = mkpath(joinpath(managed, "ordinary"))
        write(joinpath(target, "source.csv"), "inside sentinel")
    end
    link = joinpath(managed, "linked")
    target_arg = kind == :relative_directory ? relpath(target, managed) : target
    created = try
        symlink(target_arg, link; dir_target = kind in (:directory, :relative_directory, :internal_directory, :dangling_directory))
        true
    catch err
        @info "Managed-path link fixture unavailable" kind exception = sprint(showerror, err)
        false
    end
    if !created
        @test_skip "platform does not permit this link fixture"
        continue
    end
    suffix = kind in (:file, :dangling_file) ? "linked" : "linked/source.csv"
    @test_throws ErrorException read_ref("local://data/" * suffix; data_root = managed)
    @test_throws ErrorException write_ref("local://" * suffix; data_root = managed)
    @test_throws ErrorException write_ref("local://linked/new/output.csv"; data_root = managed)
    @test_throws ErrorException JuliaFlowApiGateway.safe_backup_artifact_path(managed, suffix)
    @test_throws ErrorException JuliaFlowApiGateway.local_data_estate_artifact_records(managed)
    @test_throws ErrorException JuliaFlowApiGateway.directory_size_bytes(managed)
    @test read(sentinel, String) == "outside sentinel"
    @test !ispath(joinpath(outside, "new"))
end

# Absolute directory links use Windows junctions; configured root aliases remain valid.
alias_parent = mktempdir()
alias_root = joinpath(alias_parent, "estate")
alias_created = try
    symlink(root, alias_root; dir_target = true)
    true
catch err
    @info "Configured root alias fixture unavailable" exception = sprint(showerror, err)
    false
end
if alias_created
    @test read_ref("local://data/raw/source.csv"; data_root = alias_root) == realpath(csv_path)
    @test write_ref("local://analysis/alias.json"; data_root = alias_root) == joinpath(realpath(root), "analysis", "alias.json")
end

for folder in ("raw", "_manifests", "_duckdb", "_backups")
    managed = mktempdir()
    outside = mktempdir()
    symlink(outside, joinpath(managed, folder); dir_target = true)
    withenv("JULIAFLOW_APPLIANCE_BOOTSTRAP" => "1") do
        if folder == "raw"
            @test_throws ErrorException JuliaFlowApiGateway.local_data_estate_zones(managed)
        else
            @test_throws ErrorException JuliaFlowApiGateway.local_data_estate_management(managed, [Dict("name" => "raw", "path" => joinpath(managed, "raw"), "exists" => true, "writable" => true)])
        end
    end
    @test isempty(readdir(outside))
end

# The write probe is a file sink beneath an otherwise safe zone directory.
marker_root = mktempdir()
marker_zone = mkpath(joinpath(marker_root, "raw"))
outside_marker = joinpath(mktempdir(), "sentinel.csv")
write(outside_marker, "outside marker sentinel")
marker = joinpath(marker_zone, ".juliaflow-write-check")
symlink(outside_marker, marker)
@test_throws ErrorException JuliaFlowApiGateway.local_data_estate_zones(marker_root)
@test read(outside_marker, String) == "outside marker sentinel"
@test islink(marker)

# Exclude estate backup folders, not similarly named ancestors of a configured root alias.
alias_container = mktempdir()
alias_target = mkpath(joinpath(alias_container, "_backups", "estate"))
mkpath(joinpath(alias_target, "raw"))
write(joinpath(alias_target, "raw", "source.csv"), "x,y\n1,2\n")
mkpath(joinpath(alias_target, "_backups"))
write(joinpath(alias_target, "_backups", "snapshot.csv"), "retained backup")
configured_alias = joinpath(alias_container, "configured-root")
symlink(alias_target, configured_alias; dir_target = true)
alias_records = JuliaFlowApiGateway.local_data_estate_artifact_records(configured_alias)
@test length(alias_records) == 1
@test alias_records[1]["relativePath"] == joinpath("raw", "source.csv")
@test alias_records[1]["checksumSha256"] == sources.local_artifact_checksum(joinpath(alias_target, "raw", "source.csv"))
