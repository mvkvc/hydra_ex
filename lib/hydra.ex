defmodule Hydra do
  @doc """
  The goal of hydra will be to read your configs an create a structured hierarchy that is built based on your selection. My assumption is that most training scripts will take place in a .exs or Livebook file, so the output should be config dict that will be used for training etc..
  """
  @config_folder "examples/yaml/conf"
  @config_name "config"

  def run do
    load_config(@config_folder, @config_name)
  end

  def load_yaml(folder, filename, ext \\ ".yaml") do
    Application.start(:yamerl)
    path = folder <> "/" <> filename <> ext
    IO.inspect(path)

    base = :yamerl_constr.file(path)
  end

  def load_config(folder, filename) do
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
        key = elem(x, 0) |> to_string()
        value = elem(x, 1) |> to_string()
        path = key <> "/" <> value

        {key, value, path} |> IO.inspect(label: "defaults values")

        # result =
        #   load_yaml(folder, path)
        #   |> List.first()
        #   |> convert()

        # IO.inspect({key, value, result}, label: "input to base builder")
        IO.inspect({@config_folder, key, value}, label: "bb folder, key, val")
        result = base_builder(@config_folder, key, value)

        # IO.inspect()
        Map.put(acc, to_charlist(key), result)
      end)

    # defaults
    {defaults, overrides} |> IO.inspect(label: "defaults, overrides")
    recursive_merge(defaults, overrides)
  end

  def base_builder(root, folder, file) do
    base_builder(root, folder, file, [])
  end

  def base_builder(root, folder, file, params) do
    {root, folder, file} |> IO.inspect(label: "bb inputs")

    file =
      load_yaml(root <> "/" <> folder, file)
      |> List.first()
      |> convert()

    file |> IO.inspect(label: "base_builders file")

    result =
      if file['base'] do
        new_file = file['base'] |> to_string()
        {_, file} = Map.pop!(file, 'base')
        base_builder(root, folder, new_file, params ++ [file])
      else
        params = params ++ [file]

        Enum.reduce(params, %{}, fn x, acc ->
          params ++ [file]
          IO.inspect({params, acc, x}, label: "resumts merger inspect")
          recursive_merge(acc, x)
        end)
      end

    result |> IO.inspect(label: "base_builders result")
    result
  end

  # def build_maps(maps) do
  #   Enum.reduce(maps, %{}, fn x, acc ->
  #     recursive_merge(acc, x)
  #   end)
  # end

  def recursive_merge(x, y) do
    Map.merge(x, y, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2) do
        recursive_merge(v1, v2)
      else
        v2
      end
    end)
  end

  def convert(collection) do
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
