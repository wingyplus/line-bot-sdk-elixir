defmodule LINEBotSDK.MessagingApiTest do
  use ExUnit.Case, async: true

  alias LINEBotSDK.MessagingApi
  alias LINEBotSDK.MessagingApi.Model.PushMessageRequest
  alias LINEBotSDK.MessagingApi.Model.BroadcastRequest
  alias LINEBotSDK.MessagingApi.Model.ReplyMessageRequest
  alias LINEBotSDK.MessagingApi.Model.TextMessage

  setup do
    bypass = Bypass.open()
    client = Req.new(base_url: "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass, client: client}
  end

  describe "push_message/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/v2/bot/message/push", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"sentMessages": []}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      assert {:ok, response} = MessagingApi.push_message(client, request)
      assert response.sentMessages == []
    end

    test "sends request with x-line-retry-key header when provided", %{
      bypass: bypass,
      client: client
    } do
      retry_key = "123e4567-e89b-12d3-a456-426614174000"

      Bypass.expect_once(bypass, "POST", "/v2/bot/message/push", fn conn ->
        assert Plug.Conn.get_req_header(conn, "x-line-retry-key") == [retry_key]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"sentMessages": []}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      assert {:ok, _response} =
               MessagingApi.push_message(client, request, x_line_retry_key: retry_key)
    end
  end

  describe "get_followers/2" do
    test "sends GET request with start and limit query parameters", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect_once(bypass, "GET", "/v2/bot/followers/ids", fn conn ->
        assert conn.query_string =~ "start=some-start"
        assert conn.query_string =~ "limit=1000"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"userIds": [], "next": "abcdef"}))
      end)

      assert {:ok, response} =
               MessagingApi.get_followers(client, start: "some-start", limit: 1000)

      assert response.userIds == []
      assert response.next == "abcdef"
    end
  end

  describe "get_group_members_ids/3" do
    test "sends GET request with group_id path parameter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/group/test-group-id/members/ids", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"memberIds": ["member1", "member2"], "next": "abcdef"}))
      end)

      assert {:ok, response} = MessagingApi.get_group_members_ids(client, "test-group-id")
      assert response.memberIds == ["member1", "member2"]
      assert response.next == "abcdef"
    end

    test "sends GET request with start query parameter when provided", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect_once(bypass, "GET", "/v2/bot/group/test-group-id/members/ids", fn conn ->
        assert conn.query_string =~ "start=token123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"memberIds": [], "next": null}))
      end)

      assert {:ok, _response} =
               MessagingApi.get_group_members_ids(client, "test-group-id", start: "token123")
    end

    test "sends GET request without start query parameter when not provided", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect_once(bypass, "GET", "/v2/bot/group/test-group-id/members/ids", fn conn ->
        refute conn.query_string =~ "start="

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"memberIds": []}))
      end)

      assert {:ok, _response} = MessagingApi.get_group_members_ids(client, "test-group-id")
    end
  end

  describe "get_bot_info/2" do
    test "sends GET request and returns bot info", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/info", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          ~s({"userId": "U12345", "basicId": "@bot", "displayName": "Test Bot"})
        )
      end)

      assert {:ok, response} = MessagingApi.get_bot_info(client)
      assert response.userId == "U12345"
      assert response.basicId == "@bot"
      assert response.displayName == "Test Bot"
    end
  end

  describe "get_profile/3" do
    test "sends GET request with user_id path parameter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/profile/U12345", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"userId": "U12345", "displayName": "Test User"}))
      end)

      assert {:ok, response} = MessagingApi.get_profile(client, "U12345")
      assert response.userId == "U12345"
      assert response.displayName == "Test User"
    end
  end

  describe "broadcast/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/v2/bot/message/broadcast", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "{}")
      end)

      request = %BroadcastRequest{
        messages: [%TextMessage{type: "text", text: "Hello, everyone!"}]
      }

      assert {:ok, _response} = MessagingApi.broadcast(client, request)
    end
  end

  describe "reply_message/3" do
    test "sends POST request with replyToken and messages", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/v2/bot/message/reply", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"sentMessages": []}))
      end)

      request = %ReplyMessageRequest{
        replyToken: "test-reply-token",
        messages: [%TextMessage{type: "text", text: "Thanks for your message!"}]
      }

      assert {:ok, response} = MessagingApi.reply_message(client, request)
      assert response.sentMessages == []
    end
  end

  describe "calling API twice" do
    test "can call the same API endpoint twice with the same client", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect(bypass, "POST", "/v2/bot/message/push", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"sentMessages": []}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      # First call
      assert {:ok, _response} = MessagingApi.push_message(client, request)

      # Second call with the same client
      assert {:ok, _response} = MessagingApi.push_message(client, request)
    end
  end
end
