module ConformalModels

using MLJ
import MLJModelInterface as MMI
import MLJModelInterface: predict, fit, save, restore

"An abstract base type for conformal models that produce interval-values predictions. This includes most conformal regression models."
abstract type ConformalInterval <: MMI.Interval end

"An abstract base type for conformal models that produce set-values predictions. This includes most conformal classification models."
abstract type ConformalSet <: MMI.Supervised end        # ideally we'd have MMI.Set

"An abstract base type for conformal models that produce probabilistic predictions. This includes some conformal classifier like Venn-ABERS."
abstract type ConformalProbabilistic <: MMI.Probabilistic end

const ConformalModel = Union{ConformalInterval, ConformalSet, ConformalProbabilistic}

export ConformalInterval, ConformalSet, ConformalProbabilistic, ConformalModel

include("conformal_models.jl")

# Regression Models:
include("inductive_regression.jl")
export SimpleInductiveRegressor
include("transductive_regression.jl")
export NaiveRegressor, JackknifeRegressor, JackknifePlusRegressor, JackknifeMinMaxRegressor, CVPlusRegressor, CVMinMaxRegressor

# Classification Models
include("inductive_classification.jl")
export SimpleInductiveClassifier, AdaptiveInductiveClassifier
include("transductive_classification.jl")
export NaiveClassifier

# Type unions:
const InductiveModel = Union{
    SimpleInductiveRegressor,
    SimpleInductiveClassifier,
    AdaptiveInductiveClassifier
}

const TransductiveModel = Union{
    NaiveRegressor,
    JackknifeRegressor,
    JackknifePlusRegressor,
    JackknifeMinMaxRegressor,
    CVPlusRegressor,
    CVMinMaxRegressor,
    NaiveClassifier
}

"A container listing all available methods for conformal prediction."
const available_models = Dict(
    :regression => Dict(
        :transductive => Dict(
            :naive => NaiveRegressor,
            :jackknife => JackknifeRegressor,
            :jackknife_plus => JackknifePlusRegressor,
            :jackknife_minmax => JackknifeMinMaxRegressor,
            :cv_plus => CVPlusRegressor,
            :cv_minmax => CVMinMaxRegressor,
        ),
        :inductive => Dict(
            :simple_inductive => SimpleInductiveRegressor,
        ),
    ),
    :classification => Dict(
        :transductive => Dict(
            :naive => NaiveClassifier,
        ),
        :inductive => Dict(
            :simple_inductive => SimpleInductiveClassifier,
            :adaptive_inductive => AdaptiveInductiveClassifier,
        ),
    )
)
export available_models

include("model_traits.jl")

# Other general methods:
export conformal_model, fit, predict
    
end