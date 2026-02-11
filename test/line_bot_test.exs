defmodule LINEBotTest do
  use ExUnit.Case
  doctest LINEBot

  test "greets the world" do
    assert LINEBot.hello() == :world
  end
end
