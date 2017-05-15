# Functional Domain Models with Event Sourcing in Elixir

Build functional, event-sourced domain models.

- Aggregate root public methods accept the current state and a command, returning the new state (including any applied events).
- Aggregate root state is rebuilt from events by applying a `reduce` function, starting from an empty state.

MIT License

[![Build Status](https://travis-ci.org/slashdotdash/eventsourced.svg?branch=master)](https://travis-ci.org/slashdotdash/eventsourced)

### Creating a new aggregate root and invoking command functions

```elixir
account =
  BankAccount.new("1234")
  |> BankAccount.open_account("ACC123", 100)
  |> BankAccount.deposit(50)
  |> BankAccount.withdraw(75)
```

### Populating an aggregate root from a given list of events

```elixir
events = [
  %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
  %MoneyDeposited{amount: 50, balance: 150},
  %MoneyWithdrawn{amount: 75, balance: 75}
]

account = BankAccount.load("1234", events)
```

### Event-sourced domain model

State may only be updated by applying an event. This is to allow internal state to be reconstituted by replaying a list of events. We `Enum.reduce` the events against the empty state.

An `apply/2` function must exist for each event the aggregate root may publish. It expects to receive the aggregate's state (e.g. `%BankAccount.State{}`) and the event (e.g. `%BankAccount.Events.MoneyDeposited{}`). It is responsible for updating the internal state using fields from the event.

Using the `EventSourced.AggregateRoot` macro, the example bank account example listed above is implemented as follows.

```elixir
defmodule BankAccount do
  use EventSourced.AggregateRoot, fields: [account_number: nil, balance: nil]

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
    |> update(%BankAccountOpened{account_number: account_number, initial_balance: initial_balance})
  end

  def deposit(%BankAccount{} = account, amount) when amount > 0 do
    balance = account.state.balance + amount

    account
    |> update(%MoneyDeposited{amount: amount, balance: balance})
  end

  def withdraw(%BankAccount{} = account, amount) when amount > 0 do
    balance = account.state.balance - amount

    account
    |> update(%MoneyWithdrawn{amount: amount, balance: balance})
  end

  # event handling callbacks that mutate state

  def apply(%BankAccount.State{} = state, %BankAccountOpened{} = account_opened) do
    %BankAccount.State{state |
      account_number: account_opened.account_number,
      balance: account_opened.initial_balance
    }
  end

  def apply(%BankAccount.State{} = state, %MoneyDeposited{} = money_deposited) do
    %BankAccount.State{state |
      balance: money_deposited.balance
    }
  end

  def apply(%BankAccount.State{} = state, %MoneyWithdrawn{} = money_withdrawn) do
    %BankAccount.State{state |
      balance: money_withdrawn.balance
    }
  end
end
```

This is an entirely functional event-sourced aggregate root.

### Testing

The domain models can be simply tested by invoking a public command method and verifying the correct event(s) have been applied.

```elixir
test "deposit money" do
  account =
    BankAccount.new("123")
    |> BankAccount.open_account("ACC123", 100)
    |> BankAccount.deposit(50)

  assert account.pending_events == [
    %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
    %MoneyDeposited{amount: 50, balance: 150}
  ]
  assert account.state == %BankAccount.State{account_number: "ACC123", balance: 150}
  assert account.version == 2
end
```

## Handling business rule violations

### Return `:ok` or `:error` tuples

This is the most common and idiomatic Elixir approach to writing functions that may error.

The aggregate root must return either an `{:ok, aggregate}` or `{:error, reason}` tuple from each public API function on success or failure.

```elixir
defmodule BankAccount do
  use EventSourced.AggregateRoot, fields: [account_number: nil, balance: nil]

  # ... event and command definition as above

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance <= 0 do
    {:error, :initial_balance_must_be_above_zero}
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    {:ok, update(account, %BankAccountOpened{account_number: account_number, initial_balance: initial_balance})}
  end
end
```

Following this approach allows strict pattern matching on success and failures. An error indicates a domain business rule violation, such as attempting to open an account with a negative initial balance.

You cannot use the pipeline operator (`|>`) to chain the functions. Use the `with` special form instead. This is demonstrated in the example below.

```elixir
with account <- BankAccount.new("123"),
  {:ok, account} <- BankAccount.open_account(account, "ACC123", 100),
  {:ok, account} <- BankAccount.deposit(account, 50),
do: account
```

### Raise an exception

Prevent the aggregate root function from successfully executing by using one of the following tactics.

- Use guard clauses and pattern matching on functions to prevent invalid invocation.
- Raise an exception when a business rule violation is encountered.

```elixir
defmodule BankAccount do
  use EventSourced.AggregateRoot, fields: [account_number: nil, balance: nil]

  # ... event and command definition as above

  defmodule InvalidOpeningBalanceError do
    defexception message: "initial balance must be above zero"
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance <= 0 do
    raise InvalidOpeningBalanceError
  end

  def open_account(%BankAccount{} = account, account_number, initial_balance) when initial_balance > 0 do
    update(account, %BankAccountOpened{account_number: account_number, initial_balance: initial_balance})
  end
end
```

This allows you to use the pipeline operator (`|>`) to chain functions.

```elixir
account =
  BankAccount.new("123")
  |> BankAccount.open_account("ACC123", 100)
  |> BankAccount.deposit(50)
```
