defmodule Waffle.Storage.Google.CloudStorage do
  @moduledoc """
  The main storage integration for Waffle, this acts primarily as a wrapper
  around `Google.Api.Storage.V1`. To use this module with Waffle, simply set
  your `:storage` config appropriately:

  ```elixir
  config :waffle, storage: Waffle.Storage.Google.CloudStorage
  ```

  Ensure you have a valid bucket set, either through the configs or as an
  environment variable, otherwise all calls will fail. The credentials available
  through `Goth` must have the appropriate level of access to the bucket,
  otherwise some (or all) calls may fail.
  """

  @full_control_scope "https://www.googleapis.com/auth/devstorage.full_control"

  alias GoogleApi.Storage.V1.Connection
  alias GoogleApi.Storage.V1.Api.Objects
  alias GoogleApi.Storage.V1.Model.Object
  alias Waffle.Storage.Google.Util
  alias Waffle.Types

  @type object_or_error :: {:ok, GoogleApi.Storage.V1.Model.Object.t} | {:error, Tesla.Env.t}

  @doc """
  Put a Waffle file in a Google Cloud Storage bucket.
  """
  @spec put(Types.definition, Types.version, Types.meta) :: object_or_error
  def put(definition, version, {_file, scope} = meta) do
    path = path_for(definition, version, meta)
    acl = definition.acl(version, meta)

    gcs_options =
      definition
      |> get_gcs_options(version, meta)
      |> ensure_keyword_list()
      |> Keyword.put(:acl, acl)
      |> Enum.into(%{})

    gcs_optional_params =
      definition
      |> get_gcs_optional_params(version, meta)
      |> ensure_keyword_list()

    insert(conn(scope), bucket(definition), path, data(meta), gcs_options, gcs_optional_params)
  end

  @doc """
  Delete a file from a Google Cloud Storage bucket.
  """
  @spec delete(Types.definition, Types.version, Types.meta) :: object_or_error
  def delete(definition, version, {_file, scope} = meta) do
    Objects.storage_objects_delete(
      conn(scope),
      bucket(definition),
      path_for(definition, version, meta) |> URI.encode_www_form()
    )
  end

  @doc """
  Retrieve the public URL for a file in a Google Cloud Storage bucket. Uses
  `Waffle.Storage.Google.UrlV2` by default, which uses v2 signing if a signed
  URL is requested, but this can be overriden in the options list or in the
  application configs by setting `:url_builder` to any module that imlements the
  behavior of `Waffle.Storage.Google.Url`.
  """
  @spec url(Types.definition, Types.version, Types.meta, Keyword.t) :: String.t
  def url(definition, version, meta, opts \\ []) do
    signer = Util.option(opts, :url_builder, Waffle.Storage.Google.UrlV2)
    signer.build(definition, version, meta, opts)
  end

  @doc """
  Constructs a new connection object with scoped authentication. If no scope is
  provided, the `devstorage.full_control` scope is used as a default.
  """
  @spec conn(String.t) :: Tesla.Env.client
  def conn(scope \\ @full_control_scope) do
    token_store = Application.get_env(:waffle, :token_fetcher, Waffle.Storage.Google.Token.DefaultFetcher)

    token_store.get_token(scope)
    |> Connection.new()
  end

  @doc """
  Returns the bucket for file uploads.
  """
  @spec bucket(Types.definition) :: String.t
  def bucket(definition), do: Util.var(definition.bucket())

  @doc """
  Returns the storage directory **within a bucket** to store the file under.
  """
  @spec storage_dir(Types.definition, Types.version, Types.meta) :: String.t
  def storage_dir(definition, version, meta) do
    version
    |> definition.storage_dir(meta)
    |> Util.var()
  end

  @doc """
  Returns the full file path for the upload destination.
  """
  @spec path_for(Types.definition, Types.version, Types.meta) :: String.t
  def path_for(definition, version, meta) do
    definition
    |> storage_dir(version, meta)
    |> Path.join(fullname(definition, version, meta))
  end

  @doc """
  A wrapper for `Waffle.Definition.Versioning.resolve_file_name/3`.
  """
  @spec fullname(Types.definition, Types.version, Types.meta) :: String.t
  def fullname(definition, version, meta) do
    Waffle.Definition.Versioning.resolve_file_name(definition, version, meta)
  end

  @spec data(Types.file) :: {:file | :binary, String.t}
  defp data({%{binary: nil, path: path}, _}), do: {:file, path}
  defp data({%{binary: data}, _}), do: {:binary, data}

  @spec insert(Tesla.Env.client, String.t, String.t, {:file | :binary, String.t}, map(), list()) :: object_or_error
  defp insert(conn, bucket, name, {:file, path}, gcs_options, gcs_optional_params) do
    object = %Object{name: name}
      |> Map.merge(gcs_options)

    Objects.storage_objects_insert_simple(
      conn,
      bucket,
      "multipart",
      object,
      path,
      gcs_optional_params
    )
  end
  defp insert(conn, bucket, name, {:binary, data}, gcs_options, gcs_optional_params) do
    object = %Object{name: name}
      |> Map.merge(gcs_options)

    Objects.storage_objects_insert_iodata(
      conn,
      bucket,
      "multipart",
      object,
      data,
      gcs_optional_params
    )
  end

  defp get_gcs_options(definition, version, {file, scope}) do
    try do
      apply(definition, :gcs_object_headers, [version, {file, scope}])
    rescue
      UndefinedFunctionError ->
        []
    end
  end

  defp get_gcs_optional_params(definition, version, {file, scope}) do
    try do
      apply(definition, :gcs_optional_params, [version, {file, scope}])
    rescue
      UndefinedFunctionError ->
        []
    end
  end

  defp ensure_keyword_list(list) when is_list(list), do: list
  defp ensure_keyword_list(map) when is_map(map), do: Map.to_list(map)
end
