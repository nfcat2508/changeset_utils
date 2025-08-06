defmodule ChangesetUtils do
  @moduledoc """
  A collection of utility functions when working with Ecto.Changeset
  """

  import Ecto.Changeset

  @doc """
  Replaces each char in a change not having the given format with an underscore.

  The format has to be expressed as a regular expression.

  ## Examples

      replace_sanitized(changeset, :nickname, ~r/[:alnum:]-_/)

  """
  def replace_sanitized(changeset, field, regex) do
    with true <- changeset.valid?,
         {:ok, value} when value != nil <- fetch_change(changeset, field) do
      unless is_binary(value) do
        raise ArgumentError,
              "replace_santized/3 expects changes to be strings, received: #{inspect(value)} for field `#{field}`"
      end

      value
      |> String.graphemes()
      |> Enum.map_join(&matching_or_default(&1, regex, "_"))
      |> (&put_change(changeset, field, &1)).()
    else
      _ -> changeset
    end
  end

  @doc """
  Validates each char in a change matches a given format.

  The format has to be expressed as a regular expression.

  ## Examples

      validate_chars(changeset, :tag, ~r/[a-z0-9@]/)

  """
  def validate_chars(changeset, field, regex) do
    validate_change(changeset, field, fn ^field, value ->
      unless is_binary(value) do
        raise ArgumentError,
              "validate_chars/3 expects changes to be strings, received: #{inspect(value)} for field `#{field}`"
      end

      if is_nil(changeset.errors[field]) && !all_chars_matching?(value, regex) do
        [{field, "has invalid format"}]
      else
        []
      end
    end)
  end

  @doc """
  Validates a change is a UUID

  ## Examples

      validate_uuid(changeset, :my_id)

  """
  def validate_uuid(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      unless is_binary(value) do
        raise ArgumentError,
              "validate_uuid/2 expects changes to be strings, received: #{inspect(value)} for field `#{field}`"
      end

      if is_nil(changeset.errors[field]) && Ecto.UUID.cast(value) == :error do
        [{field, "has invalid format"}]
      else
        []
      end
    end)
  end

  defp all_chars_matching?(string, regex) do
    string
    |> String.graphemes()
    |> Enum.all?(&String.match?(&1, regex))
  end

  defp matching_or_default(string, regex, default) do
    if String.match?(string, regex) do
      string
    else
      default
    end
  end
end
