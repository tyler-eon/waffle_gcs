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
  The function `Objects.storage_objects_insert/4` has the wrong URL and will
  always fail to perform an upload. Because these clients are automatically
  generated, there needs to be an investigation as to why this URL is being
  incorrectly set before a solution can be applied. This version of the function
  is an exact copy/paste of the official function except that it uses the
  correct upload URL.
  """
  @spec storage_objects_insert(
    Tesla.Env.client,
    String.t,
    Keyword.t,
    Keyword.t
  ) :: Waffle.Storage.Google.CloudStorage.object_or_error
  def storage_objects_insert(connection, bucket, optional_params \\ [], opts \\ []) do
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
      :userProject => :query,
      :body => :body
    }

    request =
      Request.new()
      |> Request.method(:post)
      |> Request.url("/upload/storage/v1/b/{bucket}/o", %{
        "bucket" => URI.encode(bucket, &URI.char_unreserved?/1)
      })
      |> Request.add_optional_params(optional_params_config, optional_params)
      |> Request.library_version(@library_version)

    connection
    |> Connection.execute(request)
    |> Response.decode(opts ++ [struct: %Object{}])
  end
end
