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
