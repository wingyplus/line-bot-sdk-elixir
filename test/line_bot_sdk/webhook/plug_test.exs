defmodule LINE.Bot.Webhook.PlugTest do
  use ExUnit.Case, async: true

  alias LINE.Bot.Webhook.Plug, as: WebhookPlug

  @channel_secret "testsecret"
  @body ~s({"destination":"U1234","events":[{"type":"message"}]})

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

    payload = conn.assigns[:webhook_payload]
    assert payload.destination == "U1234"
    assert length(payload.events) == 1
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

    payload = conn.assigns[:webhook_payload]
    assert payload.destination == "U1234"
    assert length(payload.events) == 1
    refute conn.halted
  end

  test "body_params is set after call" do
    conn =
      build_conn(@body, sign(@body))
      |> WebhookPlug.call(WebhookPlug.init(channel_secret: @channel_secret))

    assert conn.body_params == %{"destination" => "U1234", "events" => [%{"type" => "message"}]}
  end

  test "init raises without channel_secret" do
    assert_raise ArgumentError, ~r/expected :channel_secret/, fn ->
      WebhookPlug.init([])
    end
  end
end
