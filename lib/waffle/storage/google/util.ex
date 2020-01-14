defmodule Waffle.Storage.Google.Util do
  @moduledoc """
  A collection of utility functions.
  """

  alias GoogleApi.Gax.{Request, Response}
  alias GoogleApi.Storage.V1.Connection
  alias GoogleApi.Storage.V1.Model.Object

  @library_version Mix.Project.config() |> Keyword.get(:version, "")

  @doc """
  Accepts four forms of variables:

  1. The tuple `{:system, key}`, which uses `System.get_env/1`.
  2. The tuple `{:app, key}`, which uses `Application.get_env/2`.
  3. The tuple `{:app, app, key}`, which usees `Application.get_env/2`.
  4. Anything else which is returned as-is.

  In the second form (`{:app, key}`), the application is assumed to be `:waffle`
  although this can be overriden using the third form (`{:app, app, key}`).
  """
  @spec var(any) :: any
  def var({:system, key}), do: System.get_env(key)
  def var({:app, app, key}), do: Application.get_env(app, key)
  def var({:app, key}), do: var({:app, :waffle, key})
  def var(value), do: value

  @doc """
  Attempts to return a value from a given options list, using the application
  configs as a back-up. The application (used in `Application.get_env/3`) is
  assumed to be `:waffle`.

  This assumes that the application environment is set using `waffle` as the
  application name.

  If the value is not found in any of those location, an optional default value
  can be returned.
  """
  @spec option(Keyword.t, any, any) :: any
  def option(opts, key, default \\ nil) do
    case Keyword.get(opts, key) do
      nil -> Application.get_env(:waffle, key, default)
      val -> val
    end
  end

  @doc """
  If the given string does not already start with a forward slash, this function
  will prepend one and return the result.

  ## Examples

      > prepend_slash("some/path")
      "/some/path"

      > prepend_slash("/im/good")
      "/im/good"
  """
  @spec prepend_slash(String.t) :: String.t
  def prepend_slash("/" <> _rest = path), do: path
  def prepend_slash(path), do: "/#{path}"



  @doc """
  Stores a new object and metadata.

  ## Parameters

  *   `connection` (*type:* `GoogleApi.Storage.V1.Connection.t`) - Connection to server
  *   `bucket` (*type:* `String.t`) - Name of the bucket in which to store the new object. Overrides the provided object metadata's bucket value, if any.
  *   `upload_type` (*type:* `String.t`) - Upload type. Must be "multipart".
  *   `metadata` (*type:* `GoogleApi.Storage.V1.Model.Object.t`) - object metadata
  *   `data` (*type:* `iodata`) - Content to upload, as a string or iolist
  *   `optional_params` (*type:* `keyword()`) - Optional parameters
      *   `:alt` (*type:* `String.t`) - Data format for the response.
      *   `:fields` (*type:* `String.t`) - Selector specifying which fields to include in a partial response.
      *   `:key` (*type:* `String.t`) - API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
      *   `:oauth_token` (*type:* `String.t`) - OAuth 2.0 token for the current user.
      *   `:prettyPrint` (*type:* `boolean()`) - Returns response with indentations and line breaks.
      *   `:quotaUser` (*type:* `String.t`) - An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
      *   `:userIp` (*type:* `String.t`) - Deprecated. Please use quotaUser instead.
      *   `:contentEncoding` (*type:* `String.t`) - If set, sets the contentEncoding property of the final object to this value. Setting this parameter is equivalent to setting the contentEncoding metadata property. This can be useful when uploading an object with uploadType=media to indicate the encoding of the content being uploaded.
      *   `:ifGenerationMatch` (*type:* `String.t`) - Makes the operation conditional on whether the object's current generation matches the given value. Setting to 0 makes the operation succeed only if there are no live versions of the object.
      *   `:ifGenerationNotMatch` (*type:* `String.t`) - Makes the operation conditional on whether the object's current generation does not match the given value. If no live object exists, the precondition fails. Setting to 0 makes the operation succeed only if there is a live version of the object.
      *   `:ifMetagenerationMatch` (*type:* `String.t`) - Makes the operation conditional on whether the object's current metageneration matches the given value.
      *   `:ifMetagenerationNotMatch` (*type:* `String.t`) - Makes the operation conditional on whether the object's current metageneration does not match the given value.
      *   `:kmsKeyName` (*type:* `String.t`) - Resource name of the Cloud KMS key, of the form projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key, that will be used to encrypt the object. Overrides the object metadata's kms_key_name value, if any.
      *   `:name` (*type:* `String.t`) - Name of the object. Required when the object metadata is not otherwise provided. Overrides the object metadata's name value, if any. For information about how to URL encode object names to be path safe, see Encoding URI Path Parts.
      *   `:predefinedAcl` (*type:* `String.t`) - Apply a predefined set of access controls to this object.
      *   `:projection` (*type:* `String.t`) - Set of properties to return. Defaults to noAcl, unless the object resource specifies the acl property, when it defaults to full.
      *   `:provisionalUserProject` (*type:* `String.t`) - The project to be billed for this request if the target bucket is requester-pays bucket.
      *   `:userProject` (*type:* `String.t`) - The project to be billed for this request. Required for Requester Pays buckets.
  *   `opts` (*type:* `keyword()`) - Call options

  ## Returns

  *   `{:ok, %GoogleApi.Storage.V1.Model.Object{}}` on success
  *   `{:error, info}` on failure
  """
  @spec storage_objects_insert(
          Tesla.Env.client(),
          String.t(),
          String.t(),
          GoogleApi.Storage.V1.Model.Object.t(),
          iodata,
          keyword(),
          keyword()
        ) :: {:ok, GoogleApi.Storage.V1.Model.Object.t()} | {:error, Tesla.Env.t()}
  def storage_objects_insert(
        connection,
        bucket,
        upload_type,
        %{name: name},
        data,
        optional_params \\ [],
        opts \\ []
      ) do
    optional_params_config = %{
      :alt => :query,
      :fields => :query,
      :key => :query,
      :oauth_token => :query,
      :prettyPrint => :query,
      :quotaUser => :query,
      :userIp => :query,
      :contentEncoding => :query,
      :ifGenerationMatch => :query,
      :ifGenerationNotMatch => :query,
      :ifMetagenerationMatch => :query,
      :ifMetagenerationNotMatch => :query,
      :kmsKeyName => :query,
      :name => :query,
      :predefinedAcl => :query,
      :projection => :query,
      :provisionalUserProject => :query,
      :userProject => :query
    }

    request =
      Request.new()
      |> Request.method(:post)
      |> Request.url("/upload/storage/v1/b/{bucket}/o", %{
        "bucket" => URI.encode(bucket, &URI.char_unreserved?/1)
      })
      |> Request.add_param(:query, :name, name)
      |> Request.add_param(:body, :body, data)
      |> Request.add_optional_params(optional_params_config, optional_params)
      |> Request.library_version(@library_version)

    connection
    |> Connection.execute(request)
    |> Response.decode(opts ++ [struct: %GoogleApi.Storage.V1.Model.Object{}])
  end
end
