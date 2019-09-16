# Waffle GCS

[![Build Status](https://travis-ci.org/kolorahl/waffle_gcs.svg?branch=master)](https://travis-ci.org/kolorahl/waffle_gcs)

Google Cloud Storage for Waffle

## What's Waffle?

[Waffle](https://github.com/elixir-waffle/waffle) (formerly _Arc_) is a file
uploading library for Elixir. It's main goal is to provide "plug and play" file
uploading and retrieval functionality for any storage provider (e.g. AWS S3,
Google Cloud Storage, etc).

## What's Waffle GCS?

Waffle GCS provides an integration between Waffle and Google Cloud Storage. It
is (in my opinion) the spiritual successor to
[arc_gcs](https://github.com/martide/arc_gcs). If you want to easily upload and
retrieve files using Google Cloud Storage as your provider, and you also use
Waffle, then this library is for you.

## What's different from `arc_gcs`?

The major two differences are:

1. Uses the official
[Google Cloud API client](https://hex.pm/packages/google_api_storage) for Elixir
rather than constructing XML requests and sending them over HTTP.
2. Implements the v4 URL signing process in addition to the existing v2 process.

Because Google now officially builds client libraries for Elixir, it is more
maintainable to use those libraries rather than relying on the older XML API.
The v2 URL signing process is also being deprecated in favor of the v4 process.
Although Google will give plenty of advance notice if/when the v2 process is
becoming unsupported, it's again more maintainable to use Google best practices
to ensure future compatibility.
