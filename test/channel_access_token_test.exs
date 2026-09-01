# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.ChannelAccessTokenTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.ChannelAccessToken

  alias LINE.Bot.ChannelAccessToken
  alias LINE.Bot.ChannelAccessToken.Model.ChannelAccessTokenKeyIdsResponse
  alias LINE.Bot.ChannelAccessToken.Model.ErrorResponse
  alias LINE.Bot.ChannelAccessToken.Model.IssueChannelAccessTokenResponse
  alias LINE.Bot.ChannelAccessToken.Model.IssueShortLivedChannelAccessTokenResponse
  alias LINE.Bot.ChannelAccessToken.Model.IssueStatelessChannelAccessTokenResponse
  alias LINE.Bot.ChannelAccessToken.Model.VerifyChannelAccessTokenResponse

  describe "gets_all_valid_channel_access_token_key_ids/4" do
    test "sends GET request with snake_case query parameters", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/oauth2/v2.1/tokens/kid", fn conn ->
        params = URI.decode_query(conn.query_string)

        assert params["client_assertion_type"] ==
                 "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

        assert params["client_assertion"] == "my_jwt"
        refute Map.has_key?(params, "clientAssertionType")
        refute Map.has_key?(params, "clientAssertion")

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"kids": ["kid-1", "kid-2"]}))
      end)

      assert {:ok, %ChannelAccessTokenKeyIdsResponse{} = response} =
               ChannelAccessToken.gets_all_valid_channel_access_token_key_ids(
                 client,
                 "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                 "my_jwt"
               )

      assert response.kids == ["kid-1", "kid-2"]
    end
  end

  describe "issue_channel_token/5" do
    test "sends POST request with form encoded body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/oauth/accessToken", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert URI.decode_query(conn.req_body) == %{
                 "grant_type" => "client_credentials",
                 "client_id" => "1234",
                 "client_secret" => "test_secret"
               }

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"access_token": "test_token", "expires_in": 2592000, "token_type": "Bearer"})
        )
      end)

      assert {:ok, %IssueShortLivedChannelAccessTokenResponse{} = response} =
               ChannelAccessToken.issue_channel_token(
                 client,
                 "client_credentials",
                 "1234",
                 "test_secret"
               )

      assert response.access_token == "test_token"
      assert response.expires_in == 2_592_000
      assert response.token_type == "Bearer"
    end

    test "does not send an authorization header", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/oauth/accessToken", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == []

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, %IssueShortLivedChannelAccessTokenResponse{}} =
               ChannelAccessToken.issue_channel_token(
                 client,
                 "client_credentials",
                 "1234",
                 "test_secret"
               )
    end

    test "returns error response on 400", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/oauth/accessToken", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(400, ~s({"error": "invalid_request"}))
      end)

      assert {:ok, %ErrorResponse{} = response} =
               ChannelAccessToken.issue_channel_token(
                 client,
                 "client_credentials",
                 "1234",
                 "wrong_secret"
               )

      assert response.error == "invalid_request"
    end
  end

  describe "issue_channel_token_by_jwt/5" do
    test "sends POST request with JWT assertion form body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/oauth2/v2.1/token", fn conn ->
        assert URI.decode_query(conn.req_body) == %{
                 "grant_type" => "client_credentials",
                 "client_assertion_type" =>
                   "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                 "client_assertion" => "dummyClientAssertion"
               }

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"access_token": "test_token", "expires_in": 2592000, "token_type": "Bearer", "key_id": "key-id"})
        )
      end)

      assert {:ok, %IssueChannelAccessTokenResponse{} = response} =
               ChannelAccessToken.issue_channel_token_by_jwt(
                 client,
                 "client_credentials",
                 "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                 "dummyClientAssertion"
               )

      assert response.access_token == "test_token"
      assert response.key_id == "key-id"
    end
  end

  describe "issue_stateless_channel_token/3" do
    test "sends POST request with JWT assertion and omits nil optional parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "POST", "/oauth2/v3/token", fn conn ->
        params = URI.decode_query(conn.req_body)

        assert params["grant_type"] == "client_credentials"

        assert params["client_assertion_type"] ==
                 "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

        assert params["client_assertion"] == "dummyClientAssertion"
        refute Map.has_key?(params, "client_id")
        refute Map.has_key?(params, "client_secret")

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"access_token": "test_token", "expires_in": 900, "token_type": "Bearer"})
        )
      end)

      assert {:ok, %IssueStatelessChannelAccessTokenResponse{} = response} =
               ChannelAccessToken.issue_stateless_channel_token(client,
                 grant_type: "client_credentials",
                 client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                 client_assertion: "dummyClientAssertion"
               )

      assert response.access_token == "test_token"
      assert response.expires_in == 900
      assert response.token_type == "Bearer"
    end

    test "sends POST request with client secret and omits nil assertion parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "POST", "/oauth2/v3/token", fn conn ->
        params = URI.decode_query(conn.req_body)

        assert params["grant_type"] == "client_credentials"
        assert params["client_id"] == "1234"
        assert params["client_secret"] == "test_secret"
        refute Map.has_key?(params, "client_assertion_type")
        refute Map.has_key?(params, "client_assertion")

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"access_token": "test_token", "expires_in": 900, "token_type": "Bearer"})
        )
      end)

      assert {:ok, %IssueStatelessChannelAccessTokenResponse{} = response} =
               ChannelAccessToken.issue_stateless_channel_token(client,
                 grant_type: "client_credentials",
                 client_id: "1234",
                 client_secret: "test_secret"
               )

      assert response.access_token == "test_token"
    end
  end

  describe "revoke_channel_token/3" do
    test "sends POST request with access_token form parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/oauth/revoke", fn conn ->
        assert URI.decode_query(conn.req_body) == %{"access_token" => "my_token"}

        Passby.resp(conn, 200, "")
      end)

      assert {:ok, %Req.Response{}} = ChannelAccessToken.revoke_channel_token(client, "my_token")
    end
  end

  describe "revoke_channel_token_by_jwt/5" do
    test "sends POST request with client credentials and access token", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "POST", "/oauth2/v2.1/revoke", fn conn ->
        assert URI.decode_query(conn.req_body) == %{
                 "client_id" => "1234",
                 "client_secret" => "test_secret",
                 "access_token" => "my_token"
               }

        Passby.resp(conn, 200, "")
      end)

      assert {:ok, %Req.Response{}} =
               ChannelAccessToken.revoke_channel_token_by_jwt(
                 client,
                 "1234",
                 "test_secret",
                 "my_token"
               )
    end
  end

  describe "verify_channel_token/3" do
    test "sends POST request with access_token form parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/oauth/verify", fn conn ->
        assert URI.decode_query(conn.req_body) == %{"access_token" => "my_token"}

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"client_id": "1234", "expires_in": 2592000, "scope": "P"}))
      end)

      assert {:ok, %VerifyChannelAccessTokenResponse{} = response} =
               ChannelAccessToken.verify_channel_token(client, "my_token")

      assert response.client_id == "1234"
      assert response.expires_in == 2_592_000
      assert response.scope == "P"
    end
  end

  describe "verify_channel_token_by_jwt/3" do
    test "sends GET request with access_token query parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/oauth2/v2.1/verify", fn conn ->
        params = URI.decode_query(conn.query_string)

        assert params["access_token"] == "my_token"
        refute Map.has_key?(params, "accessToken")

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"client_id": "1234", "expires_in": 2592000, "scope": "P"}))
      end)

      assert {:ok, %VerifyChannelAccessTokenResponse{} = response} =
               ChannelAccessToken.verify_channel_token_by_jwt(client, "my_token")

      assert response.client_id == "1234"
    end
  end
end
