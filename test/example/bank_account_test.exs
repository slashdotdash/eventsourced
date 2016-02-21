defmodule BankAccountTest do
  use ExUnit.Case
  doctest DomainModel

  alias BankAccount.Events.BankAccountOpened

  test "open account" do
    account = BankAccount.new
      |> BankAccount.open_account("ACC123", 100)

    assert account.events == [%BankAccountOpened{account_number: "ACC123", initial_balance: 100}]
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 100}
  end

  test "reload from events" do
    events = [%BankAccountOpened{account_number: "ACC123", initial_balance: 100}]
    account = BankAccount.load("1234", events)

    assert account.id == "1234"
    assert account.state == %BankAccount.State{account_number: "ACC123", balance: 100}
    assert length(account.events) == 1
  end
end
