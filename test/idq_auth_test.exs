defmodule IdqAuthTest do
  use ExUnit.Case, async: true

  test "exits if configuration variales are missing" do
    Application.delete_env(:idq_auth, :callback_url)
    assert_raise RuntimeError, "idQ Auth Plug is missing configuration variables, please check your logs", fn ->
      IdqAuth.start(nil, nil)
    end
  end
end
