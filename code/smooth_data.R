# smooth_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 17, 2020
#
# Smoothed empirical probabilities

# https://www.rdocumentation.org/packages/fda/versions/5.1.5.1/topics/smooth.monotone
library(fda)

# Smooth probabilities in the time_left (x) direction
smooth_time_data = function(df){
  if(nrow(df) >= 5){ # Need at least 5 points to attempt smoothing
    tmp = df %>% arrange(time_left)
    x = tmp$time_left
    y = tmp$prob_win
    rng = c(min(x), max(x)) # range of x

    # b-spline basis
    norder = 6
    n = length(x)
    nbasis = n + norder - 2
    wbasis = create.bspline.basis(rng, nbasis, norder, x)

    # starting values for coefficient
    cvec0 = matrix(0, nbasis, 1)
    Wfd0 = fd(cvec0, wbasis)

    # set up functional parameter object
    Lfdobj = 3          #  penalize curvature of acceleration
    lambda = 10^(-0.5)  #  smoothing parameter
    growfdPar = fdPar(Wfd0, Lfdobj, lambda)
    wgt = tmp$n         # weight vector = sample size

    # smoothed result
    result = tryCatch({smooth.monotone(x, y, growfdPar, wgt,
                                       conv = 0.1)},
                      error = function(cond){return(NA)})
    # coefficients
    if(!is.na(result)){
      Wfd = result$Wfdobj
      beta = result$beta
      y_smooth = beta[1] + beta[2]*eval.monfd(x, Wfd)
      y_smooth = sapply(y_smooth, function(y) ifelse(y > 0.5, 0.5, y))
      y_smooth = sapply(y_smooth, function(y) ifelse(y < 0, 0, y))

      # return df
      df = df %>%
        mutate(prob_win_smooth_time = y_smooth)

    } else {
      df = df %>%
        mutate(prob_win_smooth_time = prob_win)
    }
  } else {
    df = df %>%
      mutate(prob_win_smooth_time = prob_win)
  }
  return(df)
}

# Smooth probabilities in the score margin/diff (y) direction
smooth_margin_data = function(df){
  if(nrow(df) >= 5){ # Need at least 5 points to attempt smoothing
    tmp = df
    tmp = tmp %>% arrange(diff)
    x = tmp$diff
    y = tmp$prob_win
    rng = c(min(x), max(x)) # range of x

    # b-spline basis
    norder = 6
    n = length(x)
    nbasis = n + norder - 2
    wbasis = create.bspline.basis(rng, nbasis, norder, x)

    # starting values for coefficient
    cvec0 = matrix(0, nbasis, 1)
    Wfd0 = fd(cvec0, wbasis)

    # set up functional parameter object
    Lfdobj = 3          #  penalize curvature of acceleration
    lambda = 10^(-0.5)  #  smoothing parameter
    growfdPar = fdPar(Wfd0, Lfdobj, lambda)
    wgt = tmp$n         # weight vector = sample size

    # smoothed result
    result = tryCatch({smooth.monotone(x, y, growfdPar, wgt,
                                             conv = 0.1)},
                      error = function(cond){return(NA)})
    # coefficients
    if(!is.na(result)){
      Wfd = result$Wfdobj
      beta = result$beta
      y_smooth = beta[1] + beta[2]*eval.monfd(x, Wfd)
      y_smooth = sapply(y_smooth, function(y) ifelse(y > 0.5, 0.5, y))
      y_smooth = sapply(y_smooth, function(y) ifelse(y < 0, 0, y))

      # return df
      df = df %>%
        mutate(prob_win_smooth_margin = y_smooth)

    } else {
      df = df %>%
        mutate(prob_win_smooth_margin = prob_win)
    }
  } else {
    df = df %>%
      mutate(prob_win_smooth_margin = prob_win)
  }
  return(df)
}

