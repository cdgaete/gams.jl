
println("")
println("-"^30)
println("Translate Tests")
println("-"^30)
println("")
include("translate.jl")

println("")
println("-"^30)
println("MathOptInterface Tests")
println("-"^30)
println("")
include("MOI_wrapper.jl")

println("")
println("-"^30)
println("GAMS Model Library Tests")
println("-"^30)
println("")
include("gamslib.jl")

println("")
println("-"^30)
println("Complementarity Tests")
println("-"^30)
println("")
include("complementarity.jl")
