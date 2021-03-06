
#' List materials
#' 
#' Materials in openBIS can represent a variety of objects. For the InfectX
#' HTS setup, this is mainly limited to either compounds such as oligos or
#' small molecule drugs and targeted genes. Three different objects are used to
#' identify a material: `MaterialGeneric`, `MaterialIdentifierGeneric` and
#' `MaterialIdentifierScreening`. Converting to id object types can be
#' achieved with `as_generic_mat_id()` and `as_screening_mat_id()` while
#' listing materials as `MaterialGeneric` objects is possible with
#' `list_material()`.
#' 
#' Unfortunately in this version of the openBIS JSON-RPC API, there is no
#' possibility for listing all available materials for a project or
#' experiment. Methods that return `MaterialGeneric` objects include
#' `list_material()`, which can be dispatched on material id objects and
#' objects representing plates, and [search_openbis()] with the target selector
#' `target_object` set to `material`. Coercing `MaterialGeneric` objects to
#' material id objects is possible with `as_generic_mat_id()` and
#' `as_screening_mat_id()` which do not incur an API call.
#' 
#' Instantiating material id objects is either done manually by calling
#' `material_id()` or by querying openBIS for `MaterialGeneric` objects and
#' converting to `MaterialIdentifierGeneric` or `MaterialIdentifierScreening`.
#' A material id object is defined by a material code and a material type.
#' Available types depend on whether generic or screening material objects are
#' of interest. For generic material objects, possible ids are
#'   * compound
#'   * control
#'   * esirna
#'   * gene
#'   * mirna
#'   * mirna_inhibitor
#'   * mirna_mimic
#'   * pooled_sirna
#'   * sirna
#' 
#' and for screening materials, ids can be
#'   * compound
#'   * gene
#'   * oligo
#' 
#' Material type objects can be instantiated by calling
#' `list_material_types()`, where the `mode` argument acts as a switch to
#' choose between generic and screening objects. If only a subset of types
#' are relevant, the output of `list_material_types()` can be limited by
#' passing a character vector with type names as `types` argument. The second
#' piece of information for constructing material id objects, material codes,
#' depends on material type. Genes, for example are identified with Entrez
#' gene ids (e.g. 2475 for MTOR), while for compounds, a manufacturer name is
#' used (e.g. for Ambion and MTOR, AMBION_S602, AMBION_S603 and AMBION_S604).
#' 
#' Whenever `list_material()` is dispatched on a (set of) material id
#' object(s), a (set of) `MaterialGeneric` object(s) is returned. However if
#' the dispatch occurs on plate objects (`Plate`, `PlateIdentifier` or
#' `PlateMetadata`), a (set of) `PlateWellMaterialMapping` objects is returned.
#' If `material_type` is not specified (i.e. `NULL`), the `mapping` field in
#' the returned object will contain `NULL` for each well. When passing a set
#' of `MaterialTypeIdentifierScreening` objects, as returned by
#' `list_material_types()`, the `mapping` fields will contain material type
#' information where available. The convenience function
#' `extract_well_material()` can be applied to a `PlateWellMaterialMapping`
#' object and will return the selected `MaterialIdentifierScreening` object.
#' 
#' @inheritParams logout_openbis
#' @param x A (vector of) `MaterialIdentifier` object(s).
#' @param code The material code for which an id object is created.
#' @param type The material type (possible values depend on mode).
#' @param mode Switch between generic and screening material id objects.
#' @param material_type A `MaterialTypeIdentifierScreening` object to restrict
#' the material listing to a certain type of materials.
#' @param ... Generic compatibility. Extra arguments will be passed to
#' [make_requests()].
#' 
#' @family object listing functions
#' 
#' @section openBIS:
#' * \Sexpr[results=rd]{infx::docs_link("gis", "getMaterialByCodes")}
#' * \Sexpr[results=rd]{infx::docs_link("sas", "listPlateMaterialMapping")}
#' 
#' @return Depending on the number of resulting objects, either a
#' [`json_class`] (single object) or a [`json_vec`] (multiple objects), is
#' returned. For `list_material()` and `extract_well_material()`, the
#' additional class attribute `MaterialGeneric` is added and the utility
#' functions `as_generic_mat_id()` and `as_screening_mat_id()` return
#' `MaterialIdentifierGeneric` and `MaterialIdentifierScreening` objects,
#' respectively, while `material_id()` can return either, depending on the
#' `mode` argument. Finally, `list_material_types()` returns
#' `MaterialTypeIdentifierGeneric` or `MaterialTypeIdentifierScreening`, again
#' depending on the `mode` argument.
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
#'   # list all material types
#'   types <- list_material_types()
#'   print(types)
#' 
#'   # list all gene targets on plate KB2-03-1I
#'   mat_map <- list_material(tok, samp, types[[2L]])
#'   print(mat_map, depth = 5, length = 20L)
#'   # there are maximally width x height entries arranged in a linear,
#'   # row-major fashion; missing entries are omitted, but original indices
#'   # are accessible as original_index attributes
#'   length(mat_map[["mapping"]])
#'   attr(mat_map[["mapping"]][[42L]], "original_index")
#'   # well A24 does not have a gene target as it is a MOCK control well
#'   extract_well_material(mat_map, "A", 24)
#'   # well A22 however has a gene target
#'   a_22 <- extract_well_material(mat_map, "A", 22)
#'   print(a_22, depth = 2L)
#' 
#'   # search for a material with material code 3480
#'   igf1r <- search_openbis(tok,
#'                           search_criteria(attribute_clause("code", 3480)),
#'                           target_object = "material")
#' 
#'   all.equal(as_screening_mat_id(igf1r), a_22, check.attributes = FALSE)
#'   identical(igf1r, list_material(tok, a_22))
#'   identical(igf1r, 
#'             search_openbis(tok,
#'                            search_criteria(
#'                              property_clause("gene_symbol", "IGF1R")
#'                            ),
#'                            target_object = "material"))
#' 
#'   # search for an experiment object corresponding to plate KB2-03-1I
#'   exp <- search_openbis(tok,
#'                         search_criteria(
#'                           attribute_clause(
#'                             "code",
#'                             samp[["experimentIdentifierOrNull"]]
#'                           )
#'                         ),
#'                         target_object = "experiment")
#' 
#'   # list all wells for the current material within the selected experiment
#'   wells <- list_wells(tok, a_22, experiment = exp)
#'   # this yields 3 plates, one of which is KB2-03-1I
#'   get_field(get_field(wells, "experimentPlateIdentifier"), "plateCode")
#'   # and the material of interest is in well A22 in each one
#'   unique(get_field(wells, "wellPosition"))
#' 
#'   logout_openbis(tok)
#' }
#' 
#' @export
#' 
list_material <- function(token, x, ...)
  UseMethod("list_material", x)

#' @rdname list_material
#' @export
#' 
list_material.MaterialIdentifierGeneric <- function(token, x, ...)
  make_request(api_url("gis", attr(token, "host_url"), ...),
               "getMaterialByCodes",
               list(token, as_json_vec(x)),
               ...)

#' @rdname list_material
#' @export
#' 
list_material.MaterialIdentifierScreening <- function(token, x, ...)
  list_material(token, as_generic_mat_id(x), ...)

list_plate_mat_map <- function(token, x, material_type = NULL, ...) {

  x <- as_json_vec(as_plate_id(x))

  if (!is.null(material_type)) {
    material_type <- as_json_vec(material_type)
    assert_that(has_subclass(material_type, "MaterialTypeIdentifierScreening"))
  } else
    material_type <- list(NULL)

  params <- lapply(material_type, function(y) list(token, x, y))

  res <- make_requests(api_url("sas", attr(token, "host_url"), ...),
                       "listPlateMaterialMapping",
                       params,
                       ...)
  res <- lapply(res, as_json_vec)

  as_json_vec(
    Map(set_attr,
        unlist(res, recursive = FALSE),
        rep(material_type, vapply(res, length, integer(1L))),
        MoreArgs = list(attr_name = "mat_type")),
    simplify = TRUE
  )
}

#' @rdname list_material
#' @export
#' 
list_material.PlateIdentifier <- list_plate_mat_map

#' @rdname list_material
#' @export
#' 
list_material.PlateMetadata <- list_plate_mat_map

#' @rdname list_material
#' @export
#' 
list_material.Plate <- list_plate_mat_map

#' @rdname list_material
#' @export
#' 
list_material.Sample <- function(token, x, material_type = NULL, ...)
  list_plate_mat_map(token, as_json_vec(as_plate_id(x)), material_type, ...)

#' @rdname list_material
#' @export
#' 
material_id <- function(code,
                        type = "gene",
                        mode = c("screening", "generic")) {

  mode <- match.arg(mode)

  if (length(type) == 1L)
    mat_type <- rep(list_material_types(mode, type), length(code))
  else {
    mat_type <- lapply(type, function(x) list_material_types(mode, x))
    mat_type <- as_json_vec(do.call(c, mat_type))
  }

  assert_that(length(mat_type) == length(code))

  class <- switch(mode,
                  generic = "MaterialIdentifierGeneric",
                  screening = "MaterialIdentifierScreening")

  as_json_vec(
    Map(json_class,
        materialTypeIdentifier = mat_type,
        materialCode = code,
        class = rep(class, length(code))),
    simplify = TRUE
  )
}

#' @param types Select one or several material types for which to return the
#' type id objects. NULL returns all available.
#' 
#' @rdname list_material
#' @export
#' 
list_material_types <- function(mode = c("screening", "generic"),
                                types = NULL) {

  mode <- match.arg(mode)

  all_types <- switch(mode,
                      generic = c("compound",
                                  "control",
                                  "esirna",
                                  "gene",
                                  "mirna",
                                  "mirna_inhibitor",
                                  "mirna_mimic",
                                  "pooled_sirna",
                                  "sirna"),
                      screening = c("compound",
                                    "gene",
                                    "oligo"))

  if (!is.null(types)) {
    assert_that(is.character(types),
                all(toupper(types) %in% toupper(all_types)))
  } else
    types <- all_types

  class <- switch(mode,
                  generic = "MaterialTypeIdentifierGeneric",
                  screening = "MaterialTypeIdentifierScreening")

  as_json_vec(
    Map(json_class,
        materialTypeCode = toupper(types),
        class = rep(class, length(types)),
        USE.NAMES = FALSE),
    simplify = TRUE
  )
}

as_mat_id <- function(x, mode) {

  x <- as_json_vec(x)

  as_json_vec(
    Map(material_id,
        code = get_field(x, "materialCode"),
        type = get_field(get_field(x, "materialTypeIdentifier"),
                         "materialTypeCode"),
        MoreArgs = list(mode = mode)),
    simplify = TRUE
  )
}

as_screening <- function(x, ...)
  as_mat_id(x, "screening")

as_generic <- function(x, ...)
  as_mat_id(x, "generic")

#' @rdname list_material
#' @export
#' 
as_screening_mat_id <- function(x, ...)
  UseMethod("as_screening_mat_id", x)

#' @rdname list_material
#' @export
#' 
as_screening_mat_id.MaterialGeneric <- as_screening

#' @rdname list_material
#' @export
#' 
as_screening_mat_id.MaterialScreening <- as_screening

#' @rdname list_material
#' @export
#' 
as_screening_mat_id.MaterialIdentifierGeneric <- as_screening

#' @rdname list_material
#' @export
#' 
as_screening_mat_id.MaterialIdentifierScreening <- function(x, ...)
  as_json_vec(x, simplify = TRUE)

#' @rdname list_material
#' @export
#' 
as_generic_mat_id <- function(x, ...)
  UseMethod("as_generic_mat_id", x)

#' @rdname list_material
#' @export
#' 
as_generic_mat_id.MaterialGeneric <- as_generic

#' @rdname list_material
#' @export
#' 
as_generic_mat_id.MaterialScreening <- as_generic

#' @rdname list_material
#' @export
#' 
as_generic_mat_id.MaterialIdentifierGeneric <- function(x, ...)
  as_json_vec(x, simplify = TRUE)

#' @rdname list_material
#' @export
#' 
as_generic_mat_id.MaterialIdentifierScreening <- as_generic

#' @param row Either a single integer or a single character specifying a
#' plate row.
#' @param col A single integer specifying a plate column.
#' 
#' @rdname list_material
#' @export
#' 
extract_well_material <- function(x, row, col) {

  x <- as_json_class(x)

  if (is.character(row))
    row <- match(toupper(row), LETTERS)

  assert_that(has_subclass(x, "PlateWellMaterialMapping"),
              is.count(row), is.count(col),
              row <= get_field(get_field(x, "plateGeometry"), "height"),
              col <= get_field(get_field(x, "plateGeometry"), "width"))

  ind <- (row - 1L) * get_field(get_field(x, "plateGeometry"), "width") + col

  mapping <- get_field(x, "mapping")

  if (all(vapply(mapping, has_attr, logical(1L), "original_index"))) {
    hit <- ind == vapply(mapping, attr, integer(1L), "original_index")
    assert_that(sum(hit) <= 1L)
    if (sum(hit) == 0L)
      list()
    else
      mapping[[which(hit)]]
  } else
    mapping[[ind]]
}