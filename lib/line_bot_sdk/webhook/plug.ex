defmodule LINE.Bot.Webhook.Plug do
  @moduledoc """
  A Plug for handling LINE Bot webhook requests.

  This plug verifies the request signature, parses the JSON body,
  and assigns `events` and `destination` to the connection.

  ## Usage

      plug LINE.Bot.Webhook.Plug, channel_secret: "your_channel_secret"

  The `channel_secret` option also accepts an `{module, function, arguments}` tuple
  to resolve the secret at runtime:

      plug LINE.Bot.Webhook.Plug, channel_secret: {System, :fetch_env!, ["LINE_CHANNEL_SECRET"]}

  On success, `conn.assigns.webhook_payload` will contain the `CallbackRequest` struct.
  On failure, the plug responds with 401 and halts the connection.
  """

  import Plug.Conn

  alias LINE.Bot.Webhook
  alias LINE.Bot.Webhook.Model.CallbackRequest
  alias LINE.Bot.Deserializer

  @behaviour Plug

  @impl true
  def init(opts) do
    channel_secret =
      Keyword.get(opts, :channel_secret) ||
        raise ArgumentError, "expected :channel_secret option"

    %{channel_secret: channel_secret}
  end

  @impl true
  def call(conn, %{channel_secret: channel_secret}) do
    channel_secret = resolve_channel_secret(channel_secret)

    with {:ok, body, conn} <- read_body(conn),
         [signature | _] <- get_req_header(conn, "x-line-signature"),
         true <- Webhook.signature_valid?(channel_secret, signature, body) do
      body_params = JSON.decode!(body)

      callback_request = Deserializer.decode_map(body_params, CallbackRequest)

      conn
      |> Map.put(:body_params, body_params)
      |> assign(:webhook_payload, callback_request)
    else
      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end

  defp resolve_channel_secret({m, f, a}), do: apply(m, f, a)
  defp resolve_channel_secret(secret) when is_binary(secret), do: secret
end
