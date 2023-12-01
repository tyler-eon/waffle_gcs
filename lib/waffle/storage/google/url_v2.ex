defmodule Waffle.Storage.Google.UrlV2 do
  @moduledoc """
  This is an implementation of the v2 URL signing for Google Cloud Storage. See
  [the Google documentation](https://cloud.google.com/storage/docs/access-control/signed-urls-v2)
  for more details.

  The bulk of the major logic is taken from Martide's `arc_gcs` work:
  https://github.com/martide/arc_gcs.
  """

  use Waffle.Storage.Google.Url

  alias Waffle.Types
  alias Waffle.Storage.Google.{CloudStorage, Util}

  # Default expiration time is 3600 seconds, or 1 hour
  @default_expiry 3600

  # It's unlikely, but in the event that someone accidentally tries to give a
  # zero or negative expiration time, this will be used to correct that mistake
  @min_expiry 1

  # Maximum expiration time is 7 days from the creation of the signed URL
  @max_expiry 604800

  # The official Google Cloud Storage host
  @endpoint "storage.googleapis.com"

  @doc """
  Returns the amount of time, in seconds, before a signed URL becomes invalid.
  Assumes the key for the option is `:expires_in`.
  """
  @spec expiry(Keyword.t) :: pos_integer
  def expiry(opts \\ []) do
    case Util.option(opts, :expires_in, @default_expiry) do
      val when val < @min_expiry -> @min_expiry
      val when val > @max_expiry -> @max_expiry
      val -> val
    end
  end

  @doc """
  Determines whether or not the URL should be signed. Assumes the key for the
  option is `:signed`.
  """
  @spec signed?(Keyword.t) :: boolean
  def signed?(opts \\ []), do: Util.option(opts, :signed, false)

  @doc """
  Returns the remote asset host. The config key is assumed to be `:asset_host`.
  """
  @spec endpoint(Keyword.t) :: String.t
  def endpoint(opts \\ []) do
    opts
    |> Util.option(:asset_host, @endpoint)
    |> Util.var()
  end

  @impl Waffle.Storage.Google.Url
  def build(definition, version, meta, options) do
    path = CloudStorage.path_for(definition, version, meta)

    if signed?(options) do
      build_signed_url(definition, path, options)
    else
      build_url(definition, path)
    end
  end

  @spec build_url(Types.definition, String.t) :: String.t
  defp build_url(definition, path) do
    %URI{
      host: endpoint(),
      path: build_path(definition, path),
      scheme: "https"
    }
    |> URI.to_string()
  end

  @spec build_signed_url(Types.definition, String.t, Keyword.t) :: String.t
  defp build_signed_url(definition, path, options) do
    client = GcsSignedUrl.Client.load_from_file(definition.service_account_path())
    opts = [expires: @default_expiry] |> Keyword.merge(options)
    GcsSignedUrl.generate_v4(client, CloudStorage.bucket(definition), path, opts)
  end

  @spec build_path(Types.definition, String.t) :: String.t
  defp build_path(definition, path) do
    path = if endpoint() != @endpoint do
      path
    else
      bucket_and_path(definition, path)
    end

    path
    |> Util.prepend_slash()
    |> URI.encode()
  end

  @spec bucket_and_path(Types.definition, String.t) :: String.t
  defp bucket_and_path(definition, path) do
    definition
    |> CloudStorage.bucket()
    |> Path.join(path)
  end
end
