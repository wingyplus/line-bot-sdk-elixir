# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.LineModuleAttachTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.LineModuleAttach

  alias LINE.Bot.LineModuleAttach
  alias LINE.Bot.ModuleAttach.Model.AttachModuleResponse

  describe "attach_module/6" do
    test "sends POST request with snake_case form body and omits nil optional parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "POST", "/module/auth/v1/token", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        params = URI.decode_query(conn.req_body)

        assert params["grant_type"] == "authorization_code"
        assert params["code"] == "auth_code_value"
        assert params["redirect_uri"] == "https://example.com/cb"
        refute Map.has_key?(params, "code_verifier")
        refute Map.has_key?(params, "client_id")
        refute Map.has_key?(params, "client_secret")
        refute Map.has_key?(params, "region")
        refute Map.has_key?(params, "basic_search_id")
        refute Map.has_key?(params, "scope")
        refute Map.has_key?(params, "brand_type")

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"bot_id": "U1234567890", "scopes": ["message:send"]}))
      end)

      assert {:ok, %AttachModuleResponse{} = response} =
               LineModuleAttach.attach_module(
                 client,
                 "authorization_code",
                 "auth_code_value",
                 "https://example.com/cb"
               )

      assert response.bot_id == "U1234567890"
      assert response.scopes == ["message:send"]
    end

    test "sends optional parameters when provided", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/module/auth/v1/token", fn conn ->
        params = URI.decode_query(conn.req_body)

        assert params["code_verifier"] == "test_code_verifier"
        assert params["client_id"] == "1234"
        assert params["client_secret"] == "test_secret"
        assert params["region"] == "JP"
        assert params["basic_search_id"] == "@example"
        assert params["scope"] == "message:send"
        assert params["brand_type"] == "PREMIUM"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, %AttachModuleResponse{}} =
               LineModuleAttach.attach_module(
                 client,
                 "authorization_code",
                 "auth_code_value",
                 "https://example.com/cb",
                 code_verifier: "test_code_verifier",
                 client_id: "1234",
                 client_secret: "test_secret",
                 region: "JP",
                 basic_search_id: "@example",
                 scope: "message:send",
                 brand_type: "PREMIUM"
               )
    end
  end
end
