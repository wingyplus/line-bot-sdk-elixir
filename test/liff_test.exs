# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.LiffTest do
  use ExUnit.Case, async: true

  alias LINE.Bot.Liff
  alias LINE.Bot.Liff.Model.AddLiffAppRequest
  alias LINE.Bot.Liff.Model.UpdateLiffAppRequest
  alias LINE.Bot.Liff.Model.LiffView
  alias LINE.Bot.Liff.Model.UpdateLiffView

  setup do
    bypass = Bypass.open()
    client = Req.new(base_url: "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass, client: client}
  end

  describe "add_liff_app/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/liff/v1/apps", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"liffId": "1234567890-abcdefgh"}))
      end)

      request = %AddLiffAppRequest{
        view: %LiffView{type: "full", url: "https://example.com"}
      }

      assert {:ok, response} = Liff.add_liff_app(client, request)
      assert response.liffId == "1234567890-abcdefgh"
    end
  end

  describe "delete_liff_app/3" do
    test "sends DELETE request with liff_id path parameter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/liff/v1/apps/test-liff-id", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "{}")
      end)

      assert {:ok, _response} = Liff.delete_liff_app(client, "test-liff-id")
    end
  end

  describe "get_all_liff_apps/2" do
    test "sends GET request and returns list of LIFF apps", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/liff/v1/apps", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"apps": []}))
      end)

      assert {:ok, response} = Liff.get_all_liff_apps(client)
      assert response.apps == []
    end
  end

  describe "update_liff_app/4" do
    test "sends PUT request with liff_id path parameter and JSON body", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect_once(bypass, "PUT", "/liff/v1/apps/test-liff-id", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "{}")
      end)

      request = %UpdateLiffAppRequest{
        view: %UpdateLiffView{url: "https://example.com/updated"}
      }

      assert {:ok, _response} = Liff.update_liff_app(client, "test-liff-id", request)
    end
  end
end
