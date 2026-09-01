# LINE Messaging API SDK for Elixir

[![Hex.pm](https://img.shields.io/hexpm/v/line_bot_sdk.svg)](https://hex.pm/packages/line_bot_sdk)
[![Documentation](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/line_bot_sdk)
[![CI](https://github.com/wingyplus/line-bot-sdk-elixir/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/wingyplus/line-bot-sdk-elixir/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](https://github.com/wingyplus/line-bot-sdk-elixir/blob/main/LICENSE)

## Introduction

The LINE Messaging API SDK for Elixir makes it easy to develop bots using the LINE
Messaging API, and you can create a sample bot within minutes.

The API clients in this SDK are generated from the [line-openapi](https://github.com/line/line-openapi)
specification published by LINE, so they track the official API surface.

> [!NOTE]
> This is a community-maintained SDK. It is not an official LINE product.

## Documentation

See the official API documentation for more information.

- English: https://developers.line.biz/en/docs/messaging-api/overview/
- Japanese: https://developers.line.biz/ja/docs/messaging-api/overview/

Module reference for this SDK is published on [HexDocs](https://hexdocs.pm/line_bot_sdk).

## Requirements

This library requires Elixir 1.18 or later.

## Installation

Add `:line_bot_sdk` to the dependencies in your `mix.exs`:

```elixir
def deps do
  [
    {:line_bot_sdk, "~> 0.1"}
  ]
end
```

Then fetch it:

```sh
$ mix deps.get
```

## Configuration

Every API client is built with `new/1`, which returns a `Req.Request` struct that you
pass to each API call. Keep your channel access token and channel secret out of the
source tree — read them from the environment or from application config.

```elixir
client =
  LINE.Bot.MessagingApi.new(
    channel_token: System.fetch_env!("LINE_CHANNEL_TOKEN")
  )
```

`new/1` accepts:

- `:channel_token` — channel access token used for bearer authorization (required by
  every client except `LINE.Bot.ChannelAccessToken`, which issues tokens).
- `:base_url` — base URL for requests. Each client has its own default, listed under
  [API clients](#api-clients).
- `:plug` — a plug to serve the requests instead of the network, for testing. See
  [Testing](#testing).

Every API call takes a final keyword list that is merged into the underlying
`Req.request/2` call, so you can set `:receive_timeout`, `:retry` or anything else Req
understands on a per-request basis:

```elixir
LINE.Bot.MessagingApi.push_message(client, request, [], receive_timeout: 10_000)
```

## API clients

| Module                        | API                                                  | Default base URL                 |
| ----------------------------- | ---------------------------------------------------- | -------------------------------- |
| `LINE.Bot.MessagingApi`       | Messaging API                                        | `https://api.line.me`            |
| `LINE.Bot.MessagingApiBlob`   | Messaging API endpoints that transfer binary content | `https://api.line.me` (see note) |
| `LINE.Bot.ChannelAccessToken` | Channel access token issuing and revoking            | `https://api.line.me`            |
| `LINE.Bot.Insight`            | Insight API                                          | `https://api.line.me`            |
| `LINE.Bot.Liff`               | LIFF server API                                      | `https://api.line.me`            |
| `LINE.Bot.ManageAudience`     | Audience management                                  | `https://api.line.me`            |
| `LINE.Bot.ManageAudienceBlob` | Audience management file uploads                     | `https://api.line.me` (see note) |
| `LINE.Bot.LineModule`         | Module API                                           | `https://api.line.me`            |
| `LINE.Bot.LineModuleAttach`   | Module attach API                                    | `https://manager.line.biz`       |
| `LINE.Bot.Shop`               | Shop API                                             | `https://api.line.me`            |

> [!IMPORTANT]
> LINE serves the blob endpoints from `https://api-data.line.me`, but the generated
> clients do not yet pick up that per-operation host. Pass it explicitly:
>
> ```elixir
> LINE.Bot.MessagingApiBlob.new(
>   base_url: "https://api-data.line.me",
>   channel_token: System.fetch_env!("LINE_CHANNEL_TOKEN")
> )
> ```

Request and response bodies are plain structs under each client's `Model` namespace, for
example `LINE.Bot.MessagingApi.Model.TextMessage`. Webhook event structs live under
`LINE.Bot.Webhook.Model`.

## Getting started

The snippet below is a complete echo bot: it verifies the webhook signature, decodes the
events and replies to every text message with the same text.

```elixir
defmodule MyBot.Router do
  use Plug.Router

  alias LINE.Bot.MessagingApi
  alias LINE.Bot.MessagingApi.Model.ReplyMessageRequest
  alias LINE.Bot.MessagingApi.Model.TextMessage
  alias LINE.Bot.Webhook.Model.MessageEvent
  alias LINE.Bot.Webhook.Model.TextMessageContent

  plug :match
  plug LINE.Bot.Webhook.Plug, channel_secret: {System, :fetch_env!, ["LINE_CHANNEL_SECRET"]}
  plug :dispatch

  post "/callback" do
    client = MessagingApi.new(channel_token: System.fetch_env!("LINE_CHANNEL_TOKEN"))

    Enum.each(conn.assigns.webhook_payload.events, &handle_event(client, &1))

    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  # Echo any text message back to the sender.
  defp handle_event(client, %MessageEvent{
         replyToken: reply_token,
         message: %TextMessageContent{text: text}
       })
       when is_binary(reply_token) do
    MessagingApi.reply_message(client, %ReplyMessageRequest{
      replyToken: reply_token,
      messages: [%TextMessage{type: "text", text: text}]
    })
  end

  defp handle_event(_client, _event), do: :ok
end
```

## Webhook

### The plug

`LINE.Bot.Webhook.Plug` verifies the `x-line-signature` header, decodes the request body
and assigns the parsed `LINE.Bot.Webhook.Model.CallbackRequest` struct to
`conn.assigns.webhook_payload`. A request whose signature is missing or does not match
gets a `401` response and the connection is halted, so your handler only ever sees
verified payloads.

```elixir
plug LINE.Bot.Webhook.Plug, channel_secret: {System, :fetch_env!, ["LINE_CHANNEL_SECRET"]}
```

`:channel_secret` is required and accepts either a plain string, which is resolved when
the plug pipeline is compiled, or an `{module, function, arguments}` tuple, which is
resolved on every request. Prefer the tuple form so the secret is read at runtime rather
than baked into the compiled module.

The plug reads the raw request body itself, because the signature is computed over the
bytes exactly as they were sent. Do not run `Plug.Parsers` on the webhook path ahead of
it, or the body will already be consumed and verification will fail. The decoded JSON map
is still available afterwards as `conn.body_params` if you need the untyped payload.

### The payload

`conn.assigns.webhook_payload` is a `CallbackRequest` with two fields:

- `destination` — the user ID of the bot that should receive the events.
- `events` — a list of event structs.

Fields keep the casing used by the LINE API, so they are `replyToken` and
`webhookEventId`, not `reply_token` and `webhook_event_id`.

### Events

Each entry in `events` is decoded into a concrete struct under
`LINE.Bot.Webhook.Model` based on its `type`, so you can dispatch with pattern matching:

| `type`              | Struct                       |
| ------------------- | ---------------------------- |
| `message`           | `MessageEvent`               |
| `messageEdited`     | `MessageEditedEvent`         |
| `unsend`            | `UnsendEvent`                |
| `follow`            | `FollowEvent`                |
| `unfollow`          | `UnfollowEvent`              |
| `join`              | `JoinEvent`                  |
| `leave`             | `LeaveEvent`                 |
| `memberJoined`      | `MemberJoinedEvent`          |
| `memberLeft`        | `MemberLeftEvent`            |
| `membership`        | `MembershipEvent`            |
| `postback`          | `PostbackEvent`              |
| `videoPlayComplete` | `VideoPlayCompleteEvent`     |
| `beacon`            | `BeaconEvent`                |
| `accountLink`       | `AccountLinkEvent`           |
| `delivery`          | `PnpDeliveryCompletionEvent` |
| `module`            | `ModuleEvent`                |
| `activated`         | `ActivatedEvent`             |
| `deactivated`       | `DeactivatedEvent`           |
| `botSuspended`      | `BotSuspendedEvent`          |
| `botResumed`        | `BotResumedEvent`            |

An event type this SDK does not know about — a new one added to the platform, for
instance — decodes into the base `LINE.Bot.Webhook.Model.Event` struct rather than
raising, so a catch-all clause keeps your bot running:

```elixir
defp handle_event(_client, %Event{type: type}) do
  Logger.info("ignoring unhandled event type #{type}")
end
```

The `source` of an event is likewise one of `UserSource`, `GroupSource` or `RoomSource`,
and the `message` of a `MessageEvent` is one of `TextMessageContent`,
`ImageMessageContent`, `VideoMessageContent`, `AudioMessageContent`,
`FileMessageContent`, `LocationMessageContent` or `StickerMessageContent`. Matching on
both at once is a compact way to route:

```elixir
defp handle_event(client, %MessageEvent{
       source: %UserSource{userId: user_id},
       message: %StickerMessageContent{stickerId: sticker_id}
     }) do
  ...
end
```

### Verifying a signature yourself

If you receive the request body somewhere other than a plug pipeline, verify it directly.
Pass the raw bytes, not a re-encoded map:

```elixir
LINE.Bot.Webhook.signature_valid?(channel_secret, signature, raw_body)
```

It returns a boolean and compares in constant time.

## Calling the API

### Sending a message

```elixir
alias LINE.Bot.MessagingApi
alias LINE.Bot.MessagingApi.Model.PushMessageRequest
alias LINE.Bot.MessagingApi.Model.TextMessage

client = MessagingApi.new(channel_token: System.fetch_env!("LINE_CHANNEL_TOKEN"))

request = %PushMessageRequest{
  to: "U4af4980629...",
  messages: [%TextMessage{type: "text", text: "Hello, world"}]
}

{:ok, response} = MessagingApi.push_message(client, request)
```

Optional headers such as the retry key are passed through the optional-arguments keyword
list:

```elixir
MessagingApi.push_message(client, request,
  x_line_retry_key: "123e4567-e89b-12d3-a456-426614174000"
)
```

### Handling the response

Each API call decodes the response according to the statuses the OpenAPI specification
documents for that endpoint. A documented status — including a documented _error_ status
such as `400` or `429` — returns `{:ok, struct}`, where the struct is the model declared
for it. Match on the struct type to tell success from a documented failure:

```elixir
alias LINE.Bot.MessagingApi.Model.ErrorResponse
alias LINE.Bot.MessagingApi.Model.PushMessageResponse

case MessagingApi.push_message(client, request) do
  {:ok, %PushMessageResponse{} = response} ->
    response.sentMessages

  {:ok, %ErrorResponse{} = error} ->
    Logger.warning("LINE rejected the request: #{error.message} #{inspect(error.details)}")

  {:error, %Req.Response{} = response} ->
    Logger.error("unexpected status #{response.status}: #{inspect(response.body)}")

  {:error, exception} ->
    Logger.error("request failed: #{Exception.message(exception)}")
end
```

Endpoints with an empty body return `{:ok, nil}`. An undocumented status returns
`{:error, %Req.Response{}}`, from which you can read the status, headers and raw body:

```elixir
{:error, response} = MessagingApi.push_message(client, request)

response.status
Req.Response.get_header(response, "x-line-request-id")
```

A transport-level failure returns `{:error, exception}` as raised by Req.

## Testing

Pass `:plug` to `new/1` to serve requests from your own plug instead of the network,
which makes it possible to test bot code without reaching LINE:

```elixir
client =
  LINE.Bot.MessagingApi.new(
    channel_token: "test-channel-token",
    plug: fn conn ->
      Req.Test.json(conn, %{"sentMessages" => []})
    end
  )
```

Alternatively point `:base_url` at a local mock server.

## Development

### Requirements

Working on the SDK itself needs more than working on an app that depends on it, because
the API clients are generated by a custom
[openapi-generator](https://github.com/OpenAPITools/openapi-generator) plugin written in
Java:

- **Elixir 1.18 or later** — the SDK and the `generate-code.exs` script.
- **JDK 18 or later** — the generator plugin targets Java 18, and CI builds it with 21.
- **Apache Maven** — `generate-code.exs` builds the plugin with `mvn package`. A `mvnw`
  wrapper is checked in, but it has no `.mvn/wrapper` configuration and the script calls
  `mvn` directly, so install Maven on your `PATH`.

The OpenAPI specifications come from the [line-openapi](https://github.com/line/line-openapi)
git submodule, so clone with submodules or initialize them afterwards:

```sh
$ git submodule update --init --recursive
```

### Regenerating the clients

The API clients under `lib/gen` are generated and must not be edited by hand — any change
there is lost on the next run. Change the templates and generator code in `generator/`
instead, then regenerate:

```sh
$ elixir generate-code.exs
$ mix compile
$ mix test
```

`generate-code.exs` builds the generator with Maven, deletes `lib/gen`, regenerates every
client from the specs, and runs `mix format` over the result. Commit the regenerated code
together with the `generator/` change: CI regenerates and fails the build if the working
tree comes out dirty.

### Running the test suite

```sh
$ mix deps.get
$ mix test
```

The tests do not reach the network. Each client is exercised against a local mock server
through `LINE.Bot.ClientCase`, which builds a client pointed at it.

## Help and media

FAQ: https://developers.line.biz/en/faq/

News: https://developers.line.biz/en/news/

## Versioning

This project respects [semantic versioning](https://semver.org/).

While the version is below `1.0.0`, minor releases may contain breaking changes as the
generated API surface stabilizes. Notable changes are recorded in the [changelog](https://github.com/wingyplus/line-bot-sdk-elixir/blob/main/CHANGELOG.md).

## Contributing

Issues and pull requests are welcome — see the [issue tracker](https://github.com/wingyplus/line-bot-sdk-elixir/issues).

Before opening a pull request, please read [Development](#development) above. The most
common pitfall is editing `lib/gen` directly: that code is generated, so changes there
belong in `generator/` and must be regenerated and committed together.

## License

```
Copyright 2026 Thanabodee Charoenpiriyakij

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
