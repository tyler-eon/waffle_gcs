ExUnit.start()

# The `after_suite/1` function was added in Elixir version 1.8.0
unless Version.compare(System.version(), "1.8.0") == :lt do
  ExUnit.after_suite(&Cleanup.execute/1)
end
