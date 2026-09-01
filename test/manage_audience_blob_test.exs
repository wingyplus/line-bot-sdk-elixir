# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.ManageAudienceBlobTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.ManageAudienceBlob

  alias LINE.Bot.ManageAudienceBlob
  alias LINE.Bot.ManageAudience.Model.CreateAudienceGroupResponse

  describe "create_audience_for_uploading_user_ids/4" do
    test "sends POST request with the file and description", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/audienceGroup/upload/byFile", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]
        assert conn.req_body =~ "c9161b19-57f8-46c2-a71f-dfa87314dabe"
        assert conn.req_body =~ "test_description"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(202, ~s({"audienceGroupId": 1234567890123, "type": "UPLOAD"}))
      end)

      assert {:ok, %CreateAudienceGroupResponse{} = response} =
               ManageAudienceBlob.create_audience_for_uploading_user_ids(
                 client,
                 "c9161b19-57f8-46c2-a71f-dfa87314dabe",
                 description: "test_description",
                 is_ifa_audience: true
               )

      assert response.audienceGroupId == 1_234_567_890_123
      assert response.type == "UPLOAD"
    end

    test "omits optional fields when not provided", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/audienceGroup/upload/byFile", fn conn ->
        assert conn.req_body =~ "user-id-1"
        refute conn.req_body =~ "description"
        refute conn.req_body =~ "isIfaAudience"
        refute conn.req_body =~ "uploadDescription"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(202, "{}")
      end)

      assert {:ok, %CreateAudienceGroupResponse{}} =
               ManageAudienceBlob.create_audience_for_uploading_user_ids(client, "user-id-1")
    end

    test "preserves false for is_ifa_audience", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/audienceGroup/upload/byFile", fn conn ->
        assert conn.req_body =~ "isIfaAudience"
        assert conn.req_body =~ "false"
        assert conn.req_body =~ "test_description"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(202, "{}")
      end)

      assert {:ok, %CreateAudienceGroupResponse{}} =
               ManageAudienceBlob.create_audience_for_uploading_user_ids(client, "user-id-1",
                 description: "test_description",
                 is_ifa_audience: false
               )
    end
  end

  describe "add_user_ids_to_audience/4" do
    test "sends PUT request with the file and audience group id", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "PUT", "/v2/bot/audienceGroup/upload/byFile", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]
        assert conn.req_body =~ "user-id-1"
        assert conn.req_body =~ "1234567890123"
        assert conn.req_body =~ "test_upload"

        Passby.resp(conn, 202, "")
      end)

      assert {:ok, %Req.Response{}} =
               ManageAudienceBlob.add_user_ids_to_audience(client, "user-id-1",
                 audience_group_id: 1_234_567_890_123,
                 upload_description: "test_upload"
               )
    end

    test "omits optional fields when not provided", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "PUT", "/v2/bot/audienceGroup/upload/byFile", fn conn ->
        assert conn.req_body =~ "user-id-1"
        refute conn.req_body =~ "audienceGroupId"
        refute conn.req_body =~ "uploadDescription"

        Passby.resp(conn, 202, "")
      end)

      assert {:ok, %Req.Response{}} =
               ManageAudienceBlob.add_user_ids_to_audience(client, "user-id-1")
    end
  end
end
