defmodule AggregateRootTest do
  use ExUnit.Case
  doctest EventSourced.AggregateRoot

  defmodule ExampleAggregateRoot do
    use EventSourced.AggregateRoot, fields: [name: ""]

    defmodule Events.NameAssigned do
      defstruct name: ""
    end

    def assign_name(%ExampleAggregateRoot{} = aggregate, name) do
      aggregate
      |> update(%Events.NameAssigned{name: name})
    end

    def apply(%ExampleAggregateRoot.State{} = state, %Events.NameAssigned{} = name_assigned) do
      %ExampleAggregateRoot.State{state |
        name: name_assigned.name
      }
    end
  end

  test "assigns aggregate fields to state struct" do
    aggregate = ExampleAggregateRoot.new("uuid")

    assert aggregate.state == %ExampleAggregateRoot.State{name: ""}
    assert aggregate.uuid == "uuid"
    assert aggregate.version == 0
    assert length(aggregate.pending_events) == 0
  end

  test "applies event" do
    aggregate =
      ExampleAggregateRoot.new("uuid")
      |> ExampleAggregateRoot.assign_name("Ben")

    assert aggregate.state == %ExampleAggregateRoot.State{name: "Ben"}
    assert aggregate.uuid == "uuid"
    assert aggregate.version == 1
    assert length(aggregate.pending_events) == 1
  end

  test "load from events" do
    aggregate = ExampleAggregateRoot.load("uuid", [ %ExampleAggregateRoot.Events.NameAssigned{name: "Ben"} ])

    assert aggregate.state == %ExampleAggregateRoot.State{name: "Ben"}
    assert aggregate.uuid == "uuid"
    assert aggregate.version == 1
    assert length(aggregate.pending_events) == 0  # pending events should be empty after replaying events
  end
end
