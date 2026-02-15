# SPDX-License-Identifier: Apache-2.0

defmodule LINE.Bot.Deserializer do
  @moduledoc """
  Helper functions for deserializing responses into models.
  """

  @doc """
  Decode a JSON response body into a struct.

  ## Parameters

  - `response` - The Req.Response struct
  - `module` - The module to decode the response body into (or `false` to skip decoding)

  ## Returns

  - `{:ok, struct}` on success
  - `{:ok, Req.Response.t()}` if module is `false`
  - `{:error, reason}` on failure
  """
  @spec decode(Req.Response.t(), module() | false | %{}) ::
          {:ok, struct() | map() | Req.Response.t()} | {:error, term()}
  def decode(%Req.Response{} = response, false) do
    {:ok, response}
  end

  def decode(%Req.Response{body: body}, %{}) when is_map(body) do
    {:ok, body}
  end

  def decode(%Req.Response{body: body}, module) when is_atom(module) do
    {:ok, to_struct(body, module)}
  end

  @doc """
  Update the provided model with a deserialization of a nested value.
  """
  @spec deserialize(struct(), atom(), :date | :datetime | :list | :map | :struct, module()) ::
          struct()
  def deserialize(model, field, :list, module) do
    model
    |> Map.update!(field, fn
      nil ->
        nil

      list ->
        Enum.map(list, &to_struct(&1, module))
    end)
  end

  def deserialize(model, field, :struct, module) do
    model
    |> Map.update!(field, fn
      nil ->
        nil

      value ->
        to_struct(value, module)
    end)
  end

  def deserialize(model, field, :map, module) do
    maybe_transform_map = fn
      nil ->
        nil

      existing_value ->
        Map.new(existing_value, fn
          {key, value} ->
            {key, to_struct(value, module)}
        end)
    end

    Map.update!(model, field, maybe_transform_map)
  end

  def deserialize(model, field, :date, _) do
    value = Map.get(model, field)

    case is_binary(value) do
      true ->
        case Date.from_iso8601(value) do
          {:ok, date} -> Map.put(model, field, date)
          _ -> model
        end

      false ->
        model
    end
  end

  def deserialize(model, field, :datetime, _) do
    value = Map.get(model, field)

    case is_binary(value) do
      true ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> Map.put(model, field, datetime)
          _ -> model
        end

      false ->
        model
    end
  end

  @doc """
  Decode a map (or list of maps) into a struct of the given module.

  ## Parameters

  - `value` - A map, list of maps, or nil
  - `module` - The module to decode into

  ## Returns

  The decoded struct (or list of structs, or nil).
  """
  @spec decode_map(map() | [map()] | nil, module()) :: struct() | [struct()] | nil
  def decode_map(value, module), do: to_struct(value, module)

  defp to_struct(value, module)
  defp to_struct(nil, _), do: nil

  defp to_struct(list, module) when is_list(list) and is_atom(module) do
    Enum.map(list, &to_struct(&1, module))
  end

  defp to_struct(map, module) when is_map(map) and is_atom(module) do
    model = struct(module)

    model
    |> Map.keys()
    |> List.delete(:__struct__)
    |> Enum.reduce(model, fn field, acc ->
      Map.replace(acc, field, Map.get(map, Atom.to_string(field)))
    end)
    |> module.decode()
  end

  defp to_struct(value, module) when is_atom(module) do
    module.decode(value)
  end

  @doc """
  Evaluate the response from a Req request.

  ## Parameters

  - `result` - The result from Req.request/2
  - `mapping` - A list of `{status_code, module}` tuples for response decoding

  ## Returns

  - `{:ok, struct}` or `{:ok, Req.Response.t()}` on success
  - `{:error, term}` on failure
  """
  @type status_code :: :default | 100..599
  @type response_mapping :: [{status_code, false | %{} | module()}]

  @spec evaluate_response({:ok, Req.Response.t()} | {:error, term()}, response_mapping) ::
          {:ok, struct() | Req.Response.t()} | {:error, Req.Response.t() | term()}
  def evaluate_response({:ok, %Req.Response{} = response}, mapping) do
    resolve_mapping(response, mapping, nil)
  end

  def evaluate_response({:error, _} = error, _), do: error

  defp resolve_mapping(
         %Req.Response{status: status} = response,
         [{mapping_status, struct} | _],
         _
       )
       when status == mapping_status do
    decode(response, struct)
  end

  defp resolve_mapping(response, [{:default, struct} | tail], _) do
    resolve_mapping(response, tail, struct)
  end

  defp resolve_mapping(response, [_ | tail], struct) do
    resolve_mapping(response, tail, struct)
  end

  defp resolve_mapping(response, [], nil), do: {:error, response}

  defp resolve_mapping(response, [], struct), do: decode(response, struct)
end
