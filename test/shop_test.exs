# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.ShopTest do
  use LINE.Bot.ClientCase, async: true, client: LINE.Bot.Shop

  alias LINE.Bot.Shop
  alias LINE.Bot.Shop.Model.MissionStickerRequest

  describe "mission_sticker_v3/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Passby.expect_once(bypass, "POST", "/shop/v3/mission", fn conn ->
        assert Passby.get_req_header(conn, "content-type") == ["application/json"]
        assert Passby.get_req_header(conn, "authorization") == ["Bearer test-channel-token"]

        conn
        |> Passby.put_resp_header("content-type", "application/json")
        |> Passby.resp(200, "{}")
      end)

      request = %MissionStickerRequest{
        to: "U12345678901234567890123456789012",
        productId: "1234567890",
        productType: "sticker",
        sendPresentMessage: true
      }

      assert {:ok, %Req.Response{}} = Shop.mission_sticker_v3(client, request)
    end
  end
end
