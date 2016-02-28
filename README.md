# Functional Domain Models with Event Sourcing in Elixir

Build functional, event-sourced domain models.

- Aggregate methods accept the current state and a command, returning the new state (including any applied events).
- Aggregate state is rebuilt from events by applying a `reduce` function to these events.

### Creating a new aggregate and invoking command functions

```elixir
account = BankAccount.new("1234")
  |> BankAccount.open_account("ACC123", 100)
  |> BankAccount.deposit(50)
  |> BankAccount.withdraw(75)
```

### Populating an aggregate from a given list of events

```elixir
account = BankAccount.load("1234", [
  %BankAccountOpened{account_number: "ACC123", initial_balance: 100}
])
```

### Event-sourced domain model

State may only be updated by applying an event. This is to allow internal state to be reconstituted by replaying a list of events. `Enum.reduce` the events against the empty state.

For each event the model uses, a corresponding `apply/2` function must exist. It expects to receive the domain model (e.g. `%BankAccount{}`) and event (e.g. `%BankAccount.Events.MoneyDeposited{}`). It delegates to the `apply_event/3` function to update the state, version and by prepending the new event to the list of applied events.

Using the `EventSourced.Entity` macro, the example BankAccount listed above is implemented as follows.

```elixir
defmodule BankAccount do
  use EventSourced.Entity, fields: [account_number: nil, balance: nil]

  defmodule Events do
    defmodule BankAccountOpened do
      defstruct account_number: nil, initial_balance: nil
    end

    defmodule MoneyDeposited do
      defstruct amount: nil, balance: nil
    end

    defmodule MoneyWithdrawn do
      defstruct amount: nil, balance: nil
    end
  end

  alias Events.{BankAccountOpened,MoneyDeposited,MoneyWithdrawn}

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    account 
    |> apply(%BankAccountOpened { account_number: account_number, initial_balance: initial_balance })
  end

  def deposit(%BankAccount{} = account, amount) do
    balance = account.state.balance + amount

    account 
    |> apply(%MoneyDeposited{ amount: amount, balance: balance })
  end

  def withdraw(%BankAccount{} = account, amount) do
    balance = account.state.balance - amount

    account 
    |> apply(%MoneyWithdrawn{ amount: amount, balance: balance })
  end

  defp apply(%BankAccount{} = account, %BankAccountOpened{} = account_opened) do
    apply_event(account, account_opened, fn state -> %{state |
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    } end)
  end

  defp apply(%BankAccount{} = account, %MoneyDeposited{} = money_deposited) do
    apply_event(account, money_deposited, fn state -> %{state |
      balance: money_deposited.balance
    } end)
  end

  defp apply(%BankAccount{} = account, %MoneyWithdrawn{} = money_withdrawn) do
    apply_event(account, money_withdrawn, fn state -> %{state |
      balance: money_withdrawn.balance
    } end)
  end
end
```

The macro expands to the following implementation.

```elixir
defmodule BankAccount do
  import Kernel, except: [apply: 2]

  defstruct id: nil, state: nil, events: [], version: 0

  defmodule State do
    defstruct account_number: nil, balance: nil
  end

  defmodule Events do
    defmodule BankAccountOpened do
      defstruct account_number: nil, initial_balance: nil
    end

    defmodule MoneyDeposited do
      defstruct amount: nil, balance: nil
    end

    defmodule MoneyWithdrawn do
      defstruct amount: nil, balance: nil
    end
  end

  alias Events.{BankAccountOpened,MoneyDeposited,MoneyWithdrawn}

  def new(id) do
    %BankAccount{id: id, state: %BankAccount.State{}}
  end

  def load(id, events) do
    Enum.reduce(events, new(id), &apply(&2, &1))
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    account 
    |> apply(%BankAccountOpened { account_number: account_number, initial_balance: initial_balance })
  end

  def deposit(%BankAccount{} = account, amount) do
    balance = account.state.balance + amount

    account 
    |> apply(%MoneyDeposited{ amount: amount, balance: balance })
  end

  def withdraw(%BankAccount{} = account, amount) do
    balance = account.state.balance - amount

    account 
    |> apply(%MoneyWithdrawn{ amount: amount, balance: balance })
  end

  defp apply(%BankAccount{} = account, %BankAccountOpened{} = account_opened) do
    apply_event(account, account_opened, fn state -> %{state |
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    } end)
  end

  defp apply(%BankAccount{} = account, %MoneyDeposited{} = money_deposited) do
    apply_event(account, money_deposited, fn state -> %{state |
      balance: money_deposited.balance
    } end)
  end

  defp apply(%BankAccount{} = account, %MoneyWithdrawn{} = money_withdrawn) do
    apply_event(account, money_withdrawn, fn state -> %{state |
      balance: money_withdrawn.balance
    } end)
  end

  defp apply_event(%BankAccount{} = account, event, update_state_fn) do
    %BankAccount{account |
      events: [event | account.events],
      state: update_state_fn.(account.state),
      version: account.version + 1
    }
  end
end
```