defmodule Waffle.Types do
  @moduledoc """
  This is hack until Waffle declares formal typespecs in its own project.
  """

  @type definition :: Module.t
  @type version :: Atom.t | String.t
  @type file :: %Waffle.File{}
  @type meta :: {file, any}
end
