# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.ClientCase do
  @moduledoc """
  Case template for testing API clients against a `Passby` mock server.

  Pass the API module to build a client from:

      use LINE.Bot.ClientCase, async: true, client: LINE.Bot.Insight

  Each test receives `:bypass` (the `Passby` instance) and `:client` (a client
  pointing at that instance, authorized with `channel_token/0`) in its context.
  """

  use ExUnit.CaseTemplate

  @channel_token "test-channel-token"

  @doc """
  The channel access token the client under test is built with.
  """
  def channel_token, do: @channel_token

  using opts do
    quote do
      setup do
        LINE.Bot.ClientCase.open_client(unquote(Keyword.fetch!(opts, :client)))
      end
    end
  end

  @doc """
  Starts a `Passby` instance and builds a client of `module` pointing at it.
  """
  def open_client(module) do
    bypass = Passby.open()

    client = module.new(base_url: bypass.url, channel_token: @channel_token)

    {:ok, bypass: bypass, client: client}
  end
end
