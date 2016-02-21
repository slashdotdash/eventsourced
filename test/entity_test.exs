defmodule EntityTest do
  use ExUnit.Case
  doctest DomainModel.Entity

  defmodule ExampleEntity do
    use DomainModel.Entity, fields: [name: ""]

    defmodule Events.NameAssigned do
      defstruct name: ""
    end

    def assign_name(%ExampleEntity{} = entity, name) do
      entity
      |> apply(%Events.NameAssigned{name: name})
    end

    def apply(%ExampleEntity{} = entity, %Events.NameAssigned{} = name_assigned) do
      apply_event(entity, name_assigned, fn state -> %{state | name: name_assigned.name} end)
    end
  end

  test "assigns entity fields to state struct" do
    entity = ExampleEntity.new("id")

    assert entity.state == %ExampleEntity.State{name: ""}
  end

  test "applies event" do
    entity = ExampleEntity.new("id")
    |> ExampleEntity.assign_name("Ben")

    assert entity.state == %ExampleEntity.State{name: "Ben"}
    assert entity.version == 1
    assert length(entity.events) == 1
  end

  test "load from events" do
    entity = ExampleEntity.load("id", [
      %ExampleEntity.Events.NameAssigned{name: "Ben"}
    ])

    assert entity.state == %ExampleEntity.State{name: "Ben"}
    assert entity.version == 1
    assert length(entity.events) == 1
  end
end
