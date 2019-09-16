defmodule Waffle.Storage.Google.UrlV2Test do
  use ExUnit.Case, async: true

  alias Waffle.Storage.Google.UrlV2

  describe "expiry/1" do
    test "returns a default value when option is not found" do
      assert 3600 == UrlV2.expiry()
    end

    test "uses value from keyword list" do
      assert 100 == UrlV2.expiry(expires_in: 100)
    end

    test "respects minimum and maximum values" do
      assert 1 == UrlV2.expiry(expires_in: -100)
      assert 604800 == UrlV2.expiry(expires_in: 9999999999)
    end
  end

  describe "signed?/1" do
    test "returns the option value when found" do
      assert UrlV2.signed?(signed: true)
    end

    test "returns false as the default" do
      assert false == UrlV2.signed?()
    end
  end

  describe "endpoint/1" do
    test "returns the option value when provided" do
      assert "test.com" == UrlV2.endpoint(asset_host: "test.com")
    end

    test "returns the application config as a back-up" do
      Application.put_env(:waffle, :asset_host, "test.com")
      result = UrlV2.endpoint()
      Application.delete_env(:waffle, :asset_host)

      assert "test.com" == result
    end

    test "returns default endpoint" do
      assert "storage.googleapis.com" == UrlV2.endpoint()
    end
  end
end
