# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.MessagingApiBlobTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.MessagingApiBlob

  alias LINE.Bot.MessagingApiBlob
  alias LINE.Bot.MessagingApi.Model.GetMessageContentTranscodingResponse

  describe "get_message_content/3" do
    test "sends GET request with message_id path parameter and returns the raw content", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "GET", "/v2/bot/message/test-message-id/content", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "image/jpeg")
        |> Passby.resp(200, "GREAT_JPEG")
      end)

      assert {:ok, %Req.Response{} = response} =
               MessagingApiBlob.get_message_content(client, "test-message-id")

      assert response.body == "GREAT_JPEG"
    end
  end

  describe "get_message_content_preview/3" do
    test "sends GET request with message_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(
        bypass,
        "GET",
        "/v2/bot/message/test-message-id/content/preview",
        fn conn ->
          conn
          |> Passby.put_resp_header("content-type", "image/jpeg")
          |> Passby.resp(200, "GREAT_PREVIEW")
        end
      )

      assert {:ok, %Req.Response{} = response} =
               MessagingApiBlob.get_message_content_preview(client, "test-message-id")

      assert response.body == "GREAT_PREVIEW"
    end
  end

  describe "get_message_content_transcoding_by_message_id/3" do
    test "sends GET request and returns the transcoding status", %{bypass: bypass, client: client} do
      Passby.expect_once(
        bypass,
        "GET",
        "/v2/bot/message/test-message-id/content/transcoding",
        fn conn ->
          conn
          |> Passby.put_resp_header("content-type", "application/json")
          |> Passby.resp(200, ~s({"status": "succeeded"}))
        end
      )

      assert {:ok, %GetMessageContentTranscodingResponse{} = response} =
               MessagingApiBlob.get_message_content_transcoding_by_message_id(
                 client,
                 "test-message-id"
               )

      assert response.status == "succeeded"
    end
  end

  describe "get_rich_menu_image/3" do
    test "sends GET request with rich_menu_id path parameter", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "GET", "/v2/bot/richmenu/test-rich-menu-id/content", fn conn ->
        conn
        |> Passby.put_resp_header("content-type", "image/png")
        |> Passby.resp(200, "GREAT_PNG")
      end)

      assert {:ok, %Req.Response{} = response} =
               MessagingApiBlob.get_rich_menu_image(client, "test-rich-menu-id")

      assert response.body == "GREAT_PNG"
    end
  end

  describe "set_rich_menu_image/4" do
    test "sends POST request with rich_menu_id path parameter and the image body", %{
      bypass: bypass,
      client: client
    } do
      Passby.expect_once(bypass, "POST", "/v2/bot/richmenu/test-rich-menu-id/content", fn conn ->
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]
        assert conn.req_body =~ "GREAT_JPEG"

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      assert {:ok, %Req.Response{}} =
               MessagingApiBlob.set_rich_menu_image(client, "test-rich-menu-id", "GREAT_JPEG")
    end
  end
end
