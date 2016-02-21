# Functional Domain Models with Event Sourcing in Elixir

Experiment to build functional, event-sourced domain models.

- Aggregate methods accept the current state and a command, returning the new state (including any applied events).

### Creating a new aggregate and invoking command functions.

```
account = BankAccount.new
  |> BankAccount.open_account("ACC123", 100)
  |> BankAccount.deposit(50)
  |> BankAccount.withdraw(75)
```

### Populating an aggregate from a given list of events.

```
account = BankAccount.load("1234", [
  %BankAccountOpened{account_number: "ACC123", initial_balance: 100}
])
```
