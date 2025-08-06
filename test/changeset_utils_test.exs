defmodule ChangesetUtilsTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias ChangesetUtils

  describe "replace_sanitized/3" do
    test "replaces all chars not matching the given regex" do
      given = Changeset.change({%{}, test: :string}, %{test: "abc123"})

      actual = ChangesetUtils.replace_sanitized(given, :test, ~r"[ab12]")

      assert Changeset.fetch_change!(actual, :test) == "ab_12_"
    end

    test "does not replace a field not having a change" do
      given = Changeset.change({%{field: "cat"}, test: :string}, %{test: "abc123"})

      actual = ChangesetUtils.replace_sanitized(given, :field, ~r"[at]")

      assert Changeset.fetch_field!(actual, :field) == "cat"
      assert Changeset.fetch_change(actual, :field) == :error
    end

    test "does not replace a change if changeset already invalid" do
      given =
        Changeset.change({%{}, test: :string}, %{test: "abc123"})
        |> Changeset.add_error(:test, "error")

      actual = ChangesetUtils.replace_sanitized(given, :test, ~r"[ab12]")

      assert Changeset.fetch_change!(actual, :test) == "abc123"
    end

    test "raises exception if value not binary" do
      given = Changeset.change({%{}, test: :integer}, %{test: 17})

      assert_raise ArgumentError, fn ->
        ChangesetUtils.replace_sanitized(given, :test, ~r"[ab12]")
      end
    end

    test "does nothing if nil provided" do
      given = Changeset.change({%{test: "cat"}, test: :string}, %{test: nil})

      actual = ChangesetUtils.replace_sanitized(given, :test, ~r"[at]")

      assert Changeset.fetch_field!(actual, :test) == nil
      assert Changeset.fetch_change!(actual, :test) == nil
    end
  end

  describe "validate_allowed_chars/3" do
    test "is valid if each char matches the given regex" do
      given_changeset = Changeset.change({%{}, test: :string}, %{test: "17"})
      given_regex = ~r"[0-9]"

      actual = ChangesetUtils.validate_chars(given_changeset, :test, given_regex)

      assert actual.valid?
    end

    test "is not valid if at least one char does not match the given regex" do
      given_changeset = Changeset.change({%{}, test: :string}, %{test: "17a"})
      given_regex = ~r"[0-9]"

      actual = ChangesetUtils.validate_chars(given_changeset, :test, given_regex)

      refute actual.valid?
      assert actual.errors == [{:test, {"has invalid format", []}}]
    end

    test "raises exception if value not binary" do
      given_changeset = Changeset.change({%{}, test: :integer}, %{test: 17})
      given_regex = ~r"[0-9]"

      assert_raise ArgumentError, fn ->
        ChangesetUtils.validate_chars(given_changeset, :test, given_regex)
      end
    end

    test "adds error only if not already present for field" do
      given_changeset = Changeset.change({%{}, test: :string}, %{test: "17a"})
      given_regex = ~r"[0-9]"

      actual =
        given_changeset
        |> ChangesetUtils.validate_chars(:test, given_regex)
        |> ChangesetUtils.validate_chars(:test, given_regex)

      assert actual.errors == [{:test, {"has invalid format", []}}]
    end
  end

  describe "validate_uuid/2" do
    test "is valid if field is a UUID" do
      given_changeset = Changeset.change({%{}, test: :binary_id}, %{test: Ecto.UUID.generate()})

      actual = ChangesetUtils.validate_uuid(given_changeset, :test)

      assert actual.valid?
    end

    test "is not valid if field is not a UUID" do
      given_changeset = Changeset.change({%{}, test: :string}, %{test: "abcdefg-1234567"})

      actual = ChangesetUtils.validate_uuid(given_changeset, :test)

      refute actual.valid?
      assert actual.errors == [{:test, {"has invalid format", []}}]
    end

    test "raises exception if value not binary" do
      given_changeset = Changeset.change({%{}, test: :integer}, %{test: 17})

      assert_raise ArgumentError, fn ->
        ChangesetUtils.validate_uuid(given_changeset, :test)
      end
    end

    test "adds error only if not already present for field" do
      given_changeset = Changeset.change({%{}, test: :string}, %{test: "17a"})

      actual =
        given_changeset
        |> ChangesetUtils.validate_uuid(:test)
        |> ChangesetUtils.validate_uuid(:test)

      assert actual.errors == [{:test, {"has invalid format", []}}]
    end
  end
end
