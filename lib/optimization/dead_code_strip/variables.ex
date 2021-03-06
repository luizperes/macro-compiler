defmodule MacroCompiler.Optimization.DeadCodeStrip.Variables do
  def validate_variables(symbol_table) do
    variables_read =
      symbol_table
      |> Enum.map(&find_variables_read/1)
      |> List.flatten
      |> MapSet.new
      |> MapSet.delete(nil)

    variables_write =
      symbol_table
      |> Enum.map(&find_variables_write/1)
      |> List.flatten
      |> MapSet.new
      |> MapSet.delete(nil)


    variables_write_never_read = MapSet.difference(variables_write, variables_read)
    variables_write_never_read
  end

  defp find_variables_read(stage) do
    case stage do
      %{macro_write: %{block: block}} ->
        Enum.map(block, &find_variables_read/1)

      %{variable_read: x, variable_name: {name, _metadata}} when is_list(x) ->
        [
          name,
          Enum.map(x, &find_variables_read/1)
        ]

      %{variable_read: x} when is_list(x) ->
        Enum.map(x, &find_variables_read/1)

      x when is_list(x) ->
        Enum.map(x, &find_variables_read/1)

      %{variable_read: x} when is_map(x) ->
        find_variables_read(x)

      %{variable_name: {name, _metadata}} ->
        name

      _ ->
        nil
    end
  end

  defp find_variables_write(stage) do
    case stage do
      %{macro_write: %{block: block}} ->
        Enum.map(block, &find_variables_write/1)

      %{variable_write: x} when is_list(x) ->
        Enum.map(x, &find_variables_write/1)

      x when is_list(x) ->
        Enum.map(x, &find_variables_write/1)

      %{variable_write: x} when is_map(x) ->
        find_variables_write(x)

      %{variable_name: {name, _metadata}} ->
        name

      _ ->
        nil
    end
  end
end
