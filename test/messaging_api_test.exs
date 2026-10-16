# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.MessagingApiTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.MessagingApi

  alias LINE.Bot.MessagingApi
  alias LINE.Bot.MessagingApi.Model.PushMessageRequest
  alias LINE.Bot.MessagingApi.Model.BroadcastRequest
  alias LINE.Bot.MessagingApi.Model.ReplyMessageRequest
  alias LINE.Bot.MessagingApi.Model.TextMessage
  alias LINE.Bot.MessagingApi.Model.ErrorDetail
  alias LINE.Bot.MessagingApi.Model.CouponCreateRequest
  alias LINE.Bot.MessagingApi.Model.CouponListResponse
  alias LINE.Bot.MessagingApi.Model.BotInfoResponse
  alias LINE.Bot.MessagingApi.Model.CouponCreateResponse
  alias LINE.Bot.MessagingApi.Model.CouponResponse
  alias LINE.Bot.MessagingApi.Model.ErrorResponse
  alias LINE.Bot.MessagingApi.Model.GetFollowersResponse
  alias LINE.Bot.MessagingApi.Model.GroupUserProfileResponse
  alias LINE.Bot.MessagingApi.Model.MembersIdsResponse
  alias LINE.Bot.MessagingApi.Model.MessagingApiPagerCouponListResponse
  alias LINE.Bot.MessagingApi.Model.PushMessageResponse
  alias LINE.Bot.MessagingApi.Model.ReplyMessageResponse
  alias LINE.Bot.MessagingApi.Model.UserProfileResponse

  describe "push_message/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/message/push", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"sentMessages": []}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      assert {:ok, %PushMessageResponse{} = response} = MessagingApi.push_message(client, request)
      assert response.sentMessages == []
    end

    test "sends request with x-line-retry-key header when provided", %{
      bypass: bypass,
      client: client
    } do
      retry_key = "123e4567-e89b-12d3-a456-426614174000"

      Passby.expect_once(bypass, "POST", "/v2/bot/message/push", fn conn ->
        assert Passby.get_req_header(conn, "x-line-retry-key") == [retry_key]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"sentMessages": []}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      assert {:ok, %PushMessageResponse{}} =
               MessagingApi.push_message(client, request, x_line_retry_key: retry_key)
    end
  end

  describe "get_followers/2" do
    test "sends GET request with start and limit query parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/followers/ids", fn conn ->
        assert conn.query_string =~ "start=some-start"
        assert conn.query_string =~ "limit=1000"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"userIds": [], "next": "abcdef"}))
      end)

      assert {:ok, %GetFollowersResponse{} = response} =
               MessagingApi.get_followers(client, start: "some-start", limit: 1000)

      assert response.userIds == []
      assert response.next == "abcdef"
    end
  end

  describe "get_group_members_ids/3" do
    test "sends GET request with group_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/group/test-group-id/members/ids", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"memberIds": ["member1", "member2"], "next": "abcdef"}))
      end)

      assert {:ok, %MembersIdsResponse{} = response} =
               MessagingApi.get_group_members_ids(client, "test-group-id")

      assert response.memberIds == ["member1", "member2"]
      assert response.next == "abcdef"
    end

    test "sends GET request with start query parameter when provided", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/group/test-group-id/members/ids", fn conn ->
        assert conn.query_string =~ "start=token123"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"memberIds": [], "next": null}))
      end)

      assert {:ok, %MembersIdsResponse{}} =
               MessagingApi.get_group_members_ids(client, "test-group-id", start: "token123")
    end

    test "sends GET request without start query parameter when not provided", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/group/test-group-id/members/ids", fn conn ->
        refute conn.query_string =~ "start="

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"memberIds": []}))
      end)

      assert {:ok, %MembersIdsResponse{}} =
               MessagingApi.get_group_members_ids(client, "test-group-id")
    end
  end

  describe "get_bot_info/2" do
    test "sends GET request and returns bot info", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/info", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"userId": "U12345", "basicId": "@bot", "displayName": "Test Bot"})
        )
      end)

      assert {:ok, %BotInfoResponse{} = response} = MessagingApi.get_bot_info(client)
      assert response.userId == "U12345"
      assert response.basicId == "@bot"
      assert response.displayName == "Test Bot"
    end
  end

  describe "get_profile/3" do
    test "sends GET request with user_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/profile/U12345", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"userId": "U12345", "displayName": "Test User"}))
      end)

      assert {:ok, %UserProfileResponse{} = response} = MessagingApi.get_profile(client, "U12345")
      assert response.userId == "U12345"
      assert response.displayName == "Test User"
    end

    test "decodes format: uri fields as strings", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/profile/U12345", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"userId": "U12345", "displayName": "Test User", "pictureUrl": "https://example.com/p.jpg"})
        )
      end)

      assert {:ok, %UserProfileResponse{} = response} = MessagingApi.get_profile(client, "U12345")
      assert response.pictureUrl == "https://example.com/p.jpg"
    end
  end

  describe "broadcast/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/message/broadcast", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      request = %BroadcastRequest{
        messages: [%TextMessage{type: "text", text: "Hello, everyone!"}]
      }

      assert {:ok, response} = MessagingApi.broadcast(client, request)
      refute is_struct(response)
      assert response == %{}
    end
  end

  describe "reply_message/3" do
    test "sends POST request with replyToken and messages", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/message/reply", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"sentMessages": []}))
      end)

      request = %ReplyMessageRequest{
        replyToken: "test-reply-token",
        messages: [%TextMessage{type: "text", text: "Thanks for your message!"}]
      }

      assert {:ok, %ReplyMessageResponse{} = response} =
               MessagingApi.reply_message(client, request)

      assert response.sentMessages == []
    end
  end

  describe "list_coupon/3" do
    test "sends GET request with status, start and limit query parameters", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/coupon", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        params = URI.decode_query(conn.query_string)

        assert params["status"] == "DRAFT,RUNNING,CLOSED"
        assert params["start"] == "xBQU2IB"
        assert params["limit"] == "100"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          200,
          ~s({"items": [{"couponId": "coupon_id_1", "title": "coupon 1"}], "next": "yANU9IA.."})
        )
      end)

      assert {:ok, %MessagingApiPagerCouponListResponse{} = response} =
               MessagingApi.list_coupon(client,
                 status: "DRAFT,RUNNING,CLOSED",
                 start: "xBQU2IB",
                 limit: 100
               )

      assert response.items == [%CouponListResponse{couponId: "coupon_id_1", title: "coupon 1"}]
      assert response.next == "yANU9IA.."
    end

    test "omits optional query parameters when not provided", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/coupon", fn conn ->
        assert conn.query_string == ""

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"items": []}))
      end)

      assert {:ok, %MessagingApiPagerCouponListResponse{} = response} =
               MessagingApi.list_coupon(client)

      assert response.items == []
    end
  end

  describe "create_coupon/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/coupon", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]

        body = JSON.decode!(conn.req_body)

        assert body["title"] == "coupon 1"
        assert body["startTimestamp"] == 1_700_000_000_000
        assert body["endTimestamp"] == 1_800_000_000_000

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"couponId": "coupon_id_1"}))
      end)

      request = %CouponCreateRequest{
        title: "coupon 1",
        startTimestamp: 1_700_000_000_000,
        endTimestamp: 1_800_000_000_000,
        maxUseCountPerTicket: 1,
        timezone: "ASIA_TOKYO"
      }

      assert {:ok, %CouponCreateResponse{} = response} =
               MessagingApi.create_coupon(client, body: request)

      assert response.couponId == "coupon_id_1"
    end
  end

  describe "get_coupon_detail/3" do
    test "sends GET request with coupon_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/coupon/coupon_id_1", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"couponId": "coupon_id_1", "title": "coupon 1"}))
      end)

      assert {:ok, %CouponResponse{} = response} =
               MessagingApi.get_coupon_detail(client, "coupon_id_1")

      assert response.couponId == "coupon_id_1"
      assert response.title == "coupon 1"
    end

    test "decodes a 404 into an error response", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/coupon/unknown", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(404, ~s({"message": "Not found"}))
      end)

      assert {:ok, %ErrorResponse{} = response} =
               MessagingApi.get_coupon_detail(client, "unknown")

      assert response.message == "Not found"
    end
  end

  describe "close_coupon/3" do
    test "sends PUT request with coupon_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "PUT", "/v2/bot/coupon/coupon_id_1/close", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        Passby.resp(conn, 200, "")
      end)

      assert {:ok, %Req.Response{}} = MessagingApi.close_coupon(client, "coupon_id_1")
    end
  end

  describe "path parameter encoding" do
    test "encodes a slash in the user_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/profile/..%2Falice", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, %UserProfileResponse{}} = MessagingApi.get_profile(client, "../alice")
    end

    test "treats an encoded dot sequence as data", %{bypass: bypass, client: client} do
      Passby.expect_once(
        bypass,
        "GET",
        "/v2/bot/profile/%252e%252e%2Fmessage%2Fquota",
        fn conn ->
          conn
          |> Passby.put_resp_header("content-type", "application/json")
          |> Passby.resp(200, "{}")
        end
      )

      assert {:ok, %UserProfileResponse{}} =
               MessagingApi.get_profile(client, "%2e%2e/message/quota")
    end

    test "encodes every path parameter of a multi-path endpoint", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(
        bypass,
        "GET",
        "/v2/bot/group/..%2Fgroup/member/user%2F42",
        fn conn ->
          conn
          |> Passby.put_resp_header("content-type", "application/json")
          |> Passby.resp(200, "{}")
        end
      )

      assert {:ok, %GroupUserProfileResponse{}} =
               MessagingApi.get_group_member_profile(client, "../group", "user/42")
    end
  end

  describe "error handling" do
    test "decodes a mapped error status into an error response", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/message/push", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(
          400,
          ~s({"message": "The request body has 1 error", "details": [{"message": "May not be empty", "property": "messages[0].text"}]})
        )
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: ""}]
      }

      assert {:ok, %ErrorResponse{} = response} = MessagingApi.push_message(client, request)
      assert response.message == "The request body has 1 error"

      assert response.details == [
               %ErrorDetail{message: "May not be empty", property: "messages[0].text"}
             ]
    end

    test "returns an error tuple for an unmapped error status", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/v2/bot/message/push", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.put_resp_header("x-line-request-id", "f70dd685-499a-4231-a441-f24b8d4fba21")
        |> Passby.resp(401, ~s({"message": "Authentication failed"}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      assert {:error, %Req.Response{} = response} = MessagingApi.push_message(client, request)
      assert response.status == 401
      assert response.body["message"] == "Authentication failed"

      assert Req.Response.get_header(response, "x-line-request-id") == [
               "f70dd685-499a-4231-a441-f24b8d4fba21"
             ]
    end
  end

  describe "calling API twice" do
    test "can call the same API endpoint twice with the same client", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect(bypass, "POST", "/v2/bot/message/push", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, ~s({"sentMessages": []}))
      end)

      request = %PushMessageRequest{
        to: "U12345678901234567890123456789012",
        messages: [%TextMessage{type: "text", text: "Hello, world"}]
      }

      # First call
      assert {:ok, %PushMessageResponse{}} = MessagingApi.push_message(client, request)

      # Second call with the same client
      assert {:ok, %PushMessageResponse{}} = MessagingApi.push_message(client, request)
    end
  end
end
