using OffsetArrays

#
#
#=========================================================================#
function bc1(meqn::Int, mbc::Int, mx::Int, xlower::Float64, dx::Float64,
             q::OffsetArray{Float64,2}, maux::Int, aux::OffsetArray{Float64,2},
             t::Float64, dt::Float64, mthbc::Array{Int,1})
#=========================================================================#
#
#     # Standard boundary condition choices for claw2
#
#     # At each boundary  k = 1 (left),  2 (right):
#     #   mthbc(k) =  0  for user-supplied BC's (must be inserted!)
#     #            =  1  for zero-order extrapolation
#     #            =  2  for periodic boundary coniditions
#     #            =  3  for solid walls, assuming this can be implemented
#     #                  by reflecting the data about the boundary and then
#     #                  negating the 2'nd component of q.
#     ------------------------------------------------
#
#     # Extend the data from the computational region
#     #      i = 1, 2, ..., mx2
#     # to the virtual cells outside the region, with
#     #      i = 1-ibc  and   i = mx+ibc   for ibc=1,...,mbc
#
#
#
#-------------------------------------------------------
#     # left boundary:
#-------------------------------------------------------
#
    range::UnitRange = 1:meqn
    if mthbc[1] == 0

        # user-specified boundary conditions go here in place of error output
        println("*** ERROR *** mthbc(1)=0 and no BCs specified in bc1")
        exit(-1)

    elseif mthbc[1] == 1
        # zero-order extrapolation:
        for ibc=1:mbc
            q[range, 1-ibc] = q[range, 1]
        end
    elseif mthbc[1] == 2 
        # periodic:
        for ibc=1:mbc
            q[range, 1-ibc] = q[range, mx+1-ibc]
        end
    elseif mthbc[1] == 3 
        # solid wall (assumes 2'nd component is velocity or momentum in x):
        for ibc=1:mbc
            q[range, 1-ibc] = q[range, ibc]
            q[2,1-ibc] = -q[2,ibc]
        end
        # negate the normal velocity:
    end # if mthbc[1] == ...

#
#-------------------------------------------------------
#     # right boundary:
#-------------------------------------------------------

    if mthbc[2] == 0
        # user-specified boundary conditions go here in place of error output
        println("*** ERROR *** mthbc(2)=0 and no BCs specified in bc2")
        exit(-1)

    elseif mthbc[2] == 1
        # zero-order extrapolation:
        for ibc=1:mbc
            q[range, mx+ibc] = q[range, mx]
        end
    elseif mthbc[2] == 2 
        # periodic:  
        for ibc=1:mbc
            q[range, mx+ibc] = q[range, ibc]
        end
    elseif mthbc[2] == 3 
        # solid wall (assumes 2'nd component is velocity or momentum in x):
        for ibc=1:mbc
            q[range, mx+ibc] = q[range, mx+1-ibc]
            q[2,mx+ibc] = -q[2,mx+1-ibc]
        end
    end # if mthbc[2] == ...

end

