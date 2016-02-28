defmodule BankAccountTest do
  use ExUnit.Case

  alias BankAccount.Events.{BankAccountOpened,MoneyDeposited,MoneyWithdrawn}

  test "open account" do
    account = BankAccount.new("123")
      |> BankAccount.open_account("ACC123", 100)

    assert account.id == "123"
    assert account.events == [%BankAccountOpened{account_number: "ACC123", initial_balance: 100}]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 100}
    assert account.version == 1
  end

  test "deposit money" do
    account = BankAccount.new("123")
      |> BankAccount.open_account("ACC123", 100)
      |> BankAccount.deposit(50)

    assert Enum.reverse(account.events) == [
      %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
      %MoneyDeposited{amount: 50, balance: 150}
    ]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 150}
    assert account.version == 2
  end

  test "withdraw money" do
    account = BankAccount.new("123")
      |> BankAccount.open_account("ACC123", 100)
      |> BankAccount.withdraw(50)

    assert Enum.reverse(account.events) == [
      %BankAccountOpened{account_number: "ACC123", initial_balance: 100},
      %MoneyWithdrawn{amount: 50, balance: 50}
    ]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 50}
    assert account.version == 2
  end

  test "load from events" do
    events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 100}]
    account = BankAccount.load("1234", events)

    assert account.id == "1234"
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 100}
    assert length(account.events) == 1
    assert account.version == 1
  end
end
