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
end
