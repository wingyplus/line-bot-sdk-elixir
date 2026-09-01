# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.InsightTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.Insight

  alias LINE.Bot.Insight

  describe "get_friends_demographics/2" do
    test "sends GET request and returns demographics response", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/insight/demographic", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"available": true}))
      end)

      assert {:ok, %Insight.Model.GetFriendsDemographicsResponse{} = response} =
               Insight.get_friends_demographics(client)

      assert response.available == true
    end
  end

  describe "get_message_event/3" do
    test "sends GET request with requestId query parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/insight/message/event", fn conn ->
        assert conn.query_string =~ "requestId=test-request-id"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"overview": {}}))
      end)

      assert {:ok, %Insight.Model.GetMessageEventResponse{}} =
               Insight.get_message_event(client, "test-request-id")
    end
  end

  describe "get_number_of_followers/2" do
    test "sends GET request with date query parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/insight/followers", fn conn ->
        assert conn.query_string =~ "date=20231201"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"status": "ready", "followers": 1000}))
      end)

      assert {:ok, %Insight.Model.GetNumberOfFollowersResponse{} = response} =
               Insight.get_number_of_followers(client, date: "20231201")

      assert response.status == "ready"
      assert response.followers == 1000
    end
  end

  describe "get_number_of_message_deliveries/3" do
    test "sends GET request with date query parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/insight/message/delivery", fn conn ->
        assert conn.query_string =~ "date=20231201"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"status": "ready", "broadcast": 100}))
      end)

      assert {:ok, %Insight.Model.GetNumberOfMessageDeliveriesResponse{} = response} =
               Insight.get_number_of_message_deliveries(client, "20231201")

      assert response.status == "ready"
      assert response.broadcast == 100
    end
  end

  describe "get_statistics_per_unit/5" do
    test "sends GET request with customAggregationUnit, from, and to query parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/insight/message/event/aggregation", fn conn ->
        assert conn.query_string =~ "customAggregationUnit=promotion_a"
        assert conn.query_string =~ "from=20231201"
        assert conn.query_string =~ "to=20231231"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"overview": {}}))
      end)

      assert {:ok, %Insight.Model.GetStatisticsPerUnitResponse{}} =
               Insight.get_statistics_per_unit(client, "promotion_a", "20231201", "20231231")
    end
  end
end
