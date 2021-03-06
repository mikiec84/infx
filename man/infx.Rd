% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/infx.R
\docType{package}
\name{infx}
\alias{infx}
\alias{infx-package}
\title{API access to the InfectX data repository}
\description{
The \href{https://labnotebook.ch}{openBIS} data repository hosted by
\href{http://www.infectx.ch}{InfectX} contains high throughput screening data
from several large-scale gene knockdown experiments. The screens currently
publicly available are RNA interference based, use kinome-wide libraries
from multiple vendors and were carried out on HeLa cells, in presence of
several viral and bacterial pathogens. Further genome-wide screens have been
carried out and their public release is forthcoming. For more information,
please refer to the \href{https://ropensci.github.io/infx/}{README} or the
\href{../doc/infx-intro.html}{Introduction vignette}.
}
\details{
The provided functionality is not restricted to InfectX data, but applies
to the v1 JSON-RPC based openBIS API in general. Some parts of the API,
geared more towards data curation are currently not supported. For more
information on what API functions are available, have a look at the
\href{../doc/openbis-api.html}{openBIS API vignette}. The basic infrastructure
for creating and executing a request, as well as processing the response, is
exposed and missing functionality can easily be added.

Type information of JSON objects returned from the API is preserved as S3
class attribute and all retrieved JSON objects additionally inherit from the
S3 class \code{json_class}. As such, a \code{foobar} object retrieved from openBIS,
will have two class attributes: \code{foobar} and \code{json_class}. Sets of
\code{json_class} objects that are of the same sub-type can be represented as
\code{json_vec} objects of that sub-type. Several \code{foobar} objects therefore can
be combined into a list structure with S3 classes \code{foobar} and \code{json_vec},
where every entry in turn is an S3 object with types \code{foobar} and
\code{json_class}.\preformatted{examp <- json_vec(
  json_class(a = "foo", class = "foobar"),
  json_class(a = "bar", class = "foobar")
)
str(examp)

#> List of 2
#>  $ :List of 1
#>   ..$ a: chr "foo"
#>   ..- attr(*, "class")= chr [1:2] "foobar" "json_class"
#>  $ :List of 1
#>   ..$ a: chr "bar"
#>   ..- attr(*, "class")= chr [1:2] "foobar" "json_class"
#>  - attr(*, "class")= chr [1:2] "foobar" "json_vec"
}

Such an approach was chosen in order to not only have available generic
function dispatch on individual \code{json_class} objects, but also on sets (or
\emph{vectors}) of \code{json_class} objects. For more information on working with
\code{json_class} and \code{json_vec} objects refer to the
\href{#json-object-handling}{section on JSON objects} and
\href{../doc/json-class.html}{JSON object vignette}.

This documentation makes a distinction between objects in openBIS that exist
mainly for the purpose of organizing/grouping data and objects that
represent actual data resources. The most basic object in the organizational
hierarchy is that of a \code{Project}. Several \code{Experiment} objects may be
associated with a \code{Project} and \code{Sample} objects live in experiments. Given
the HTS-based context of InfectX data, samples typically represent
microtiter plates or individual plate wells. \code{Material} objects describe
agents applied to samples. Many of the InfectX screens are RNA interference-
based and therefore materials may be for example siRNA oligos or targeted
genes. Finally, samples are associated with \code{DataSet} objects that stand for
experimental measurements or data derived thereof.

Any type of data resource available in openBIS can be accessed as files
belonging to data sets. Due to the image-based nature of InfectX screens,
raw experimental data comes in the form of fluorescence microscopy imagery
which consequently constitutes the most basic form of data resource
available. It is therefore no surprise that image data receives special
treatment, allowing for more fine grained access and functionality that
helps with finding specific sub-sets of images. A further data resource
that comes with features similar to those of image data is termed feature
vector data sets. This is mostly tabular data with a single value
corresponding to an imaging site. This is typically used for image
acquisition meta data, summarized image analysis or quality control results.
}
\section{General comments}{

A login token is required for any type of API call. Passing valid login
credentials to \code{\link[=login_openbis]{login_openbis()}} will return a string that can subsequently
be used for making API requests. Login tokens are invalidated by calling
\code{\link[=logout_openbis]{logout_openbis()}} which is performed automatically upon garbage collection
of login tokens returned by \code{\link[=login_openbis]{login_openbis()}} with the \code{auto_disconnect}
switch set to \code{TRUE} (default). Validity of a login token can be checked
with \code{\link[=is_token_valid]{is_token_valid()}}.

All API requests are constructed by \code{\link[=make_requests]{make_requests()}} (or for single
requests by the wrapper function \code{\link[=make_request]{make_request()}}), which helps with putting
together JSON-RPC requests and parses the returned JSON objects by calling
\code{\link[=process_json]{process_json()}}. Processing of JSON involves generation of \code{json_class}
and \code{json_vec} objects using \code{@type} information, as well as resolution of
\code{@id} references. While obviously a feature for reducing data transfer
overhead, this type of data deduplication has the down-side of yielding
objects that are no longer self-contained. If for example plate wells are
listed and each well contains an object referencing the associated plate,
only a single instance of this plate object will be retrieved as part of the
first well object and all subsequent well objects only contain a reference
to this plate object. Sub-setting this list of wells however might yield
well objects with broken references. To circumvent such issues, all
references are resolved by a call to \code{\link[=resolve_references]{resolve_references()}}, initiated by
\code{\link[=process_json]{process_json()}}.

As a side note: while created for and mainly tested with
\href{https://infectx.biozentrum.unibas.ch/openbis}{InfectX} data, all API
methods can be used for accessing other openBIS instances as well.
Functions that issue API calls can all accept a \code{host_url} argument which
is forwarded to \code{\link[=api_url]{api_url()}} in \code{\link[=make_requests]{make_requests()}} in order to create API
endpoint urls. Another publicly available openBIS instance is the
\href{https://openbis-eln-lims.ethz.ch/openbis/}{demo} offered by the openBIS
development team. It can be accessed with both user name and password
\code{test_observer} both via a browser or by passing
\code{https://openbis-eln-lims.ethz.ch} as \code{host_url} to methods which
initiate API calls.

After being assembled by \code{\link[=make_requests]{make_requests()}}, requests are executed by
\code{\link[=do_requests_serial]{do_requests_serial()}} or \code{\link[=do_requests_parallel]{do_requests_parallel()}}, depending on whether
several API calls are constructed at the same time. The argument \code{n_con}
controls the degree of parallelism and if set to \code{1}, forces serial
execution even in cases where several requests are being issued. Failed
requests can be automatically repeated to provide additional stability by
setting the \code{n_try} argument to a value larger than \code{1} (default is \code{2}).
For more information on how to add further functionality using
\code{\link[=make_requests]{make_requests()}} and \code{\link[=do_requests_serial]{do_requests_serial()}}/\code{\link[=do_requests_parallel]{do_requests_parallel()}},
refer to the \href{../doc/openbis-api.html}{openBIS API vignette}.
}

\section{JSON object handling}{

Object structures as returned by openBIS can be instantiated using the
creator \code{\link[=json_class]{json_class()}}. This function takes an arbitrary set of key-value
pairs, followed by a class name and returns a list-based \code{json_class}
object. Existing list-based objects may be coerced to \code{json_class} using
\code{\link[=as_json_class]{as_json_class()}} where \code{@type} list entries are taken to be class types.
The inverse is achieved by calling \code{\link[=rm_json_class]{rm_json_class()}} on a \code{json_class}
object or by calling \code{\link[=as_list]{as_list()}} and passing the \code{keep_asis} argument as
\code{FALSE}. \code{json_class} objects can be validated with \code{\link[=is_json_class]{is_json_class()}} which
is recursively called on any object inheriting from \code{json_class} in
\code{\link[=check_json_class]{check_json_class()}}.

Similarly to \code{json_class} objects, a constructor for \code{json_vec} objects is
provided in the form of \code{\link[=json_vec]{json_vec()}} and existing structures can be coerced
to \code{json_vec} by \code{\link[=as_json_vec]{as_json_vec()}}. The validator function \code{\link[=is_json_vec]{is_json_vec()}}
tests whether an object is a properly formed \code{json_vec} object and the
utility function \code{\link[=has_common_subclass]{has_common_subclass()}} tests whether the passed list
structure consists of \code{json_class} objects of the same sub-type. The inverse
of applying \code{\link[=as_json_vec]{as_json_vec()}} to a list structure is achieved by passing a
\code{json_vec} object to \code{\link[=as_list]{as_list()}}.

Several utility functions are provided that facilitate handling of
\code{json_class} and \code{json_vec} objects. \code{\link[=has_fields]{has_fields()}} tests whether certain
named entries are present in a \code{json_class} object or in each member of a
\code{json_vec}. In order to extract the content of a field, \code{\link[=get_field]{get_field()}} can be
applied to \code{json_class} and \code{json_vec} objects. Analogously,
\code{\link[=has_subclass]{has_subclass()}} and \code{\link[=get_subclass]{get_subclass()}} test for and extract the original JSON
object type from \code{json_class} and \code{json_vec} objects. Finally,
\code{\link[=remove_null]{remove_null()}} recursively removes empty fields (fields containing \code{NULL})
from \code{json_class} and \code{json_vec} objects.

In addition to the mentioned utility functions, several base R generic
functions have \code{json_class} and \code{json_vec} specific methods implemented.
Combining several \code{json_class} objects using \code{\link[base:c]{base::c()}} yields a \code{json_vec}
object, as does repeating objects using \code{\link[base:rep]{base::rep()}}. The same functions
can be applied to \code{json_vec} objects but this only checks for agreement in
sub-type. Custom sum-setting is provided as well, in order to retain class
attributes and replacement functions acting on \code{json_vec} objects make sure
that sub-types remain compatible. Recursive printing of both \code{json_class}
and \code{json_vec} objects is possible by calling \code{\link[base:print]{base::print()}}. Recursion
depth, as well as printing length and width can be controlled via arguments,
as can fancy printing (colors and UTF box characters for visualizing tree
structures).
}

\section{Listing and searching for objects}{

OpenBIS projects can be listed by calling \code{\link[=list_projects]{list_projects()}} and experiments
are enumerated with \code{\link[=list_experiments]{list_experiments()}}. Two objects types are used for
representing experiments: \code{Experiment} and \code{ExperimentIdentifier}.
\code{\link[=as_experiment_id]{as_experiment_id()}} converts a set of \code{Experiment} objects to
\code{ExperimentIdentifier} (requires no API call) and the inverse is possible
by passing a set of \code{ExperimentIdentifier} objects to \code{\link[=list_experiments]{list_experiments()}}
(does require an API call). All available experiments can be listed as
\code{ExperimentIdentifier} objects using \code{\link[=list_experiment_ids]{list_experiment_ids()}} and all
experiments for a set of projects are enumerated by passing \code{Project}
objects to \code{\link[=list_experiments]{list_experiments()}}. Experiments have a type and all realized
types can be listed with \code{\link[=list_experiment_types]{list_experiment_types()}}.

Experiments consist of samples which can be listed by passing a set of
\code{Experiment} or \code{ExperimentIdentifier} objects to \code{\link[=list_samples]{list_samples()}}. Samples
too have a type and all types are retrieved by calling
\code{\link[=list_sample_types]{list_sample_types()}}. Additional object types that are used to represent
samples are plate and well objects, including \code{Plate}, \code{PlateIdentifier},
\code{PlateMetadata}, \code{WellIdentifier} and \code{WellMetadata}, all of which can be
converted to \code{Sample} objects by calling \code{\link[=list_samples]{list_samples()}}. Plate objects
can be listed using \code{\link[=list_plates]{list_plates()}}, which can either return all available
plate objects or plates for a given set of experiments (passed as
\code{Experiment} or \code{ExperimentIdentifier} objects). Plate meta data, which
also contains associated well meta data is retrieved by
\code{\link[=list_plate_metadata]{list_plate_metadata()}} which can act on plate objects (\code{Plate},
\code{PlateIdentifier} or \code{Sample}). Wells of a plate are listed with
\code{\link[=list_wells]{list_wells()}} which too may be dispatched on plate objects. Wells
associated with a material object can be enumerated by passing a set of
\code{MaterialScreening}, \code{MaterialIdentifierScreening}, \code{MaterialGeneric} or
\code{MaterialIdentifierGeneric} to \code{\link[=list_wells]{list_wells()}}.

Data set objects represent the most diverse group of data-organizational
structures. Possible types include \code{DataSet}, \code{DatasetIdentifier},
\code{DatasetReference}, \code{ImageDatasetReference}, \code{MicroscopyImageReference},
\code{PlateImageReference}, \code{FeatureVectorDatasetReference} and
\code{FeatureVectorDatasetWellReference}. Full \code{DataSet} objects are returned by
\code{\link[=list_datasets]{list_datasets()}}, either for a set of plate samples, experiments or data
set codes (passed as character vector). \code{\link[=list_dataset_ids]{list_dataset_ids()}} gives back
\code{DatasetIdentifier} objects, either for a set of \code{DataSet} objects or data
set codes (again passed as character vector). The remaining data set types
are generated by \code{\link[=list_references]{list_references()}}, and return type depends on input
arguments.

Whenever \code{\link[=list_references]{list_references()}} is dispatched on objects identifying a plate
sample (\code{Plate}, \code{PlateIdentifier}, \code{PlateMetadata} or \code{Sample}), a \code{type}
argument is available, which can be any of \code{raw}, \code{segmentation} or
\code{feature}. Depending on \code{type}, \code{ImageDatasetReference} or
\code{FeatureVectorDatasetReference} objects are returned. The former type of
objects represent plate-wise image data sets (either for raw images or
segmentation masks) while the latter type references feature vector data
sets.

Dispatch of \code{\link[=list_references]{list_references()}} is also possible on objects identifying
data sets and again the return type depends on further arguments. If
imaging channels are specified as \code{channels} argument, but not specific
wells are selected, \code{MicroscopyImageReference} objects are retrieved,
representing a plate-wide raw imaging data set per imaging site and imaging
channel. If in addition to imaging channels, wells are specified
(\code{WellPosition} objects, e.g. created by \code{\link[=well_pos]{well_pos()}}, passed as \code{wells}
argument), the return type changes to \code{PlateImageReference}. Such objects
precisely reference an image, by encoding imaging channel, imaging site,
well position and pate-wise imaging data set.

Finally, \code{\link[=list_references]{list_references()}} can be dispatched on material objects,
including \code{MaterialGeneric}, \code{MaterialScreening},
\code{MaterialIdentifierGeneric} and \code{MaterialIdentifierScreening}, in which case
\code{PlateWellReferenceWithDatasets} objects are returned. While themselves
not representing data sets, \code{PlateWellReferenceWithDatasets} contain all
respective \code{ImageDatasetReference} and \code{FeatureVectorDatasetReference}
objects.
}

\section{Search for objects}{

Instead of enumerating objects using the various \code{list_*()} functions,
search queries can be constructed and run against openBIS. A search query
consists of a possibly nested \code{SearchCriteria} object as instantiated by
\code{\link[=search_criteria]{search_criteria()}} and is executed by calling \code{\link[=search_openbis]{search_openbis()}}.
\code{SearchCriteria} objects are composed of a set of match clauses (see
\code{\link[=property_clause]{property_clause()}}, \code{\link[=any_property_clause]{any_property_clause()}}, \code{\link[=any_field_clause]{any_field_clause()}},
\code{\link[=attribute_clause]{attribute_clause()}} and \code{\link[=time_attribute_clause]{time_attribute_clause()}}) which are combined by
an operator (either \code{any} or \code{all}).

Additionally, a single \code{SearchSubCriteria} may be attached to every
\code{SearchCriteria} object which in turn consists of a \code{SearchCriteria} and an
object type to which this search criteria object is applied to. In the call
to \code{\link[=search_openbis]{search_openbis()}} a target type has to be specified as \code{target_object}
argument (default is \code{data_set} and possible alternatives are \code{experiment},
\code{material} as well as \code{sample}) to indicate what object type the search is
targeted at.
}

\section{Downloading data}{

As mentioned earlier, there are three types of data resources that can be
downloaded: files, images and feature vector data. File access is the most
basic method and any type of data (including images and feature data) is
available via this route. Accessing images and feature data using
specialized interfaces however simplifies and makes possibly more specific
data access.

Files can be listed for any object representing a data set as well as for a
character vector of data set codes using \code{\link[=list_files]{list_files()}}. An object type,
specialized for referencing files in a data set is available as
\code{DataSetFileDTO} can also be passed to \code{\link[=list_files]{list_files()}}. This is useful
whenever only a subset of files within a data set, contained in a folder,
are of interest. In any case, \code{\link[=list_files]{list_files()}} returns a set of
\code{FileInfoDssDTO} objects. As no data set information is encoded in
\code{FileInfoDssDTO} objects, \code{\link[=list_files]{list_files()}} saves data set codes as \code{data_set}
attributes with each object. Download of files is done using
\code{\link[=fetch_files]{fetch_files()}}, which requires for every requested file, the data set code
and file path. This information can be passed as separate character vectors,
\code{DataSetFileDTO} objects or \code{FileInfoDssDTO} objects with data set
information passed separately as character vector or as \code{data_set}
attribute with each object. Furthermore data set membership information can
be passed as any type of data set object and if no file paths are
specified, all available files for the given data sets are retrieved.

\code{\link[=fetch_files]{fetch_files()}} internally creates download urls by calling
\code{\link[=list_download_urls]{list_download_urls()}} and uses \code{\link[=do_requests_serial]{do_requests_serial()}} or
\code{\link[=do_requests_parallel]{do_requests_parallel()}} to execute the downloads. Whether downloads are
performed in serial or parallel fashion can be controlled using the \code{n_con}
argument. Additionally a function may be passed to \code{\link[=fetch_files]{fetch_files()}} as
\code{reader} argument which will be called on each downloaded file.

Images are retrieved using \code{\link[=fetch_images]{fetch_images()}}. If dispatch occurs on general
purpose data set objects, including \code{DatasetIdentifier}, \code{DatasetReference}
or \code{ImageDatasetReference}, further arguments for identifying images are
passed as \code{channels} and \code{well_positions}. As \code{MicroscopyImageReference}
objects already contain channel information, only well positions are needed
in order to specify images. Somewhat surprisingly, image tile information
which is also part of \code{MicroscopyImageReference} objects is disregarded and
images are fetched for entire wells. Data sets that are connected to wells
and not plates can be passed to \code{\link[=fetch_images]{fetch_images()}} without additionally
specifying well locations. Images can be scaled down to smaller sizes either
by setting the \code{thumbnails} argument to \code{TRUE} (only possible for data sets
connected to wells instead of plates, as the corresponding API call does
not support selecting wells) or by passing an \code{ImageSize} object as
\code{image_size} argument, in which case returned images will be scaled to fit
within the box specified by the \code{ImageSize} object, while retaining the
original aspect ratio.

\code{PlateImageReference} objects most precisely reference images, as they
contain data set, well location, site location and channel information. If
a set of \code{PlateImageReference} objects is passed to \code{\link[=fetch_images]{fetch_images()}}, image
size can be set using the \code{thumbnails} or \code{image_size} arguments and image
file type can be forced to png using the \code{force_png} switch. Most
fine-grained control over the returned images is achieved by using
\code{ImageRepresentationFormat} objects. Pre-defined format objects can be
retrieved per data set by calling \code{\link[=list_image_metadata]{list_image_metadata()}} with \code{type} set to
\code{format}. General image meta data, such as tile layout and channel
information is returned by \code{\link[=list_image_metadata]{list_image_metadata()}} if the \code{type} argument
is left at default value \code{metadata}.

Two types of objects are central to specifying feature data sets:
\code{FeatureVectorDatasetReference} and \code{FeatureVectorDatasetWellReference}
where the former object type references feature data for an entire plate and
the latter for individual wells on a plate. Both object types may be passed
to \code{\link[=fetch_features]{fetch_features()}} which returns objects of type \code{FeatureVectorDataset}
whenever a full plate is requested and \code{FeatureVectorWithDescription} for
individual wells. Features are selected by passing a character vector of
feature codes as \code{feature_codes} argument, the possible values of which
can be enumerated for a feature vector data set by calling
\code{\link[=list_feature_codes]{list_feature_codes()}} or by extracting the \code{code} entries from
\code{FeatureInformation} objects as retrieved by \code{\link[=list_features]{list_features()}}. In case the
\code{feature_codes} argument is left at default value (\code{NA}), all available
features are returned by \code{\link[=fetch_features]{fetch_features()}}.
}

