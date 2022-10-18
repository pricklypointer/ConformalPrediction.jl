"A base type for Inductive Conformal Classifiers."
abstract type InductiveConformalClassifier <: InductiveConformalModel end

# Simple
"The `SimpleInductiveClassifier` is the simplest approach to Inductive Conformal Classification. Contrary to the [`NaiveClassifier`](@ref) it computes nonconformity scores using a designated calibration dataset."
mutable struct SimpleInductiveClassifier{Model <: Supervised} <: InductiveConformalClassifier
    model::Model
    coverage::AbstractFloat
    scores::Union{Nothing,AbstractArray}
    heuristic::Function
    train_ratio::AbstractFloat
end

function SimpleInductiveClassifier(model::Supervised; coverage::AbstractFloat=0.95, heuristic::Function=f(ŷ)=1.0-ŷ, train_ratio::AbstractFloat=0.5)
    return SimpleInductiveClassifier(model, coverage, nothing, heuristic, train_ratio)
end

@doc raw"""
    MMI.fit(conf_model::SimpleInductiveClassifier, verbosity, X, y)

Wrapper function to fit the underlying MLJ model. For Inductive Conformal Prediction the underlying model is fitted on the *proper training set*. The `fitresult` is assigned to the model instance. Computation of nonconformity scores requires a separate calibration step involving a *calibration data set* (see [`calibrate!`](@ref)). 
"""
function MMI.fit(conf_model::SimpleInductiveClassifier, verbosity, X, y)
    
    # Data Splitting:
    train, calibration = partition(eachindex(y), conf_model.train_ratio)
    Xtrain = MLJ.matrix(X)[train,:]
    ytrain = y[train]
    Xcal = MLJ.matrix(X)[calibration,:]
    ycal = y[calibration]

    # Training: 
    fitresult, cache, report = MMI.fit(conf_model.model, verbosity, MMI.reformat(conf_model.model, Xtrain, ytrain)...)

    # Nonconformity Scores:
    ŷ = MMI.predict(conf_model.model, fitresult, Xcal)
    conf_model.scores = @.(conf_model.heuristic(ycal, ŷ))

    return (fitresult, cache, report)
end

@doc raw"""
    MMI.predict(conf_model::SimpleInductiveClassifier, fitresult, Xnew)

For the [`SimpleInductiveClassifier`](@ref) prediction sets are computed as follows,

``
\begin{aligned}
\hat{C}_{n,\alpha}(X_{n+1}) &= \left\{y: s(X_{n+1},y) \le \hat{q}_{n, \alpha}^{+} \{|Y_i - \hat\mu(X_i) |\} \right\}, \ i \in \mathcal{D}_{\text{calibration}}
\end{aligned}
``

where ``\mathcal{D}_{\text{calibration}}`` denotes the designated calibration data and ``\hat\mu`` denotes the model fitted on training data ``\mathcal{D}_{\text{train}}``.
"""
function MMI.predict(conf_model::SimpleInductiveClassifier, fitresult, Xnew)
    p̂ = MMI.predict(conf_model.model, fitresult, MMI.reformat(conf_model.model, Xnew)...)
    L = p̂.decoder.classes
    ŷ = pdf(p̂, L)
    v = conf_model.scores
    q̂ = qplus(v, conf_model)
    ŷ = map(x -> collect(key => 1.0-val <= q̂ ? val : missing for (key,val) in zip(L,x)),eachrow(ŷ))
    return 
end

