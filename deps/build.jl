using BinDeps

BinDeps.@setup

libzstd = library_dependency("libzstd")
version = "1.2.0"
source  = "https://github.com/facebook/zstd/archive/v$(version).tar.gz"

if is_windows()
    using WinRPM
    provides(WinRPM.RPM,"libzstd",libzstd,os = :Windows)
end


prefix = joinpath(dirname(@__FILE__), "usr")
provides(Sources, URI(source), libzstd, unpacked_dir="zstd-$(version)")
provides(
    SimpleBuild,
    (@build_steps begin
        GetSources(libzstd)
        @build_steps begin
            ChangeDirectory(joinpath(BinDeps.depsdir(libzstd), "src", "zstd-$(version)"))
            MakeTargets(["PREFIX=$(prefix)", "install"])
        end
    end), libzstd)

@BinDeps.install Dict(:libzstd=>:libzstd)
