defmodule ExShip.Country do

  def country(%{country: code}) do
    country(code)
  end

  def country("AX"), do: "Aland Island"
  def country("BA"), do: "Bosnia-Herzegovina"
  def country("BQ"), do: "Bonaire"
  def country("CC"), do: "Cocos Island"
  def country("CI"), do: "Ivory Coast"
  def country("CV"), do: "Cape Verde"
  def country("CZ"), do: "Czech Republic"
  def country("KR"), do: "South Korea"
  def country("KP"), do: "North Korea"
  def country("MM"), do: "Burma"
  def country("RU"), do: "Russia"
  def country("SH"), do: "Saint Helena"
  def country("SY"), do: "Syria"
  def country("VA"), do: "Vatican City"
  def country("TZ"), do: "Tanzania"
  def country("WF"), do: "Wallis and Futuna Islands"

  def country(code) do
    ISO.country_name(code, :informal)
  end
 end