
#' List datasets and dataset reference objects
#'
#' All available datasets for the specified experiment(s), sample(s) or
#' dataset code(s) are retrieved as `DataSet` objects by
#' `list_datasets()`. Each dataset has a type and all realized type
#' identifiers can be listed using `list_dataset_types()`. A more compact
#' object type, uniquely identifying a `DataSet`, is that of a
#' `DatasetIdentifier`. Given either a set of `DataSet` objects or a character
#' vector holding (a) dataset code(s), `list_dataset_id()` fetches the
#' corresponding `DatasetIdentifier` objects. Behavior of the function
#' `list_references()`, in particular the returned object type, depends on
#' input types. For more information, please refer to the details section.
#' 
#' `list_datasets()` is an s3 generic function that can be dispatched on
#' `Sample` and `Experiment` objects, as well as character vectors containing
#' dataset codes and it returns sets of `DataSet` objects. Additionally it
#' can be requested that parent or child datasets are to be included as well.
#' 
#' Several classes in addition to `DatasetIdentifier` implement the
#' `IDatasetIdentifier` interface, including
#'   * `DatasetReference`
#'   * `FeatureVectorDatasetReference`
#'   * `FeatureVectorDatasetWellReference`
#'   * `ImageDatasetReference`
#'   * `MicroscopyImageReference`
#'   * `PlateImageReference`
#' 
#' The return type of `list_references()` depends on dispatch object type and
#' in some cases on additional arguments. If the s3 generic function
#' `list_references()` is dispatched on plate objects (`Plate`,
#' `PlateIdentifier` or `PlateMetadata` or `Sample` objects, representing
#' plates), `ImageDatasetReference` objects are returned (except if the type
#' argument is set to `feature`, in which case, if
#' `MaterialIdentifierScreening` objects are used as input,
#' `PlateWellReferenceWithDatasets` objects are returned, which each contain
#' `ImageDatasetReference` and `FeatureVectorDatasetReference` objects.
#' 
#' Whenever `list_references()` is dispatched on dataset ids or dataset
#' reference objects, the resulting object type depends on whether a (set of)
#' `WellPosition` object(s) were specified as `wells` argument. For its
#' default value (NULL), a set of `MicroscopyImageReference` objects is
#' returned, while `PlateImageReference` objects are returned otherwise.  
#' 
#' @inheritParams logout_openbis
#' @param x Object to limit search for datasets/files with.
#' @param ... Generic compatibility. Extra arguments will be passed to
#' [make_requests()].
#' 
#' @section Implementation note: The API function `listDataSetsForSample()`
#' has a parameter `areOnlyDirectlyConnectedIncluded`, which is currently
#' fixed to `TRUE`. The  documentation contains the following explanation:
#' 
#' > If true, only datasets that are directly connected to the sample are
#' included, otherwise datasets of child samples are included as well.
#' 
#' This does however not seem to correspond to including child datasets in the
#' API call to `listDataSets()` via its `connectionsToGet` argument. As long
#' as it is not entirely clear how the inclusion of child/parent datasets
#' differs from setting `areOnlyDirectlyConnectedIncluded` to `FALSE`, this
#' option is not exposed to the user.
#' 
#' @family object listing functions
#' 
#' @return Depending on the number of resulting objects, either a
#' [`json_class`] (single object) or a [`json_vec`] (multiple objects), is
#' returned. For the specific sub-class, refer to the *Details* section.
#' 
#' @examples
#' \donttest{
#'   tok <- login_openbis()
#' 
#'   # search for a sample object corresponding to plate KB2-03-1I
#'   samp <- search_openbis(tok,
#'                          search_criteria(
#'                            attribute_clause("code",
#'                                             "/INFECTX_PUBLISHED/KB2-03-1I")
#'                          ),
#'                          target_object = "sample")
#' 
#'   # list all datasets associated with this plate
#'   ds <- list_datasets(tok, samp)
#' 
#'   # select a feature dataset, note how the fields "parentCodes" and
#'   # "childrenCodes" both are not set
#'   feat_ds <- ds[[grep("FEATURES_CC_MAT",
#'                       get_field(ds, "dataSetTypeCode"))]]
#' 
#'   # fetch parent and child datasets and now both the "parentCodes" and
#'   # "childrenCodes" fields are populated with the corresponding codes
#'   feat_ds <- list_datasets(tok, get_field(feat_ds, "code"), include = "all")
#' 
#'   # re-using the plate sample from above, an ImageDatasetReference object
#'   # corresponding to the associated raw imaging dataset is listed
#'   raw_ref <- list_references(tok, samp)
#'   # available imaging channels are
#'   get_field(raw_ref, "properties")[["IMAGE.CHANNEL.LIST"]]
#' 
#'   # a more specific image reference object can be retrieved by passing a
#'   # well specification to list_references()
#'   well_ref <- list_references(tok, raw_ref,
#'                               wells = well_pos(name = "A2"),
#'                               channel = "DAPI")
#'   # a reference to 9 images is returned, as there are 3 x 3 imaging tiles
#'   # per well
#'   length(well_ref)
#' 
#'   logout_openbis(tok)
#' }
#' 
#' @export
#' 
list_datasets <- function(token, x, ...)
  UseMethod("list_datasets", x)

#' @rdname list_datasets
#' 
#' @param include String indicating whether to include parent/child datasets
#' as well.
#' 
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("gis", "listDataSetsForSample")}
#' * \Sexpr[results=rd]{infx::docs_link("gis", "listDataSets")}
#' 
#' @export
#' 
list_datasets.Sample <- function(token,
                                 x,
                                 include = c(NA, "children", "parents", "all"),
                                 ...) {

  include <- resolve_fetch_opts(include)
  x <- as_json_vec(remove_null(x))

  if (length(include) == 0L) {

    if (length(x) == 1L)
      make_request(api_url("gis", attr(token, "host_url"), ...),
                   "listDataSetsForSample",
                   list(token, x[[1L]], TRUE),
                   ...)
    else
      make_request(api_url("gis", attr(token, "host_url"), ...),
                   "listDataSets",
                   list(token, x),
                   ...)

  } else
    make_request(api_url("gis", attr(token, "host_url"), ...),
                 "listDataSets",
                 list(token, x, include),
                 ...)
}

#' @rdname list_datasets
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("gis", "listDataSetsForExperiments")}
#' @export
#' 
list_datasets.Experiment <- function(token,
                                     x,
                                     include = c(NA, "children", "parents",
                                                 "all"),
                                     ...) {

  make_request(api_url("gis", attr(token, "host_url"), ...),
               "listDataSetsForExperiments",
               list(token,
                    as_json_vec(remove_null(x)),
                    resolve_fetch_opts(include)),
               ...)
}

#' @rdname list_datasets
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("gis", "getDataSetMetaData")}
#' @export
#' 
list_datasets.character <- function(token,
                                    x,
                                    include = c(NA, "children", "parents",
                                                "all"),
                                    ...) {

  include <- resolve_fetch_opts(include)

  if (length(include) == 2L)
    make_request(api_url("gis", attr(token, "host_url"), ...),
                 "getDataSetMetaData",
                 list(token, as.list(x)),
                 ...)
  else
    make_request(api_url("gis", attr(token, "host_url"), ...),
                 "getDataSetMetaData",
                 list(token, as.list(x), include),
                 ...)
}

#' @rdname list_datasets
#' @export
#' 
list_dataset_ids <- function(token, x, ...)
  UseMethod("list_dataset_ids", x)

#' @rdname list_datasets
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("sas", "getDatasetIdentifiers")}
#' @export
#' 
list_dataset_ids.character <- function(token, x, ...)
  make_request(api_url("sas", attr(token, "host_url"), ...),
               "getDatasetIdentifiers",
               list(token, as.list(x)),
               ...)

#' @rdname list_datasets
#' @export
#' 
list_dataset_ids.DataSet <- function(token, x, ...)
  list_dataset_ids(token, dataset_code(x), ...)

#' @rdname list_datasets
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("sas", "listRawImageDatasets")}
#' * \Sexpr[results=rd]{infx::docs_link("sas",
#'                      "listSegmentationImageDatasets")}
#' * \Sexpr[results=rd]{infx::docs_link("sas", "listFeatureVectorDatasets")}
#' @export
#' 
list_references <- function(token, x, ...)
  UseMethod("list_references", x)

list_img_ds <- function(token,
                        x,
                        type = c("raw", "segmentation", "feature"),
                        ...) {

  type <- match.arg(type)

  fun <- switch(match.arg(type),
                raw = "listRawImageDatasets",
                segmentation = "listSegmentationImageDatasets",
                feature = "listFeatureVectorDatasets")

  make_request(api_url("sas", attr(token, "host_url"), ...),
               fun,
               list(token, as_json_vec(as_plate_id(x))),
               ...)
}

#' @rdname list_datasets
#' 
#' @param type For listing image datasets, it can be specified, whether only
#' raw image datasets, only segmentation image datasets or any kind of image
#' datasets (default) are to be listed.
#' 
#' @export
#' 
list_references.PlateIdentifier <- list_img_ds

#' @rdname list_datasets
#' @export
#' 
list_references.Plate <- list_img_ds

#' @rdname list_datasets
#' @export
#' 
list_references.PlateMetadata <- list_img_ds

#' @rdname list_datasets
#' @export
#' 
list_references.Sample <- list_img_ds

list_ref_for_material <- function(token, x, experiment = NULL, ...)
  list_wells(token, x, experiment, include_datasets = TRUE, ...)

#' @rdname list_datasets
#' 
#' @param experiment When searching for datasets associated with materials,
#' the search can be limited to a single experiment.
#' 
#' @export
#' 
list_references.MaterialGeneric <- list_ref_for_material

#' @rdname list_datasets
#' @export
#' 
list_references.MaterialScreening <- list_ref_for_material

#' @rdname list_datasets
#' @export
#' 
list_references.MaterialIdentifierGeneric <- list_ref_for_material

#' @rdname list_datasets
#' @export
#' 
list_references.MaterialIdentifierScreening <- list_ref_for_material

list_img_ref_wrapper <- function(token, x, wells = NULL, channels, ...)
  list_img_ref(token, x, wells, channels, ...)

#' @rdname list_datasets
#' 
#' @param wells A (set of) `WellPosition` object(s) to limit the dataset
#' listing to.
#' @param channels A character vector with imaging channel names to limit the
#' dataset listing to.
#' 
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("dsrs", "listImageReferences")}
#' * \Sexpr[results=rd]{infx::docs_link("dsrs", "listPlateImageReferences")}
#' 
#' @export
#' 
list_references.DatasetIdentifier <- list_img_ref_wrapper

#' @rdname list_datasets
#' @export
#' 
list_references.DataSet <- function(token, x, wells = NULL, channels, ...)
  list_references(token, list_dataset_ids(token, x, ...), wells, channels, ...)

#' @rdname list_datasets
#' @export
#' 
list_references.DatasetReference <- list_img_ref_wrapper

#' @rdname list_datasets
#' @export
#' 
list_references.FeatureVectorDatasetReference <- list_img_ref_wrapper

#' @rdname list_datasets
#' @export
#' 
list_references.FeatureVectorDatasetWellReference <- list_img_ref_wrapper

#' @rdname list_datasets
#' @export
#' 
list_references.ImageDatasetReference <- list_img_ref_wrapper

#' @rdname list_datasets
#' @export
#' 
list_references.MicroscopyImageReference <- list_img_ref_wrapper

#' @rdname list_datasets
#' @export
#' 
list_references.PlateImageReference <- list_img_ref_wrapper

#' List image references
#' 
#' Used for double dispatching on the `list_datasets()` generic, list image
#' reference objects either for a specific (set of) `WellPosition` object(s)
#' or for the specified datasets in general.
#' 
#' @inheritParams list_datasets
#' 
#' @keywords internal
#' 
#' @export
#' 
list_img_ref <- function(token, x, wells = NULL, channels, ...)
  UseMethod("list_img_ref", wells)

#' @rdname list_img_ref
#' @keywords internal
#' @export
#' 
list_img_ref.NULL <- function(token, x, wells, channels, ...) {

  x <- as_json_vec(x)

  if (length(channels) > 1L)
    channels <- as.list(channels)

  params <- lapply(x, function(z) list(token, z, channels))

  res <- make_requests(api_url("dsrs", attr(token, "host_url"), ...),
                       "listImageReferences",
                       params,
                       ...)
  res <- lapply(res, as_json_vec)

  as_json_vec(
    Map(set_attr,
        unlist(res, recursive = FALSE),
        rep(x, vapply(res, length, integer(1L))),
        MoreArgs = list(attr_name = "data_set")),
    simplify = TRUE
  )
}

#' @rdname list_img_ref
#' @keywords internal
#' @export
#' 
list_img_ref.WellPosition <- function(token, x, wells, channels, ...) {

  x <- as_json_vec(x)
  wells <- as_json_vec(wells)

  if (length(channels) > 1L)
    channels <- as.list(channels)

  params <- lapply(x, function(z) list(token, z, wells, channels))

  res <- make_requests(api_url("dsrs", attr(token, "host_url"), ...),
                       "listPlateImageReferences",
                       params,
                       ...)
  res <- lapply(res, as_json_vec)

  as_json_vec(
    Map(set_attr,
        unlist(res, recursive = FALSE),
        rep(x, vapply(res, length, integer(1L))),
        MoreArgs = list(attr_name = "data_set")),
    simplify = TRUE
  )
}

#' @rdname list_datasets
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("gis", "listDataSetTypes")}
#' @export
#' 
list_dataset_types <- function(token, ...)
  make_request(api_url("gis", attr(token, "host_url"), ...),
               "listDataSetTypes",
               list(token),
               ...)

#' Extract dataset code
#' 
#' Given a (set of) dataset object(s), for each one extract the dataset code
#' and return a character vector of codes.
#' 
#' @param x Dataset object(s).
#' @param ... Generic compatibility.
#' 
#' @keywords internal
#' @export
#' 
dataset_code <- function(x, ...)
  UseMethod("dataset_code")

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.DataSet <- function(x, ...)
  get_field(x, "code")

ds_code_ds_id <- function(x, ...)
  get_field(x, "datasetCode")

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.DatasetIdentifier <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.DatasetReference <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.FeatureVectorDatasetReference <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.FeatureVectorDatasetWellReference <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.ImageDatasetReference <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.MicroscopyImageReference <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.PlateImageReference <- ds_code_ds_id

#' @rdname dataset_code
#' @keywords internal
#' @export
#' 
dataset_code.DataSetFileDTO <- function(x, ...)
  get_field(x, "dataSetCode")

resolve_fetch_opts <- function(x = c(NA, "children", "parents", "all")) {

  x <- match.arg(x)

  if (is.na(x))
    list()
  else if (x == "all")
    list("CHILDREN", "PARENTS")
  else
    list(toupper(x))
}
