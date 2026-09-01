# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.LineModuleTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.LineModule

  alias LINE.Bot.LineModule
  alias LINE.Bot.Module.Model.AcquireChatControlRequest
  alias LINE.Bot.Module.Model.DetachModuleRequest

  describe "acquire_chat_control/3" do
    test "sends POST request with chat_id path parameter and JSON body", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "POST", "/v2/bot/chat/test-chat-id/control/acquire", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      request = %AcquireChatControlRequest{expired: false}

      assert {:ok, _response} =
               LineModule.acquire_chat_control(client, "test-chat-id", body: request)
    end
  end

  describe "detach_module/2" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/channel/detach", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      request = %DetachModuleRequest{botId: "test-bot-id"}

      assert {:ok, _response} = LineModule.detach_module(client, body: request)
    end
  end

  describe "get_modules/2" do
    test "sends GET request and returns list of modules", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/list", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"bots": []}))
      end)

      assert {:ok, response} = LineModule.get_modules(client)
      assert response.bots == []
    end

    test "sends GET request with start and limit query parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/list", fn conn ->
        assert conn.query_string =~ "start=abc"
        assert conn.query_string =~ "limit=10"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"bots": []}))
      end)

      assert {:ok, _response} = LineModule.get_modules(client, start: "abc", limit: 10)
    end
  end

  describe "release_chat_control/3" do
    test "sends POST request with chat_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/chat/test-chat-id/control/release", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, _response} = LineModule.release_chat_control(client, "test-chat-id")
    end
  end
end
