defmodule Shippex.USPS.LabelTest do
  use ExUnit.Case

  describe "domestic" do
    test "priority label generated" do
      shipment = Helper.valid_shipment
      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
      assert length(rate.line_items) == 1
      {:ok, transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
      assert length(transaction.rate.line_items) == 1
    end

    test "priority express label generated" do
      shipment = Helper.valid_shipment
      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      assert length(rate.line_items) == 1
      {:ok, transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
      assert length(transaction.rate.line_items) == 1
    end

    test "insured priority label generated" do
      shipment = Helper.valid_shipment(insurance: 500_00)
      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
      assert length(rate.line_items) > 1
      {:ok, transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
      assert length(transaction.rate.line_items) > 1
    end

    test "insured priority express label generated" do
      shipment = Helper.valid_shipment(insurance: 500_00)
      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      assert length(rate.line_items) > 1
      {:ok, transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
      assert length(transaction.rate.line_items) > 1
    end
  end

  describe "canada" do
    test "priority label generated for canada" do
      shipment = Helper.valid_shipment(to: "CA")

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end

    test "priority express label generated for canada" do
      shipment = Helper.valid_shipment(to: "CA")

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end

    test "insured priority label generated for canada" do
      shipment = Helper.valid_shipment(to: "CA", insurance: 500_00)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end

    test "insured priority express label generated for canada" do
      shipment = Helper.valid_shipment(to: "CA", insurance: 500_00)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end
  end

  describe "mexico" do
    test "priority label generated for mexico" do
      shipment = Helper.valid_shipment(to: "MX", insurance: nil)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end

    test "priority express label generated for mexico" do
      shipment = Helper.valid_shipment(to: "MX", insurance: nil)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end

    test "insured priority label generated for mexico" do
      shipment = Helper.valid_shipment(to: "MX", insurance: 500_00)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end

    test "insured priority express label generated for mexico" do
      shipment = Helper.valid_shipment(to: "MX", insurance: 500_00)

      {:ok, rate} = Shippex.Carrier.USPS.fetch_rate(shipment, :usps_priority_express)
      {:ok, _transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)
    end
  end
end
