defmodule SpecialtiesViaMacro do
  import Memoizer

  memoize specialties() do
    ["Specialty Three", "Specialty Four"]
  end

end
