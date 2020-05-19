module GAMS

using Libdl

export GAMSModelStatus, GAMSSolveStatus, GAMSModelType, GAMSVarType
export label
export GAMSWorkspace, GAMSJob
export get_version, check_solver, get_solvers, set_system_dir

# GAMS model status
@enum(GAMSModelStatus,
   MODEL_STATUS_OPTIMAL_GLOBAL = 1,
   MODEL_STATUS_OPTIMAL_LOCAL = 2,
   MODEL_STATUS_UNBOUNDED = 3,
   MODEL_STATUS_INFEASIBLE_GLOBAL = 4,
   MODEL_STATUS_INFEASIBLE_LOCAL = 5,
   MODEL_STATUS_INFEASIBLE_INTERMED = 6,
   MODEL_STATUS_FEASIBLE = 7,
   MODEL_STATUS_INTEGER = 8,
   MODEL_STATUS_NON_INTEGER_INTERMED = 9,
   MODEL_STATUS_INTEGER_INFEASIBLE = 10,
   MODEL_STATUS_LICENSE_ERROR = 11,
   MODEL_STATUS_ERROR_UNKNOWN = 12,
   MODEL_STATUS_ERROR_NO_SOLUTION = 13,
   MODEL_STATUS_NO_SOLUTION_RETURNED = 14,
   MODEL_STATUS_SOLVED_UNIQUE = 15,
   MODEL_STATUS_SOLVED = 16,
   MODEL_STATUS_SOLVED_SINGULAR = 17,
   MODEL_STATUS_UNBOUNDED_NO_SOLUTION = 18,
   MODEL_STATUS_INFEASIBLE_NO_SOLUTION = 19,
   MODEL_STATUS_UNDEFINED = 20
)

# GAMS solve status
@enum(GAMSSolveStatus,
   SOLVE_STATUS_NORMAL = 1,
   SOLVE_STATUS_ITERATION = 2,
   SOLVE_STATUS_RESOURCE = 3,
   SOLVE_STATUS_SOLVER = 4,
   SOLVE_STATUS_EVAL_ERROR = 5,
   SOLVE_STATUS_CAPABILITY = 6,
   SOLVE_STATUS_LICENSE = 7,
   SOLVE_STATUS_USER = 8,
   SOLVE_STATUS_SETUP_ERROR = 9,
   SOLVE_STATUS_SOLVE_ERROR = 10,
   SOLVE_STATUS_INTERNAL_ERROR = 11,
   SOLVE_STATUS_SKIPPED = 12,
   SOLVE_STATUS_SYSTEM_ERROR = 13,
   SOLVE_STATUS_UNDEFINED = 14
)

# GAMS model type
@enum(GAMSModelType,
   MODEL_TYPE_LP,
   MODEL_TYPE_MIP,
   MODEL_TYPE_RMIP,
   MODEL_TYPE_NLP,
   MODEL_TYPE_MCP,
   MODEL_TYPE_MPEC,
   MODEL_TYPE_RMPEC,
   MODEL_TYPE_CNS,
   MODEL_TYPE_DNLP,
   MODEL_TYPE_MINLP,
   MODEL_TYPE_RMINLP,
   MODEL_TYPE_QCP,
   MODEL_TYPE_MIQCP,
   MODEL_TYPE_RMIQCP,
   MODEL_TYPE_EMP,
   MODEL_TYPE_UNDEFINED,
)

# GAMS variable type
@enum(GAMSVarType,
   VARTYPE_UNKNOWN,
   VARTYPE_BINARY,
   VARTYPE_INTEGER,
   VARTYPE_POSITIVE,
   VARTYPE_NEGATIVE,
   VARTYPE_FREE,
   VARTYPE_SOS1,
   VARTYPE_SOS2,
   VARTYPE_SEMICONT,
   VARTYPE_SEMIINT
)

# GAMS value position in GDX data
const GAMS_VALUE_LEVEL = 1
const GAMS_VALUE_MARGINAL = 2
const GAMS_VALUE_LOWER = 3
const GAMS_VALUE_UPPER = 4
const GAMS_VALUE_SCALE = 5

# GAMS special values
const GAMS_SV_UNDEF = 1.0e300       # undefined
const GAMS_SV_NA    = 2.0e300       # not available / applicable
const GAMS_SV_PINF  = 3.0e300       # plus infinity
const GAMS_SV_MINF  = 4.0e300       # minus infinity
const GAMS_SV_EPS   = 5.0e300       # epsilon
const GAMS_SV_ACR   = 10.0e300      # potential / real acronym
const GAMS_SV_NAINT = 2100000000    # not available / applicable for integers

# GAMS model status that indicates no solution returned
const GAMS_MODEL_STATUS_NO_SOLUTION = (
   MODEL_STATUS_ERROR_UNKNOWN, MODEL_STATUS_ERROR_NO_SOLUTION,
   MODEL_STATUS_NO_SOLUTION_RETURNED, MODEL_STATUS_UNBOUNDED_NO_SOLUTION,
   MODEL_STATUS_INFEASIBLE_NO_SOLUTION, MODEL_STATUS_INTEGER_INFEASIBLE,
   MODEL_STATUS_LICENSE_ERROR
)

# GAMS model attributes (after solve) with integer value
const GAMS_MODEL_ATTRIBUTES_INT = (
   "domUsd", "iterUsd", "marginals", "modelStat", "numDepnd", "numDVar", "numEqu",
   "numInfes", "numNLIns", "numNLNZ", "numNOpt", "numNZ", "numRedef", "numVar",
   "numVarProj", "solveStat"
)

# GAMS model attributes (after solve) with real value
const GAMS_MODEL_ATTRIBUTES_REAL = (
   "etAlg", "etSolve", "etSolver", "maxInfes", "meanInfes", "objEst", "objVal",
   "resUsd", "rObj", "sysIdent", "sysVer", "sumInfes"
)

# GAMS model attributes (after solve)
const GAMS_MODEL_ATTRIBUTES = union(
   GAMS_MODEL_ATTRIBUTES_INT,
   GAMS_MODEL_ATTRIBUTES_REAL
)

# required GAMS model attributes
const GAMS_MODEL_ATTRIBUTES_REQUIRED = (
   "modelStat", "numEqu", "numVar", "solveStat"
)

function label(
   type::GAMSModelType
)
   return replace(string(type), r"(MODEL_TYPE_)" => "")
end

function model_type_from_label(
   type::String
)
   if type == "LP"
      return MODEL_TYPE_LP
   elseif type == "MIP"
      return MODEL_TYPE_MIP
   elseif type == "RMIP"
      return MODEL_TYPE_RMIP
   elseif type == "NLP"
      return MODEL_TYPE_NLP
   elseif type == "MCP"
      return MODEL_TYPE_MCP
   elseif type == "MPEC"
      return MODEL_TYPE_MPEC
   elseif type == "RMPEC"
      return MODEL_TYPE_RMPEC
   elseif type == "CNS"
      return MODEL_TYPE_CNS
   elseif type == "DNLP"
      return MODEL_TYPE_DNLP
   elseif type == "MINLP"
      return MODEL_TYPE_MINLP
   elseif type == "RMINLP"
      return MODEL_TYPE_RMINLP
   elseif type == "QCP"
      return MODEL_TYPE_QCP
   elseif type == "MIQCP"
      return MODEL_TYPE_MIQCP
   elseif type == "RMIQCP"
      return MODEL_TYPE_RMIQCP
   elseif type == "EMP"
      return MODEL_TYPE_EMP
   else
      return MODEL_TYPE_UNDEFINED
   end
end

mutable struct GAMSSolution
   x::Vector{Float64}
   x_dual::Vector{Float64}
   eq::Vector{Float64}
   eq_dual::Vector{Float64}
end

GAMSSolution(n::Int, m::Int) = GAMSSolution(zeros(n), zeros(n), zeros(m), zeros(m))

mutable struct GAMSWorkspace
   version::Tuple{Int, Int, Int}
   working_dir::String
   system_dir::String
   supported_solver_type::Dict{String, Dict{GAMSModelType, Bool}}

   function GAMSWorkspace(
      working_dir::String,
      system_dir::String
   )
      check_system_dir(system_dir)
      new((0, 0, 0), working_dir, system_dir, Dict{String, Dict{GAMSModelType, Bool}}())
   end
end

function GAMSWorkspace(
   system_dir::String
)
   working_dir = mktempdir(prefix = "gams_jl_")
   GAMSWorkspace(working_dir, system_dir)
end

function GAMSWorkspace()
   path = Sys.which("gams")
   if isnothing(path)
      error("GAMS executable not found!")
   end
   GAMSWorkspace(splitdir(path)[1])
end

function check_system_dir(
   system_dir::String
)
   if Sys.iswindows()
      if ! Sys.isexecutable(joinpath(system_dir, "gams.exe"))
         error("GAMS executable 'gams.exe' not found in: $system_dir")
      end
   else
      if ! Sys.isexecutable(joinpath(system_dir, "gams"))
         error("GAMS executable 'gams' not found in: $system_dir")
      end
   end
   push!(Libdl.DL_LOAD_PATH, system_dir)
   return true
end

function set_system_dir(
   workspace::GAMSWorkspace,
   system_dir::String
)
   if check_system_dir(system_dir)
      workspace.system_dir = system_dir
      workspace.version = (0,0,0)
      workspace.supported_solver_type = Dict{String, Dict{GAMSModelType, Bool}}()
   end
end

function set_working_dir(
   workspace::GAMSWorkspace,
   working_dir::String
)
   rm(workspace.working_dir, force=true, recursive=true)
   if ! ispath(working_dir)
      mkpath(working_dir)
   end
   workspace.working_dir = working_dir
end

function get_version(
   workspace::GAMSWorkspace
)
   if workspace.version == (0,0,0)
      cmd = joinpath(workspace.system_dir, "gams")
      audit = read(`$cmd audit lo=3`, String)
      version = parse.(Int64, split(match(r"[0-9]+.[0-9]+.[0-9]+", audit).match, "."))
      workspace.version = (version[1], version[2], version[3])
   end
   return workspace.version
end

function load_solver_info(
   workspace::GAMSWorkspace
)
   cmd = joinpath(workspace.system_dir, "gams")
   cmd_arg::Vector{String} = Vector{String}()
   push!(cmd_arg, joinpath(@__DIR__, "solver_info.gms"))
   push!(cmd_arg, "curDir=$(workspace.working_dir)")
   push!(cmd_arg, "logoption=0")

   try
      Base.run(`$cmd $cmd_arg`)
   catch e
      lst_filepath = joinpath(workspace.working_dir, "solver_info.lst")
      error("GAMS compilation failed:\n" * open(f->read(f, String), lst_filepath))
   end

   # create gdx object
   gdx = GDXHandle()
   gdx_create(gdx)
   gdx_open_read(gdx, joinpath(workspace.working_dir, "solver_info.gdx"))

   # read gdx file
   n_rec = gdx_data_read_str_start(gdx, 1)
   uels = Vector{String}(undef, 2)
   vals = Vector{Float64}(undef, 2)
   for i in 1:n_rec
      gdx_data_read_str(gdx, uels, vals)
      name = lowercase(uels[1])
      if ! haskey(workspace.supported_solver_type, name)
         workspace.supported_solver_type[name] = Dict{String, Bool}()
      end
      type = model_type_from_label(uppercase(uels[2]))
      if ! haskey(workspace.supported_solver_type[name], type)
         workspace.supported_solver_type[name][type] = true
      end
   end
   gdx_data_read_done(gdx)
   gdx_close(gdx)
   gdx_free(gdx)

   return
end

function check_solver(
   workspace::GAMSWorkspace,
   solver::String
)
   solver = lowercase(solver)
   if isempty(workspace.supported_solver_type)
      load_solver_info(workspace)
   end
   return haskey(workspace.supported_solver_type, solver)
end

function check_solver(
   workspace::GAMSWorkspace,
   solver::String,
   modeltype::GAMSModelType
)
   solver = lowercase(solver)
   if check_solver(workspace, solver)
      return haskey(workspace.supported_solver_type[solver], modeltype)
   end
   return false
end

function check_solver(
   workspace::GAMSWorkspace,
   solver::String,
   modeltype::String
)
   return check_solver(workspace, solver, model_type_from_label(uppercase(modeltype)))
end

function get_solvers(
   workspace::GAMSWorkspace
)
   if isempty(workspace.supported_solver_type)
      load_solver_info(workspace)
   end
   return sort(collect(keys(workspace.supported_solver_type)))
end

mutable struct GAMSJob
   workspace::GAMSWorkspace
   filename::String
   jobname::String
end

GAMSJob(workspace::GAMSWorkspace, filename::String) = GAMSJob(workspace, filename, "m")

function run(
   job::GAMSJob;
   options::Dict{String,Any},
   solver_options::Dict{String,Any}
)
   # add instructions to write solution gdx
   open(job.filename, "a") do io
      Base.write(io, "Set attr / ")
      for (i, attr) in enumerate(GAMS_MODEL_ATTRIBUTES)
         if i > 1
            Base.write(io, ", ")
         end
         Base.write(io, attr)
      end
      Base.write(io, " /\n\n")
      Base.write(io, "Parameter stats;\n")
      for attr in GAMS_MODEL_ATTRIBUTES
         Base.write(io, "stats('$attr') = $(job.jobname).$attr;\n")
      end
      Base.write(io, "execute_unload '$(job.jobname)_stats.gdx', attr, stats;\n")
   end

   # create solver option file
   has_optfile = false
   if haskey(options, "solver") && length(solver_options) > 0
      opt_filepath = joinpath(job.workspace.working_dir, "$(options["solver"]).opt")
      open(opt_filepath, "w") do io
         for (name, value) in solver_options
            Base.write(io, "$name $value\n")
         end
      end
      has_optfile = true
   end

   # GAMS command
   cmd = joinpath(job.workspace.system_dir, "gams")
   cmd_arg::Vector{String} = Vector{String}()
   push!(cmd_arg, "$(job.filename)")
   push!(cmd_arg, "curDir=$(job.workspace.working_dir)")
   for (name, value) in options
      push!(cmd_arg, "$name=$value")
   end
   if has_optfile
      push!(cmd_arg, "optfile=1")
   end
   push!(cmd_arg, "savepoint=1")
   push!(cmd_arg, "limrow=0")
   push!(cmd_arg, "limcol=0")
   push!(cmd_arg, "solprint=off")
   push!(cmd_arg, "solvelink=5")

   # run GAMS
   try
      Base.run(`$cmd $cmd_arg`)
   catch e
      lst_filename = splitext(basename(job.filename))[1] * ".lst"
      lst_filepath = joinpath(job.workspace.working_dir, lst_filename)
      error("GAMS compilation failed:\n" * open(f->read(f, String), lst_filepath))
   end

   stats = Dict{String, Any}()
   idx = Vector{Int}(undef, 1)
   vals = Vector{Float64}(undef, max(GAMS_VALUE_LEVEL, GAMS_VALUE_MARGINAL))

   # create gdx object
   gdx = GDXHandle()
   gdx_create(gdx)
   gdx_open_read(gdx, joinpath(job.workspace.working_dir, "$(job.jobname)_stats.gdx"))

   # read stats gdx file
   n_rec = gdx_data_read_raw_start(gdx, 2)
   for i in 1:n_rec
      gdx_data_read_raw(gdx, idx, vals)
      name = GAMS_MODEL_ATTRIBUTES[idx[1]]
      val = parse_gdx_value(vals[GAMS_VALUE_LEVEL])
      if name == "modelStat"
         stats[name] = GAMSModelStatus(Int(val))
      elseif name == "solveStat"
         stats[name] = GAMSSolveStatus(Int(val))
      elseif name in GAMS_MODEL_ATTRIBUTES_REAL
         stats[name] = val
      elseif isnan(val) || isinf(val)
         stats[name] = val
      else
         stats[name] = Int(val)
      end
   end
   gdx_data_read_done(gdx)
   gdx_close(gdx)

   # check if all required stats are read
   for attr in GAMS_MODEL_ATTRIBUTES_REQUIRED
      if ! haskey(stats, attr)
         error("Reading model attribute '$attr' from GDX failed")
      end
   end

   sol::GAMSSolution = GAMSSolution(stats["numVar"], stats["numEqu"])

   # return if we don't expect any solution file
   if stats["modelStat"] in GAMS_MODEL_STATUS_NO_SOLUTION
      return sol, stats
   end

   # open solution gdx file
   gdx_open_read(gdx, joinpath(job.workspace.working_dir, "$(job.jobname)_p.gdx"))

   # read solution gdx file
   i = j = 1
   while true
      n_rec = gdx_data_read_raw_start(gdx, i)
      for k in 1:n_rec
         gdx_data_read_raw(gdx, idx, vals)
         sol.eq[j] = parse_gdx_value(vals[GAMS_VALUE_LEVEL])
         sol.eq_dual[j] = parse_gdx_value(vals[GAMS_VALUE_MARGINAL])
         j += 1
      end
      i += 1
      if j > stats["numEqu"]
         gdx_data_read_done(gdx)
         break
      end
   end
   j = 1
   while true
      n_rec = gdx_data_read_raw_start(gdx, i)
      for k in 1:n_rec
         gdx_data_read_raw(gdx, idx, vals)
         sol.x[j] = parse_gdx_value(vals[GAMS_VALUE_LEVEL])
         sol.x_dual[j] = parse_gdx_value(vals[GAMS_VALUE_MARGINAL])
         j += 1
      end
      i += 1
      if j > stats["numVar"]
         gdx_data_read_done(gdx)
         break
      end
   end

   gdx_close(gdx)
   gdx_free(gdx)

   return sol, stats
end

function auto_model_type(
   type::GAMSModelType,
   is_quadratic::Bool,
   is_nonlinear::Bool,
   is_discrete::Bool
)
   if type == GAMS.MODEL_TYPE_UNDEFINED
      if is_nonlinear && is_discrete
         type = GAMS.MODEL_TYPE_MINLP
      elseif is_nonlinear
         type = GAMS.MODEL_TYPE_NLP
      elseif is_quadratic && is_discrete
         type = GAMS.MODEL_TYPE_MIQCP
      elseif is_quadratic
         type = GAMS.MODEL_TYPE_QCP
      elseif is_discrete
         type = GAMS.MODEL_TYPE_MIP
      else
         type = GAMS.MODEL_TYPE_LP
      end
   else
      if type == GAMS.MODEL_TYPE_LP
         if is_quadratic
            type = GAMS.MODEL_TYPE_QCP
         elseif is_nonlinear
            type = GAMS.MODEL_TYPE_NLP
         elseif is_discrete
            type = GAMS.MODEL_TYPE_MIP
         end
      end
      if type == GAMS.MODEL_TYPE_MIP
         if is_quadratic
            type = GAMS.MODEL_TYPE_MIQCP
         elseif is_nonlinear
            type = GAMS.MODEL_TYPE_MINLP
         end
      end
      if type == GAMS.MODEL_TYPE_QCP
         if is_nonlinear
            type = GAMS.MODEL_TYPE_NLP
         elseif is_discrete
            type = GAMS.MODEL_TYPE_MIQCP
         end
      end
      if type == GAMS.MODEL_TYPE_MIQCP
         if is_nonlinear
            type = GAMS.MODEL_TYPE_MINLP
         end
      end
      if type == GAMS.MODEL_TYPE_NLP
         if is_discrete
            type = GAMS.MODEL_TYPE_MINLP
         end
      end
   end
   return type
end

function parse_gdx_value(
   val::Float64
)
   if val == GAMS_SV_UNDEF || val == GAMS_SV_NA
      return NaN
   end
   if val == GAMS_SV_PINF
      return Inf
   end
   if val == GAMS_SV_MINF
      return -Inf
   end
   if val == GAMS_SV_EPS
      return eps()
   end
   return val
end

include("gdx.jl")
include("MOI_wrapper/MOI_wrapper.jl")

end
