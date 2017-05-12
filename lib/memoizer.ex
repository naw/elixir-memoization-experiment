defmodule Memoizer do

  defmacro memoize(description, do: content) do
    quote do
      def load do
        unquote(content)
      end

      defp start_link do
        Agent.start_link(fn -> nil end, name: __MODULE__)
      end

      defp get_and_set do
        data = load()
        Agent.update(__MODULE__, fn _ -> data end)
        data
      end

      def(unquote(description)) do
        start_link()
        Agent.get(__MODULE__, fn state -> state end) || get_and_set()
      end
    end
  end

end
