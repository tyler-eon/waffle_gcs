defmodule Waffle.Storage.Google.CloudStorageTest do
  use ExUnit.Case, async: true

  alias Waffle.Storage.Google.CloudStorage

  @file_name "image.png"
  @file_path "test/support/#{@file_name}"
  @remote_dir "arc-test"

  def env_bucket(), do: System.get_env("WAFFLE_BUCKET")

  def random_name(_) do
    name = 8 |> :crypto.strong_rand_bytes() |> Base.encode16() |> Kernel.<>(".png")
    %{name: name, path: "#{@remote_dir}/#{name}"}
  end

  def create_wafile(_), do: %{wafile: Waffle.File.new(@file_path)}

  def setup_waffle(%{wafile: file, name: name}) do
    %{
      definition: DummyDefinition,
      version: :original,
      meta: {file, name},
    }
  end

  describe "conn/1" do
    test "constructs a Tesla client" do
      assert %Tesla.Client{} = CloudStorage.conn()
    end

    test "constructs a Tesla client with a custom scope" do
      assert %Tesla.Client{} = CloudStorage.conn("https://www.googleapis.com/auth/devstorage.read_only")
    end
  end

  describe "utility functions" do
    setup [:random_name, :create_wafile, :setup_waffle]

    test "bucket/1 returns a bucket name based on a Waffle definition", %{definition: def} do
      assert env_bucket() == CloudStorage.bucket(def)
      assert "invalid" == CloudStorage.bucket(DummyDefinitionInvalidBucket)
    end

    test "storage_dir/3 returns the remote storage directory (not the bucket)", %{definition: def, version: ver, meta: meta} do
      assert @remote_dir == CloudStorage.storage_dir(def, ver, meta)
    end

    test "path_for/3 returns the file full path (storage directory plus filename)", %{definition: def, version: ver, meta: meta, name: name} do
      assert "#{@remote_dir}/#{name}" == CloudStorage.path_for(def, ver, meta)
    end
  end

  describe "waffle functions" do
    setup [:random_name, :create_wafile, :setup_waffle]

    test "put/3 uploads a valid file", %{definition: def, version: ver, meta: meta} do
      assert {:ok, _} = CloudStorage.put(def, ver, meta)
    end

    test "put/3 uploads binary data", %{definition: def, version: ver, name: name} do
      assert {:ok, _} = CloudStorage.put(def, ver, {%Waffle.File{binary: File.read!(@file_path)}, name})
    end

    test "put/3 fails for an invalid file", %{version: ver, meta: meta} do
      assert {:error, _} = CloudStorage.put(DummyDefinitionInvalidBucket, ver, meta)
    end

    test "delete/3 successfully deletes existing object", %{definition: def, version: ver, meta: meta} do
      assert {:ok, _} = CloudStorage.put(def, ver, meta)
      assert {:ok, _} = CloudStorage.delete(def, ver, meta)
    end

    test "delete/3 fails for invalid bucket or object", %{definition: def, version: ver, meta: meta} do
      assert {:error, _} = CloudStorage.delete(def, ver, meta)
      assert {:error, _} = CloudStorage.delete(DummyDefinitionInvalidBucket, ver, meta)
    end

    test "url/3 returns regular URLs", %{definition: def, version: ver, meta: meta, name: name} do
      assert CloudStorage.url(def, ver, meta) =~ "/#{env_bucket()}/#{@remote_dir}/#{name}"
    end

    test "url/3 returns signed URLs (v2)", %{definition: def, version: ver, meta: meta} do
      assert CloudStorage.url(def, ver, meta, [signed_urls: true]) =~ "&Signature="
    end
  end
end
