module ReadDataFile

export Reader, readstr, readraw, readbool, readint, readflt, close

type Reader
       
    fname::String
    istream::IOStream
    line::String
    lineno::Int

    # a constructor: opens a file, sets lineno
    function Reader(fname::String)
        istream = open(fname, "r")
        r = new(fname,istream, "", 0)
        finalizer(r, close)
        return r
    end
end

function readln(r::Reader)
    const skip_rexp = r"^\s*(?:#|$)"
    const rexp = r"^\s*(.*?)\s*(?:(#|=:)\s*(.*?)\s*$|$)"

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

function readstr(r::Reader)
    readln(r)
    return r.line
end

function readraw(r::Reader)
    readln(r)
    return split(r.line)
end

function readbool(r::Reader)
    readln(r)
    if r.line != "T" && r.line != "F"
        local fname = r.fname, lineno = r.lineno
        error("$fname($lineno): error parsing boolean")
    end
    return r.line == "T"
end

function readint(r::Reader)
    readln(r)
    x::Int = parseint(r.line)
    return x
end

function readflt(r::Reader)
    readln(r)
    x::Float64 = parsefloat(r.line)
    return x
end

function close(r::Reader)
    Base.close(r.istream)
end

# ```jlcon
# julia> include("ReadDataFile.jl")
# 
# julia> using ReadDataFile
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
