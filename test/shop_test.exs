# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.ShopTest do
  use ExUnit.Case, async: true

  alias LINE.Bot.Shop
  alias LINE.Bot.Shop.Model.MissionStickerRequest

  setup do
    bypass = Bypass.open()
    client = Req.new(base_url: "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass, client: client}
  end

  describe "mission_sticker_v3/3" do
    test "sends POST request with JSON body", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/shop/v3/mission", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "{}")
      end)

      request = %MissionStickerRequest{
        to: "U12345678901234567890123456789012",
        productId: "1234567890",
        productType: "sticker",
        sendPresentMessage: true
      }

      assert {:ok, _response} = Shop.mission_sticker_v3(client, request)
    end
  end
end
