defmodule ExShip.USPS.LabelTest do
  use ExUnit.Case

  describe "domestic" do
    test "priority label generated" do
      Helper.valid_shipment()
      |> test_shipment(:usps_priority)
    end

    test "priority express label generated" do
      Helper.valid_shipment()
      |> test_shipment(:usps_priority_express)
    end

    test "insured priority label generated" do
      Helper.valid_shipment(insurance: 500_00)
      |> test_shipment(:usps_priority)
    end

    test "insured priority express label generated" do
      Helper.valid_shipment(insurance: 500_00)
      |> test_shipment(:usps_priority_express)
    end

    test "setting insurance to 0 does not trigger error" do
      shipment = Helper.valid_shipment(insurance: 0)

      {:ok, transaction} = ExShip.Carrier.USPS.create_transaction(shipment, :usps_priority)
      assert length(transaction.rate.line_items) == 1
    end
  end

  describe "canada" do
    test "priority label generated for canada" do
      Helper.valid_shipment(to: "CA")
      |> test_shipment(:usps_priority)
    end

    test "priority express label generated for canada" do
      Helper.valid_shipment(to: "CA")
      |> test_shipment(:usps_priority_express)
    end

    test "insured priority label generated for canada" do
      Helper.valid_shipment(to: "CA", insurance: 500_00)
      |> test_shipment(:usps_priority)
    end

    test "insured priority express label generated for canada" do
      Helper.valid_shipment(to: "CA", insurance: 500_00)
      |> test_shipment(:usps_priority_express)
    end
  end

  describe "mexico" do
    test "priority label generated for mexico" do
      Helper.valid_shipment(to: "MX", insurance: nil)
      |> test_shipment(:usps_priority)
    end

    test "priority express label generated for mexico" do
      Helper.valid_shipment(to: "MX", insurance: nil)
      |> test_shipment(:usps_priority_express)
    end
  end

  describe "south korea" do
    test "priority label generated for south korea" do
      address =
        ExShip.Address.new!(%{
          first_name: "John",
          last_name: "Doe",
          address: "29-11 Hoehyeondong 1(il)-ga",
          city: "Seoul",
          state: "11",
          country: "KR",
          phone: "123-123-1234"
        })

      Helper.valid_shipment(to: address, insurance: nil)
      |> test_shipment(:usps_priority)
    end
  end

  defp test_shipment(shipment, service) do
    expected_line_items = if shipment.package.insurance, do: 2, else: 1
    {:ok, rate} = ExShip.Carrier.USPS.fetch_rate(shipment, service)
    assert length(rate.line_items) == expected_line_items

    {:ok, transaction} = ExShip.Carrier.USPS.create_transaction(shipment, rate.service)
    assert length(transaction.rate.line_items) == expected_line_items
  end
end
