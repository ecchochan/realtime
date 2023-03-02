defmodule RealtimeWeb.ChannelsAuthorizationTest do
  use ExUnit.Case

  import Mock

  alias RealtimeWeb.{ChannelsAuthorization, JwtVerification}

  @secret ""
  @signing_method "HS256"
  @pubkey ""

  test "authorize/1 when token is authorized" do
    input_token = "\n token %20 1 %20 2 %20 3   "
    expected_token = "token123"

    with_mock JwtVerification,
      verify: fn token, @secret, @signing_method, @pubkey ->
        assert token == expected_token
        {:ok, %{}}
      end do
      assert {:ok, %{}} =
               ChannelsAuthorization.authorize(input_token, @secret, @signing_method, @pubkey)
    end
  end

  test "authorize/1 when token is unauthorized" do
    with_mock JwtVerification, verify: fn _token, _secret, _signing_method, _pubkey -> :error end do
      assert :error =
               ChannelsAuthorization.authorize("bad_token", @secret, @signing_method, @pubkey)
    end
  end

  test "authorize/1 when token is not a string" do
    assert :error = ChannelsAuthorization.authorize([], @secret, @signing_method, @pubkey)
  end
end
