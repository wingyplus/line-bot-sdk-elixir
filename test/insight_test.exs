defmodule LINEBotSDK.InsightTest do
  use ExUnit.Case, async: true

  alias LINEBotSDK.Insight

  setup do
    bypass = Bypass.open()
    client = Req.new(base_url: "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass, client: client}
  end

  describe "get_friends_demographics/2" do
    test "sends GET request and returns demographics response", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/insight/demographic", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"available": true}))
      end)

      assert {:ok, response} = Insight.get_friends_demographics(client)
      assert response.available == true
    end
  end

  describe "get_message_event/3" do
    test "sends GET request with requestId query parameter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/insight/message/event", fn conn ->
        assert conn.query_string =~ "requestId=test-request-id"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"overview": {}}))
      end)

      assert {:ok, _response} = Insight.get_message_event(client, "test-request-id")
    end
  end

  describe "get_number_of_followers/2" do
    test "sends GET request with date query parameter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/insight/followers", fn conn ->
        assert conn.query_string =~ "date=20231201"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"status": "ready", "followers": 1000}))
      end)

      assert {:ok, response} = Insight.get_number_of_followers(client, date: "20231201")
      assert response.status == "ready"
      assert response.followers == 1000
    end
  end

  describe "get_number_of_message_deliveries/3" do
    test "sends GET request with date query parameter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/v2/bot/insight/message/delivery", fn conn ->
        assert conn.query_string =~ "date=20231201"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"status": "ready", "broadcast": 100}))
      end)

      assert {:ok, response} = Insight.get_number_of_message_deliveries(client, "20231201")
      assert response.status == "ready"
      assert response.broadcast == 100
    end
  end

  describe "get_statistics_per_unit/5" do
    test "sends GET request with customAggregationUnit, from, and to query parameters", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect_once(bypass, "GET", "/v2/bot/insight/message/event/aggregation", fn conn ->
        assert conn.query_string =~ "customAggregationUnit=promotion_a"
        assert conn.query_string =~ "from=20231201"
        assert conn.query_string =~ "to=20231231"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"overview": {}}))
      end)

      assert {:ok, _response} =
               Insight.get_statistics_per_unit(client, "promotion_a", "20231201", "20231231")
    end
  end
end
