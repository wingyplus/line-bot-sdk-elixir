defmodule LINE.Bot.WebhookTest do
  use ExUnit.Case, async: true

  alias LINE.Bot.Webhook

  @channel_secret "testsecret"
  @body ~s({"events":[]})

  setup do
    sig = :crypto.mac(:hmac, :sha256, @channel_secret, @body) |> Base.encode64()
    %{sig: sig}
  end

  test "valid signature returns true", %{sig: sig} do
    assert Webhook.signature_valid?(@channel_secret, sig, @body) == true
  end

  test "invalid signature returns false", _context do
    assert Webhook.signature_valid?(@channel_secret, "invalidSignature", @body) == false
  end

  test "tampered body returns false", %{sig: sig} do
    body = ~s({"events":[{"type":"tampered"}]})
    assert Webhook.signature_valid?(@channel_secret, sig, body) == false
  end
end
