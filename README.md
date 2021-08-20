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

The major three differences are:

1. Transitions from `Arc` to `Waffle`.
2. Uses the official
[Google Cloud API client](https://hex.pm/packages/google_api_storage) for Elixir
rather than constructing XML requests and sending them over HTTP.
3. (In Progress) Implements the v4 URL signing process in addition to the existing v2 process.

Because Google now officially builds client libraries for Elixir, it is more
maintainable to use those libraries rather than relying on the older XML API.
The v2 URL signing process is also being deprecated in favor of the v4 process.
Although Google will give plenty of advance notice if/when the v2 process is
becoming unsupported, it's again more maintainable to use Google best practices
to ensure future compatibility.

## Installation

Add it to your mix dependencies:

```elixir
defp deps do
  [
    {:waffle_gcs, "~> 0.1"}
  ]
end
```

## Configuration

All configuration values are stored under the `:waffle` app key. E.g.

```elixir
config :waffle,
  storage: Waffle.Storage.Google.CloudStorage,
  bucket: "gcs-bucket",
  storage_dir: "uploads/waffle"
```

**Note**: a valid bucket name is a required config. This can either be a
hard-coded string (e.g. `"gcs-bucket"`) or a system env tuple (e.g.
`{:system, "WAFFLE_BUCKET"}`). You can also override this in your definition
module (e.g. `def bucket(), do: "my-bucket"`).

Authentication is done through Goth which requires credentials (https://github.com/peburrows/goth#installation).

### Custom Token Generation ###

By default, the credentials provided to Goth will be used to generate tokens.
If you have multiple sets of credentials in Goth or otherwise need more control
over token generation, you can define your own module:

```elixir
defmodule MyCredentials do
  @behaviour Waffle.Storage.Google.Token.Fetcher
  @impl Waffle.Storage.Google.Token.Fetcher
  def get_token(scopes) when is_list(scopes), do: get_token(Enum.join(scopes, " "))
  @impl Waffle.Storage.Google.Token.Fetcher
  def get_token(scope) when is_binary(scope) do
    {:ok, token} = Goth.Token.for_scope({"my-user@my-gcs-account.com", scope})
    token.token
  end
end
```

And configure it to use this new module instead of the default token generation:

```elixir
config :waffle,
  storage: Waffle.Storage.Google.CloudStorage,
  bucket: "gcs-bucket-name",
  token_fetcher: MyCredentials
```

## URL Signing

If your bucket/object permissions do not allow for public access, you will need
to use signed URLs to give people access to the uploaded files. This is done by
either passing `signed: true` to `CloudStorage.url/4` or by setting it in the
configs (`config :waffle, signed: true`). The default expiration time is one
hour but can be changed by setting the `:expires_in` config/option value. The
value is **the number of seconds** the URL should remain valid for after
generation.

## GCS object headers

You can specify custom object headers by defining `gcs_object_headers/2` in your definition which returns keyword list or map. E.g.

```
def gcs_object_headers(_version, {_file, _scope}) do
  [contentType: "image/jpeg"]
end
```

The list of all the supported attributes can be found here: https://hexdocs.pm/google_api_storage/GoogleApi.Storage.V1.Model.Object.html.

## GCS optional params

You can specify optional params by defining `gcs_optional_params/2` in your definition, which returns keywords list, E.g:

```
def gcs_optional_params(_version, {_file, _scope}) do
  [predefinedAcl: "publicRead"]
end
```

It will be used as `optional_params` argument in gcs request. List of all supported attributes can be found here: https://hexdocs.pm/google_api_storage/GoogleApi.Storage.V1.Api.Objects.html#storage_objects_insert_simple/7
