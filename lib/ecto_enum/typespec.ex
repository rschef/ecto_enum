defmodule EctoEnum.Typespec do
  @moduledoc "Helper for generating enum typespecs"

  def make(enums) do
    enums
    |> Enum.reverse()
    |> Enum.reduce(fn
      a, acc when is_atom(a) or is_binary(a) -> add_type(a, acc)
      {a, _}, acc when is_atom(a) -> add_type(a, acc)
      _, acc -> acc
    end)
  end

  defp add_type(type, acc), do: {:|, [], [to_atom(type), to_atom(acc)]}

  defp to_atom(term) when is_atom(term) or is_tuple(term), do: term
  defp to_atom(string) when is_binary(string), do: String.to_atom(string)
end

defmodule EctoEnum.Typespec.TestModule do
  @moduledoc """
  Sample enum-containing module for testing type generation. Types aren't
  generated for dynamically generated modules that eunit uses, so we have to
  prepare this module in advance
  """

  import EctoEnum

  defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3

  defenum PGStatusEnum, :status, [:registered, :active, :inactive, :archived]

  defenum PGRoleEnum, :role, ["user", "manager", "admin"]
end
