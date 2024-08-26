################################################################################
# Build stage 0
# Extract APM Server and make various file manipulations.
################################################################################
ARG BASE_REGISTRY=registry1.dsop.io
ARG BASE_IMAGE=redhat/ubi/ubi9
ARG BASE_TAG=8.10

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} AS prep_files

ARG ELASTIC_STACK=${APM_SERVER_VERSION}
ARG ELASTIC_PRODUCT=apm-server
ARG OS_AND_ARCH=linux-x86_64
