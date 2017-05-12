In Ruby we might have something like this:

```ruby
module Specialties
  def self.specialties
    @specialties ||= ["Specialty One", "Specialty Two"]
  end
end
```

And we could call this from anywhere in the application:

```ruby
def valid_specialty?(specialty)
  specialty.in?(Specialties.specialties)
end
```

In Elixir, we can have a `Specialties` module, but we can't memoize data:

```elixir
defmodule Specialties do
  def specialties
    ["Specialty One", "Specialty Two"]
   end
end

```

This is a problem if the data comes from some expensive operation (like loading and parsing a file, for example)

We can use something like an `Agent` to hold this state, and we could definitely start the `Agent` in a supervisor, but this feels like a lot of overhead just to get simple memoization. From the perspective of the "consuming" code, it just wants to call `Specialties.specialties`, and from the perspective of the `Specialties` module, it really only cares about how to get the actual specialties, not how to memoize them in an `Agent`.

We _could_ make a Specialties module that knows how to memoize the data in an `Agent` lazily (i.e. without a supervisor starting it up in advance) like this:

```elixir
defmodule Specialties do

  defp load_specialties do
    ["Specialty One", "Specialty Two"]
  end

  defp start_link do
    Agent.start_link(fn -> nil end, name: :specialties)
  end

  defp get_and_set_specialties do
    data = load_specialties()
    Agent.update(:specialties, fn _ -> data end)
    data
  end

  def specialties do
    start_link()
    Agent.get(:specialties, fn state -> state end) || get_and_set_specialties()
  end

end
```

However, only the first function is actually interesting --- the last 3 functions are just boilerplate to deal with the `Agent` stuff and memoization. We could extract this boilerplate into a macro like this:

```Elixir
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
```

And then use it like this:

```elixir
defmodule SpecialtiesViaMacro do
  import Memoizer

  memoize specialties() do
    ["Specialty Three", "Specialty Four"]
  end

end
```

Of course, in a multi-process environment, two processes could call `Specialties.specialties` at the same time, and they both might end up running the expensive calculation (which is true in the Ruby version too), but for quick and dirty memoization, especially for single-process Elixir code, this seems a lot simpler than always building an `Agent` and supervising it.

As a newbie to Elixir, I'm probably missing something here, so I probably won't _actually_ use this approach, but I wanted to at least document the concept.
