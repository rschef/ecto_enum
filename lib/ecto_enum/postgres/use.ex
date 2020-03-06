defmodule EctoEnum.Postgres.Use do
  @moduledoc false

  alias EctoEnum.Postgres.Use, as: PostgresUse
  alias EctoEnum.Typespec

  defmacro __using__(input) do
    quote bind_quoted: [input: input] do
      typespec = Typespec.make(input[:enums])

      @behaviour Ecto.Type

      @type t :: unquote(typespec)

      enums = input[:enums]
      atom_enums = Enum.map(enums, &PostgresUse.to_atom/1)
      string_enums = Enum.map(enums, &to_string/1)
      valid_values = atom_enums ++ string_enums

      for enum <- enums do
        string = to_string(enum)
        atom = PostgresUse.to_atom(string)

        def cast(unquote(atom)), do: {:ok, unquote(enum)}
        def cast(unquote(string)), do: {:ok, unquote(enum)}

        def dump(unquote(atom)), do: {:ok, unquote(string)}
        def dump(unquote(string)), do: {:ok, unquote(string)}

        def load(unquote(atom)), do: {:ok, unquote(enum)}
        def load(unquote(string)), do: {:ok, unquote(enum)}
      end

      def cast(_other), do: :error

      def dump(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
            "Valid enums are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

      def load(_other), do: :error

      def embed_as(_), do: :self

      def equal?(term1, term2), do: term1 == term2

      def valid_value?(value) do
        Enum.member?(unquote(valid_values), value)
      end

      # # Reflection
      def __enums__(), do: unquote(enums)
      def __enum_map__(), do: __enums__()
      def __valid_values__(), do: unquote(valid_values)

      default_schema = "public"
      schema = Keyword.get(input, :schema, default_schema)
      type = :"#{schema}.#{input[:type]}"

      def type, do: unquote(type)
      def schemaless_type, do: unquote(input[:type])

      def schema, do: unquote(schema)

      types = Enum.map_join(enums, ", ", &"'#{&1}'")
      create_sql = "CREATE TYPE #{type} AS ENUM (#{types})"
      drop_sql = "DROP TYPE #{type}"

      Code.ensure_loaded(Ecto.Migration)

      if function_exported?(Ecto.Migration, :execute, 2) do
        def create_type() do
          Ecto.Migration.execute(unquote(create_sql), unquote(drop_sql))
        end
      else
        def create_type() do
          Ecto.Migration.execute(unquote(create_sql))
        end
      end

      def drop_type() do
        Ecto.Migration.execute(unquote(drop_sql))
      end
    end
  end

  def to_atom(atom) when is_atom(atom), do: atom
  def to_atom(string) when is_binary(string), do: String.to_atom(string)
end
