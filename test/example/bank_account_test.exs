defmodule BankAccountTest do
  use ExUnit.Case

  alias BankAccount.Events.{BankAccountOpened,MoneyDeposited,MoneyWithdrawn}

  test "open account" do
    account =
      with account <- BankAccount.new("123"),
        {:ok, account} <- BankAccount.open_account(account, "ACC123", 100),
      do: account

    assert account.uuid == "123"
    assert account.pending_events == [
      %BankAccountOpened{account_number: "ACC123", initial_balance: 100}
    ]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 100}
    assert account.version == 1
  end

  test "deposit money" do
    account =
      with account <- BankAccount.new("123"),
        {:ok, account} <- BankAccount.open_account(account, "ACC123", 100),
        {:ok, account} <- BankAccount.deposit(account, 50),
      do: account

    assert account.pending_events == [
      %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
      %MoneyDeposited{amount: 50, balance: 150}
    ]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 150}
    assert account.version == 2
  end

  test "withdraw money" do
    account =
      with account <- BankAccount.new("123"),
        {:ok, account} <- BankAccount.open_account(account, "ACC123", 100),
        {:ok, account} <- BankAccount.deposit(account, 50),
        {:ok, account} <- BankAccount.withdraw(account, 25),
      do: account

    assert account.pending_events == [
      %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
      %MoneyDeposited{amount: 50, balance: 150},
      %MoneyWithdrawn{amount: 25, balance: 125}
    ]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 125}
    assert account.version == 3
  end

  test "load from events" do
    events = [
      %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
      %MoneyDeposited{amount: 50, balance: 150}
    ]
    account = BankAccount.load("1234", events)

    assert account.uuid == "1234"
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 150}
    assert length(account.pending_events) == 0
    assert account.version == 2
  end
end
