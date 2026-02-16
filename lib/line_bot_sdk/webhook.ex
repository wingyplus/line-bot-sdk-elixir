defmodule LINE.Bot.Webhook do
  def signature_valid?(channel_secret, signature, body) do
    case Base.decode64(signature) do
      {:ok, decoded} ->
        expected = :crypto.mac(:hmac, :sha256, channel_secret, body)
        Plug.Crypto.secure_compare(expected, decoded)

      :error ->
        false
    end
  end
end
