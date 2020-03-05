defmodule EctoEnum.PostgresTest do
  use ExUnit.Case, async: false

  import EctoEnum
  defenum StatusEnum, :status, [:registered, :active, :inactive, :archived]
  defenum RoleEnum, :role, ["user", "manager", "admin"]

  defmodule User do
    use Ecto.Schema

    schema "users_pg" do
      field(:status, StatusEnum)
      field(:role, RoleEnum)
    end
  end

  alias Ecto.Integration.TestRepo

  test "accepts atom and string on save" do
    user = TestRepo.insert!(%User{status: :registered, role: "user"})
    user = TestRepo.get(User, user.id)
    assert user.status == :registered
    assert user.role == "user"

    user = Ecto.Changeset.change(user, status: :active, role: "admin")
    user = TestRepo.update!(user)
    assert user.status == :active
    assert user.role == "admin"

    user = Ecto.Changeset.change(user, status: "inactive", role: :manager)
    user = TestRepo.update!(user)
    assert user.status == "inactive"
    assert user.role == :manager

    user = TestRepo.get(User, user.id)
    assert user.status == :inactive
    assert user.role == "manager"

    TestRepo.insert!(%User{status: :archived, role: "user"})
    user = TestRepo.get_by(User, status: :archived, role: "user")
    assert user.status == :archived
    assert user.role == "user"
  end

  test "casts binary to atom when enums are atoms" do
    %{errors: errors} = Ecto.Changeset.cast(%User{}, %{"status" => 3}, ~w(status)a)
    error = {:status, {"is invalid", [type: EctoEnum.PostgresTest.StatusEnum, validation: :cast]}}
    assert error in errors

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => "active"}, ~w(status)a)
    assert changes.status == :active

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"status" => :inactive}, ~w(status)a)
    assert changes.status == :inactive
  end

  test "casts atom to binary when enums are strings" do
    %{errors: errors} = Ecto.Changeset.cast(%User{}, %{"role" => 3}, ~w(role)a)
    error = {:role, {"is invalid", [type: EctoEnum.PostgresTest.RoleEnum, validation: :cast]}}
    assert error in errors

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"role" => "manager"}, ~w(role)a)
    assert changes.role == "manager"

    %{changes: changes} = Ecto.Changeset.cast(%User{}, %{"role" => :admin}, ~w(role)a)
    assert changes.role == "admin"
  end

  test "loads enum in type defined in defenum/3" do
    status = :active
    role = "user"
    user = TestRepo.insert!(%User{status: status, role: role})
    user = TestRepo.get!(User, user.id)

    assert user.status === status
    assert user.role === role
  end

  test "raises when input is not in the enum map" do
    error = {:status, {"is invalid", [type: EctoEnum.PostgresTest.StatusEnum, validation: :cast]}}

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => "retroactive"}, ~w(status)a)
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => :retroactive}, ~w(status)a)
    assert error in changeset.errors

    changeset = Ecto.Changeset.cast(%User{}, %{"status" => 4}, ~w(status)a)
    assert error in changeset.errors

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: "retroactive"})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: :retroactive})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: 5})
    end
  end

  test "using EctoEnum.Postgres for defining an Enum module" do
    defmodule NewType do
      use EctoEnum.Postgres, type: :new_type, enums: [:ready, :set, :go]
    end

    assert NewType.cast("ready") == {:ok, :ready}

    defmodule NewStringType do
      use EctoEnum.Postgres, type: :new_type, enums: ["ready", "set", "go"]
    end

    assert NewStringType.cast("ready") == {:ok, "ready"}
  end
end
