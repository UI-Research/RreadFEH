% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_feh_micro.R
\name{make_record_struct}
\alias{make_record_struct}
\title{Reads from an open FEH header file and returns a record structure}
\usage{
make_record_struct(file, read_frame)
}
\arguments{
\item{file}{a connection to a header file pointing to a beginning of a header}

\item{read_frame}{a function that reads a frame in a header file (read_out_frame or read_in_frame)}
}
\description{
Reads from an open FEH header file and returns a record structure
}
