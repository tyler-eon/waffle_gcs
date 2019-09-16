defmodule Waffle.Storage.Google.Url do
  @moduledoc """
  Defines an interface for generating Google Cloud Storage URLs.
  """

  alias Waffle.Types

  @doc """
  Constructs a URL based on data from Waffle.
  """
  @callback build(
    definition :: Types.definition,
    version :: Types.version,
    meta :: Types.meta,
    options :: Keyword.t
  ) :: String.t

  defmacro __using__(_) do
    quote do
      @behaviour Waffle.Storage.Google.Url
      @before_compile Waffle.Storage.Google.Url
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @doc """
      Same as `build(definition, version, meta, [])`.
      """
      @spec build(Types.definition, Types.version, Types.meta) :: String.t
      def build(definition, version, meta), do: build(definition, version, meta, [])
    end
  end
end
