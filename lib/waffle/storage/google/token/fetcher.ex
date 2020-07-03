defmodule Waffle.Storage.Google.Token.Fetcher do
  @callback get_token(binary) :: binary
end
