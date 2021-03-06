# // Copyright (C) 2015 - 2016  Dmitriy Selivanov
# // This file is part of text2vec
# //
#   // text2vec is free software: you can redistribute it and/or modify it
# // under the terms of the GNU General Public License as published by
# // the Free Software Foundation, either version 2 of the License, or
# // (at your option) any later version.
# //
#   // text2vec is distributed in the hope that it will be useful, but
# // WITHOUT ANY WARRANTY; without even the implied warranty of
# // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# // GNU General Public License for more details.
# //
#   // You should have received a copy of the GNU General Public License
# // along with text2vec.  If not, see <http://www.gnu.org/licenses/>.
#' TfIdf
#'
#' Term Frequency Inverse Document Frequency
#' @description Creates TfIdf(Latent semantic analysis) model.
#' The IDF is defined as follows: \code{idf = log(# documents in the corpus) /
#' (# documents where the term appears + 1)}
#' @format \code{\link{R6Class}} object.
#' @section Usage:
#' For usage details see \bold{Methods, Arguments and Examples} sections.
#' \preformatted{
#' tfidf = TfIdf$new(smooth_idf = TRUE, norm = c('l1', 'l2', 'none'), sublinear_tf = FALSE)
#' tfidf$fit(x)
#' tfidf$fit_transform(x)
#' tfidf$transform(x)
#' }
#' @section Methods:
#' \describe{
#'   \item{\code{$new(smooth_idf = TRUE, norm = c("l1", "l2", "none"), sublinear_tf = FALSE)}}{Creates tf-idf model}
#'   \item{\code{$fit(x)}}{fit tf-idf model to an input DTM (preferably in "dgCMatrix" format)}
#'   \item{\code{$fit_transform(x)}}{fit model to an input sparse matrix (preferably in "dgCMatrix"
#'    format) and then transforms it.}
#'   \item{\code{$transform(x)}}{transform new data \code{x} using tf-idf from train data}
#' }
#' @field verbose \code{logical = TRUE} whether to display training inforamtion
#' @section Arguments:
#' \describe{
#'  \item{tfidf}{A \code{TfIdf} object}
#'  \item{x}{An input term-cooccurence matrix. Preferably in \code{dgCMatrix} format}
#'  \item{smooth_idf}{\code{TRUE} smooth IDF weights by adding one to document
#'   frequencies, as if an extra document was seen containing every term in the
#'   collection exactly once. This prevents division by zero.}
#'  \item{norm}{\code{c("l1", "l2", "none")} Type of normalization to apply to term vectors.
#'   \code{"l1"} by default, i.e., scale by the number of words in the document. }
#'  \item{sublinear_tf}{\code{FALSE} Apply sublinear term-frequency scaling, i.e.,
#'  replace the term frequency with \code{1 + log(TF)}}
#' }
#' @export
#' @examples
#' data("movie_review")
#' N = 100
#' tokens = movie_review$review[1:N] %>% tolower %>% word_tokenizer
#' dtm = create_dtm(itoken(tokens), hash_vectorizer())
#' model_tfidf = TfIdf$new()
#' model_tfidf$fit(dtm)
#' dtm_1 = model_tfidf$transform(dtm)
#' dtm_2 = model_tfidf$fit_transform(dtm)
#' identical(dtm_1, dtm_2)
TfIdf = R6::R6Class(
  "tf_idf",
  inherit = text2vec_transformer,
  public = list(
    initialize = function(smooth_idf = TRUE,
                          norm = c('l1', 'l2', 'none'),
                          sublinear_tf = FALSE) {
      private$sublinear_tf = sublinear_tf
      private$smooth_idf = smooth_idf
      private$norm = match.arg(norm)
      private$internal_matrix_format = 'dgCMatrix'
    },
    fit = function(x, ...) {
      x_internal = private$prepare_x(x)
      private$idf = private$get_idf(x_internal)
      private$fitted = TRUE
      invisible(self)
    },
    fit_transform = function(x, ...) {
      x_internal = private$prepare_x(x)
      self$fit(x)
      x_internal %*% private$idf
    },
    transform = function(x, ...) {
      if (private$fitted)
        private$prepare_x(x) %*% private$idf
      else
        stop("Fit the model first!")
    }
  ),
  private = list(
    idf = NULL,
    norm = NULL,
    sublinear_tf = FALSE,
    smooth_idf = TRUE,
    prepare_x = function(x) {
      x_internal = coerce_matrix(x, private$internal_matrix_format, verbose = self$verbose)
      if(private$sublinear_tf)
        x_internal@x = 1 + log(x_internal@x)
      normalize(x_internal, private$norm)
    },
    get_idf = function(x) {
      # abs is needed for case when dtm is matrix from HashCorpus and signed_hash is used!
      cs = colSums( abs(sign(x) ) )
      if (private$smooth_idf)
        idf = log(nrow(x) / (cs + 1 ))
      else
        idf = log(nrow(x) / (cs))
      Diagonal(x = idf)
    }
  )
)
