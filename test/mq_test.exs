defmodule MqTest do
  use ExUnit.Case
  doctest Mq

  test "greets the world" do
    assert Mq.hello() == :world
  end
end
