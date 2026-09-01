# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.ManageAudienceTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.ManageAudience

  alias LINE.Bot.ManageAudience
  alias LINE.Bot.ManageAudience.Model.Audience
  alias LINE.Bot.ManageAudience.Model.CreateAudienceGroupRequest
  alias LINE.Bot.ManageAudience.Model.CreateAudienceGroupResponse
  alias LINE.Bot.ManageAudience.Model.GetAudienceDataResponse
  alias LINE.Bot.ManageAudience.Model.GetAudienceGroupsResponse
  alias LINE.Bot.ManageAudience.Model.GetSharedAudienceDataResponse
  alias LINE.Bot.ManageAudience.Model.GetSharedAudienceGroupsResponse
  alias LINE.Bot.ManageAudience.Model.UpdateAudienceGroupDescriptionRequest

  describe "create_audience_group/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/audienceGroup/upload", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          202,
          ~s({"audienceGroupId": 1234567890123, "type": "UPLOAD", "description": "test_audience"})
        )
      end)

      request = %CreateAudienceGroupRequest{
        description: "test_audience",
        isIfaAudience: false,
        audiences: [%Audience{id: "U4af4980629..."}]
      }

      assert {:ok, %CreateAudienceGroupResponse{} = response} =
               ManageAudience.create_audience_group(client, request)

      assert response.audienceGroupId == 1_234_567_890_123
      assert response.type == "UPLOAD"
      assert response.description == "test_audience"
    end
  end

  describe "delete_audience_group/3" do
    test "builds path from numeric audience_group_id", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "DELETE", "/v2/bot/audienceGroup/0", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, %Req.Response{}} = ManageAudience.delete_audience_group(client, 0)
    end
  end

  describe "get_audience_data/3" do
    test "builds path from numeric audience_group_id", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/audienceGroup/1234567890123", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"audienceGroup": {"audienceGroupId": 1234567890123, "description": "test"}})
        )
      end)

      assert {:ok, %GetAudienceDataResponse{} = response} =
               ManageAudience.get_audience_data(client, 1_234_567_890_123)

      assert response.audienceGroup.audienceGroupId == 1_234_567_890_123
    end
  end

  describe "get_audience_groups/4" do
    test "sends GET request with page and optional query parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/audienceGroup/list", fn conn ->
        params = URI.decode_query(conn.query_string)

        assert params["page"] == "1"
        assert params["description"] == "test"
        assert params["status"] == "READY"
        assert params["size"] == "40"
        assert params["includesExternalPublicGroups"] == "false"
        assert params["createRoute"] == "MESSAGING_API"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"audienceGroups": [], "hasNextPage": false, "totalCount": 0, "page": 1, "size": 40})
        )
      end)

      assert {:ok, %GetAudienceGroupsResponse{} = response} =
               ManageAudience.get_audience_groups(client, 1,
                 description: "test",
                 status: "READY",
                 size: 40,
                 includes_external_public_groups: false,
                 create_route: "MESSAGING_API"
               )

      assert response.audienceGroups == []
      assert response.hasNextPage == false
      assert response.page == 1
    end

    test "omits optional query parameters when not provided", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/audienceGroup/list", fn conn ->
        params = URI.decode_query(conn.query_string)

        assert params["page"] == "1"
        refute Map.has_key?(params, "description")
        refute Map.has_key?(params, "status")
        refute Map.has_key?(params, "size")
        refute Map.has_key?(params, "includesExternalPublicGroups")
        refute Map.has_key?(params, "createRoute")

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"audienceGroups": []}))
      end)

      assert {:ok, %GetAudienceGroupsResponse{}} = ManageAudience.get_audience_groups(client, 1)
    end
  end

  describe "get_shared_audience_data/3" do
    test "builds path from numeric audience_group_id", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/audienceGroup/shared/12345", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, %GetSharedAudienceDataResponse{}} =
               ManageAudience.get_shared_audience_data(client, 12345)
    end
  end

  describe "get_shared_audience_groups/4" do
    test "sends GET request with page query parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/audienceGroup/shared/list", fn conn ->
        assert conn.query_string =~ "page=1"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"audienceGroups": [], "hasNextPage": false}))
      end)

      assert {:ok, %GetSharedAudienceGroupsResponse{} = response} =
               ManageAudience.get_shared_audience_groups(client, 1)

      assert response.audienceGroups == []
    end
  end

  describe "update_audience_group_description/4" do
    test "builds path from numeric audience_group_id and sends JSON body", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(
        bypass,
        "PUT",
        "/v2/bot/audienceGroup/999/updateDescription",
        fn conn ->
          assert Passby.get_req_header(conn, "content-type") == ["application/json"]
          assert JSON.decode!(conn.req_body) == %{"description" => "renamed-audience"}

          Passby.resp(conn, 200, "")
        end
      )

      request = %UpdateAudienceGroupDescriptionRequest{description: "renamed-audience"}

      assert {:ok, %Req.Response{}} =
               ManageAudience.update_audience_group_description(client, 999, request)
    end
  end
end
