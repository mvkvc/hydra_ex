defmodule Hydra do
  @doc """
  The goal of hydra will be to read your configs an create a structured hierarchy that is built based on your selection. My assumption is that most training scripts will take place in a .exs or Livebook file, so the output should be config dict that will be used for training etc..
  """
  @config_folder "examples/yaml/conf"
  @config_name "config.yaml"

  def run do
    load_config(@config_folder, @config_name)
  end

  def load_yaml(folder, filename) do
    Application.start(:yamerl)
    path = folder <> "/" <> filename
    IO.inspect(path)

    base = :yamerl_constr.file(path)
  end

  def load_config(folder, filename, ext \\ ".yaml") do
    base =
      load_yaml(folder, filename)
      |> List.first()
      |> convert()

    {defaults, overrides} = Map.pop!(base, 'defaults')
    # overrides |> IO.inspect(label: "overrides")
    # defaults |> IO.inspect(label: "defaults")

    default_lookup = Map.to_list(defaults)

    IO.inspect(default_lookup, label: "default lookup")

    defaults =
      Enum.reduce(default_lookup, %{}, fn x, acc ->
        key = elem(x, 0) |> IO.inspect()
        value = elem(x, 1) |> IO.inspect()
        path = to_string(key) <> "/" <> to_string(value) <> ext

        result =
          load_yaml(folder, path)
          |> List.first()
          |> convert()

        Map.put(acc, key, result)
      end)

    # {defaults, overrides}
    recursive_merge(defaults, overrides)
  end

  defp recursive_merge(x, y) do
    Map.merge(x, y, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2) do
        recursive_merge(v1, v2)
      else
        v2
      end
    end)
  end

  defp convert(collection) do
    IO.inspect(collection, label: "CONVERT CALLED")

    result =
      Enum.reduce(collection, %{}, fn x, acc ->
        IO.inspect(x, label: "x in func")

        case x do
          [a] when is_tuple(a) ->
            IO.inspect(a, label: "is_tuple in list")
            Map.put(acc, elem(a, 0), elem(a, 1))

          {a, b} when (is_list(b) and not is_binary(b)) or is_tuple(b) ->
            IO.inspect(b, label: "is_list but not binary")
            b = if is_charlist(b), do: b, else: convert(b)
            Map.put(acc, a, b)

          {a, b} ->
            IO.inspect(b, label: "is_tuple")
            Map.put(acc, a, b)

          [a] when is_list(a) and length(a) == 1 ->
            convert(a)

          _ ->
            acc
            # IO.inspect(x, label: "no match")
        end
      end)

    IO.inspect(result)
    result
  end

  def is_charlist(list) do
    Enum.reduce_while(list, true, fn x, acc ->
      cond do
        is_integer(x) -> {:cont, acc}
        true -> {:halt, false}
      end
    end)
  end

  # def overrides(config, overrides) do
  # end
end
