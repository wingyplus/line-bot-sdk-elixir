defmodule LINE.Bot.Webhook.PlugTest do
  use ExUnit.Case, async: true

  alias LINE.Bot.Webhook.Plug, as: WebhookPlug
  alias LINE.Bot.Webhook.Model.CallbackRequest
  alias LINE.Bot.Webhook.Model.DeliveryContext
  alias LINE.Bot.Webhook.Model.FollowEvent
  alias LINE.Bot.Webhook.Model.MessageEvent
  alias LINE.Bot.Webhook.Model.UnfollowEvent
  alias LINE.Bot.Webhook.Model.UserSource

  @channel_secret "testsecret"
  @body ~s({"destination":"U1234","events":[{"type":"message"}]})

  @realistic_body JSON.encode!(%{
                    "destination" => "xxxxxxxxxx",
                    "events" => [
                      %{
                        "type" => "message",
                        "message" => %{
                          "type" => "text",
                          "id" => "14353798921116",
                          "text" => "Hello, world"
                        },
                        "timestamp" => 1_625_665_242_211,
                        "source" => %{
                          "type" => "user",
                          "userId" => "U80696558e1aa831..."
                        },
                        "replyToken" => "757913772c4646b784d4b7ce46d12671",
                        "mode" => "active",
                        "webhookEventId" => "01FZ74A0TDDPYRVKNK77XKC3ZR",
                        "deliveryContext" => %{
                          "isRedelivery" => false
                        }
                      },
                      %{
                        "type" => "follow",
                        "timestamp" => 1_625_665_242_214,
                        "source" => %{
                          "type" => "user",
                          "userId" => "Ufc729a925b3abef..."
                        },
                        "replyToken" => "bb173f4d9cf64aed9d408ab4e36339ad",
                        "mode" => "active",
                        "webhookEventId" => "01FZ74ASS536FW97EX38NKCZQK",
                        "deliveryContext" => %{
                          "isRedelivery" => false
                        }
                      },
                      %{
                        "type" => "unfollow",
                        "timestamp" => 1_625_665_242_215,
                        "source" => %{
                          "type" => "user",
                          "userId" => "Ubbd4f124aee5113..."
                        },
                        "mode" => "active",
                        "webhookEventId" => "01FZ74B5Y0F4TNKA5SCAVKPEDM",
                        "deliveryContext" => %{
                          "isRedelivery" => false
                        }
                      }
                    ]
                  })

  defp sign(body) do
    :crypto.mac(:hmac, :sha256, @channel_secret, body) |> Base.encode64()
  end

  def channel_secret, do: @channel_secret

  defp build_conn(body, signature) do
    Plug.Test.conn(:post, "/webhook", body)
    |> Plug.Conn.put_req_header("x-line-signature", signature)
    |> Plug.Conn.put_req_header("content-type", "application/json")
  end

  test "valid signature assigns webhook_payload" do
    conn =
      build_conn(@body, sign(@body))
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: @channel_secret))

    assert %CallbackRequest{
             destination: "U1234",
             events: [%MessageEvent{type: "message"}]
           } = conn.assigns[:webhook_payload]

    refute conn.halted
  end

  test "invalid signature returns 401 and halts" do
    conn =
      build_conn(@body, "invalidsignature")
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: @channel_secret))

    assert conn.status == 401
    assert conn.halted
  end

  test "missing signature header returns 401 and halts" do
    conn =
      Plug.Test.conn(:post, "/webhook", @body)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: @channel_secret))

    assert conn.status == 401
    assert conn.halted
  end

  test "channel_secret as MFA resolves at runtime" do
    conn =
      build_conn(@body, sign(@body))
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: {__MODULE__, :channel_secret, []}))

    assert %CallbackRequest{
             destination: "U1234",
             events: [%MessageEvent{type: "message"}]
           } = conn.assigns[:webhook_payload]

    refute conn.halted
  end

  test "body_params is set after call" do
    conn =
      build_conn(@body, sign(@body))
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: @channel_secret))

    assert conn.body_params == %{"destination" => "U1234", "events" => [%{"type" => "message"}]}
  end

  test "decodes realistic webhook payload with multiple event types" do
    conn =
      build_conn(@realistic_body, sign(@realistic_body))
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: @channel_secret))

    assert %CallbackRequest{
             destination: "xxxxxxxxxx",
             events: [message_event, follow_event, unfollow_event]
           } = conn.assigns[:webhook_payload]

    # Message event
    assert %MessageEvent{
             type: "message",
             timestamp: 1_625_665_242_211,
             webhookEventId: "01FZ74A0TDDPYRVKNK77XKC3ZR",
             source: %UserSource{type: "user"},
             deliveryContext: %DeliveryContext{isRedelivery: false}
           } = message_event

    # Follow event
    assert %FollowEvent{
             type: "follow",
             timestamp: 1_625_665_242_214,
             webhookEventId: "01FZ74ASS536FW97EX38NKCZQK",
             source: %UserSource{type: "user"},
             deliveryContext: %DeliveryContext{isRedelivery: false}
           } = follow_event

    # Unfollow event
    assert %UnfollowEvent{
             type: "unfollow",
             timestamp: 1_625_665_242_215,
             webhookEventId: "01FZ74B5Y0F4TNKA5SCAVKPEDM",
             source: %UserSource{type: "user"},
             deliveryContext: %DeliveryContext{isRedelivery: false}
           } = unfollow_event

    refute conn.halted
  end

  test "init raises without channel_secret" do
    assert_raise ArgumentError, ~r/expected :channel_secret/, fn ->
      WebhookPlug.init([])
    end
  end
end
