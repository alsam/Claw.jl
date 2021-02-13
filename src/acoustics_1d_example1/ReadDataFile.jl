module ReadDataFile

export Reader, read_str, read_bool, read_int, read_flt, read_int_array, read_flt_array, close_reader

mutable struct Reader
       
    fname::String
    istream::IOStream
    line::String
    lineno::Int

    # a constructor: opens a file, sets lineno
    function Reader(fname::String)
        istream = open(fname, "r")
        r = new(fname,istream, "", 0)
        return r
    end
end

finalizer(r::Reader, close_reader) = close_reader(r)

function readln(r::Reader)
    skip_rexp = r"^\s*(?:#|$)"
    rexp = r"^\s*(.*?)\s*(?:(#|=:)\s*(.*?)\s*$|$)"

    while true
        r.line = readline(r.istream)
        r.lineno += 1
        # skip empty lines and comments starting from #
        if match(skip_rexp, r.line) == nothing
            break
        end
    end
    m = match(rexp, r.line)
    r.line = m.captures[1]
end

function read_str(r::Reader)
    readln(r)
    return r.line
end

function read_bool(r::Reader)
    readln(r)
    if r.line != "T" && r.line != "F"
        local fname = r.fname, lineno = r.lineno
        error("$fname($lineno): error parsing boolean")
    end
    return r.line == "T"
end

function read_int(r::Reader)
    readln(r)
    return parse(Int,r.line)
end

function read_flt(r::Reader)
    readln(r)
    return parse(Float64, r.line)
end

function read_raw(r::Reader)
    readln(r)
    return split(r.line)
end

function read_array(r::Reader, parser, len)
    buf = read_raw(r)
    buflen = length(buf)
    @assert(buflen == len)
    return [parser(buf[i]) for i = 1:buflen]
end

read_int_array(r::Reader, len::Int) = read_array(r, x -> parse(Int, x), len)
read_flt_array(r::Reader, len::Int) = read_array(r, x -> parse(Float64, x), len)

function close_reader(r::Reader)
    println("closing Reader $(r.fname)")
    Base.close(r.istream)
end

# ```jlcon
# julia> include("ReadDataFile.jl")
# 
# julia> using .ReadDataFile
# 
# julia> r = Reader("claw.data")
# -I- claw.data 6 blank lines were skipped
# Reader("claw.data",IOStream(<file claw.data>),"1",6,r"^\s*(.*?)\s*(?:#\s*(.*?)\s*$|$)")
# 
# julia> readint(r)
# 1
# 
# julia> readflt(r)
# -1.0
# ```

end # ReadDataFile
