# Low-level Interfaces
# ====================

# load libzstd
include("../deps/deps.jl")

function iserror(code::Csize_t)
    return ccall((:ZSTD_isError, libzstd), Cuint, (Csize_t,), code) != 0
end

function zstderror(stream, code::Csize_t)
    ptr = ccall((:ZSTD_getErrorName, libzstd), Cstring, (Csize_t,), code)
    error("zstd error: ", unsafe_string(ptr))
end

function max_clevel()
    return ccall((:ZSTD_maxCLevel, libzstd), Cint, ())
end

const MAX_CLEVEL = max_clevel()

# ZSTD_outBuffer
mutable struct InBuffer
    src::Ptr{Void}
    size::Csize_t
    pos::Csize_t

    function InBuffer()
        return new(C_NULL, 0, 0)
    end
end

# ZSTD_inBuffer
mutable struct OutBuffer
    dst::Ptr{Void}
    size::Csize_t
    pos::Csize_t

    function OutBuffer()
        return new(C_NULL, 0, 0)
    end
end

# ZSTD_CStream
mutable struct CStream
    ptr::Ptr{Void}
    ibuffer::InBuffer
    obuffer::OutBuffer

    function CStream()
        ptr = ccall((:ZSTD_createCStream, libzstd), Ptr{Void}, ())
        if ptr == C_NULL
            throw(OutOfMemoryError())
        end
        return new(ptr, InBuffer(), OutBuffer())
    end
end

function initialize!(cstream::CStream, level::Integer)
    return ccall((:ZSTD_initCStream, libzstd), Csize_t, (Ptr{Void}, Cint), cstream.ptr, level)
end

function compress!(cstream::CStream)
    return ccall((:ZSTD_compressStream, libzstd), Csize_t, (Ptr{Void}, Ptr{Void}, Ptr{Void}), cstream.ptr, pointer_from_objref(cstream.obuffer), pointer_from_objref(cstream.ibuffer))
end

function finish!(cstream::CStream)
    return ccall((:ZSTD_endStream, libzstd), Csize_t, (Ptr{Void}, Ptr{Void}), cstream.ptr, pointer_from_objref(cstream.obuffer))
end

function free!(cstream::CStream)
    return ccall((:ZSTD_freeCStream, libzstd), Csize_t, (Ptr{Void},), cstream.ptr)
end

# ZSTD_DStream
mutable struct DStream
    ptr::Ptr{Void}
    ibuffer::InBuffer
    obuffer::OutBuffer

    function DStream()
        ptr = ccall((:ZSTD_createDStream, libzstd), Ptr{Void}, ())
        if ptr == C_NULL
            throw(OutOfMemoryError())
        end
        return new(ptr, InBuffer(), OutBuffer())
    end
end

function initialize!(dstream::DStream)
    return ccall((:ZSTD_initDStream, libzstd), Csize_t, (Ptr{Void},), dstream.ptr)
end

function decompress!(dstream::DStream)
    return ccall((:ZSTD_decompressStream, libzstd), Csize_t, (Ptr{Void}, Ptr{Void}, Ptr{Void}), dstream.ptr, pointer_from_objref(dstream.obuffer), pointer_from_objref(dstream.ibuffer))
end

function free!(dstream::DStream)
    return ccall((:ZSTD_freeDStream, libzstd), Csize_t, (Ptr{Void},), dstream.ptr)
end
