defmodule Waffle.Storage.Google.Util do
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
  For some reason, the Elixir library for Google Cloud Storage **DOES NOT**
  support binary data uploads. Their code always assumes that a path to a file
  is being passed to it and constructs the request as such. More infuriating is
  that Tesla, the HTTP library being used to make these requests, converts file
  paths to binary streams anyway, so adding the data to a temporary file would
  add additional steps. Specifically, we'd be doing the following:

  1. Receive binary data (maybe from a stream).
  2. Write the binary data to a temporary file.
  3. Tesla opens the temporary file as a stream.
  4. The request is made.
  5. Delete the temporary file.

  Internally, Google relies solely on `Tesla.Multipart.add_file/3` which creates
  a stream from the given filepath and then calls
  `Tesla.Multipart.add_file_content/3`. I have bypassed this step by creating a
  multipart struct manually, adding the binary data with `add_file_content`, and
  setting it to the request body. Fun fact: if you have no `file` param and your
  `body` param has a single entry of `{:body, _}`, the Google connection will
  use whatever the value is verbatim. We take advantage of that weird fact to
  bypass their custom `build_body` logic.
  """
  @spec storage_objects_insert_binary(
    Tesla.Env.client,
    String.t,
    Object.t,
    String.t
  ) :: Waffle.Storage.Google.CloudStorage.object_or_error
  def storage_objects_insert_binary(connection, bucket, metadata, bin) do
      request = Request.new()
      |> Request.method(:post)
      |> Request.url("/upload/storage/v1/b/{bucket}/o", %{
        "bucket" => URI.encode(bucket, &URI.char_unreserved?/1)
      })
      |> Request.add_param(:query, :uploadType, "multipart")
      |> Request.add_param(:body, :body, build_binary_body(metadata, bin))
      |> Request.library_version(@library_version)

      connection
      |> Connection.execute(request)
      |> Response.decode([struct: %Object{}])
  end

  @doc """
  Builds a `Tesla.Multipart` structure containing two parts: a binary payload
  and metadata about the binary payload. The `metadata` argument must be JSON
  encodable, i.e. it must succeed when passed to `Poison.encode!/1`.
  """
  @spec build_binary_body(Object.t, String.t) :: Tesla.Multipart.t
  def build_binary_body(metadata, bin) do
      Tesla.Multipart.new()
      |> Tesla.Multipart.add_field(
        :metadata,
        Poison.encode!(metadata),
        headers: [{:"Content-Type", "application/json"}]
      )
      |> Tesla.Multipart.add_file_content(bin, :data)
  end
end
