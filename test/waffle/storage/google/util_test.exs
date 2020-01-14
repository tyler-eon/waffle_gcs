defmodule Waffle.Storage.Google.UtilTest do
  use ExUnit.Case, async: true

  alias Waffle.Storage.Google.{CloudStorage, Util}

  @app_key :_test
  @app_test "app env test"

  setup_all do
    Application.put_env(:waffle, @app_key, @app_test)
  end

  describe "var/1" do
    test "returns a system variable" do
      key = "WAFFLE_BUCKET"
      new = "test-bucket"
      prev = System.get_env(key)
      System.put_env(key, new)
      value = Util.var({:system, key})
      System.put_env(key, prev)
      assert new == value
    end

    test "returns an application variable with default app" do
      assert @app_test == Util.var({:app, @app_key})
    end

    test "returns an application variable for a specified app" do
      Application.put_env(:goth, @app_key, @app_test)
      assert @app_test == Util.var({:app, :goth, @app_key})
    end

    test "returns anything you give it on the catch-all" do
      assert 12345 == Util.var(12345)
      assert "hey" == Util.var("hey")
      assert :test == Util.var(:test)
    end
  end

  describe "option/3" do
    setup do
      %{opts: [one: 1, two: 2]}
    end

    test "returns value from keyword list", %{opts: opts} do
      assert 2 == Util.option(opts, :two)
    end

    test "returns value from application environment", %{opts: opts} do
      assert @app_test == Util.option(opts, @app_key)
    end

    test "returns nil if no default is given and no value is found" do
      assert nil == Util.option([], :one)
    end

    test "return a custom default value" do
      assert "test" == Util.option([], :one, "test")
      assert :test == Util.option([], :one, :test)
    end
  end

  describe "prepend_slash/1" do
    test "prepends a forward slash to a string" do
      assert "/test/path" == Util.prepend_slash("test/path")
    end

    test "does nothing if a string starts with a forward slash" do
      assert "/test/path" == Util.prepend_slash("/test/path")
    end
  end

  describe "storage_objects_insert/4" do
    test "uploads raw binary data to a Google Cloud Storage bucket" do
      conn = CloudStorage.conn()
      bucket = CloudStorage.bucket(DummyDefinition)
      name = "test.txt"
      bin  = "this is a test"
      assert {:ok, _} = Util.storage_objects_insert(
        conn,
        bucket,
        "multipart",
        %GoogleApi.Storage.V1.Model.Object{name: name},
        bin
      )
      assert {:ok, _} = GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
        conn,
        bucket,
        name
      )
    end
  end
end
