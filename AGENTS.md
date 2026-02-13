## Components

The SDK have 3 main components:

- `generator` - Tool generate the the SDK code from @./line-openapi. The code will generate to @./lib/gen directory. It's override the [openapi-generator](https://github.com/OpenAPITools/openapi-generator), written in Java.
- `line-openapi` - The OpenAPI specification from LINE Official.
- SDK - Living in the root of repository.

## Guidelines

- Do not modify @./lib/gen directly, modify code in @./generator and generate with `elixir generate-code.exs` instead.
- Make sure code can be compile with `mix compile`
