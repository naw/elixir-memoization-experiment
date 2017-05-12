defmodule MoreSpecialtiesViaMacro do
  import Memoizer

  memoize specialties() do
    ["Specialty Five", "Specialty Six"]
  end

end
