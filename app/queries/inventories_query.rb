class InventoriesQuery < ApplicationService
  include InventoriesQueryHelpers

  SALE_STOP_FILTER_QUERY = <<~SQL.freeze
    WHERE sources_inventories.sale_stop IS TRUE
      AND ota_accounts.active IS TRUE
      AND sources_shops.shop_id IS NOT NULL
      AND sources_car_classes.car_class_id IS NOT NULL
  SQL

  param :shop
  param :car_classes

  option :ota_ids, default: -> { shop.organization.ota_ids }
  option :start_date
  option :end_date

  def call
    scope = initial_scope
    scope = add_select(scope)
    add_joins(scope)
  end

  private

  def initial_scope
    Inventory.select(:id, :shop_inventory_limit, :shared_inventory_limit, :blocked_inventory)
  end

  def add_select(scope)
    scope.select(<<~SQL)
      si.car_class_id,
      si.shop_id,
      si.date,
      si.sale_stop_ota_ids,
      si.booked_inventories_by_ota
    SQL
  end

  def add_joins(scope)
    scope.joins(<<~SQL)
      RIGHT JOIN (#{subquery}) AS si
        ON si.shop_id = inventories.shop_id
        AND si.car_class_id = inventories.car_class_id
        AND si.date = inventories.date
    SQL
  end

  def subquery
    scope = filtered_scope
    scope = add_select_subquery(scope)
    scope = add_select_sale_stop(scope)
    scope = add_select_booked_inventories(scope)
    scope = add_filter_by_inventory_type(scope)
    scope = add_grouping(scope)
    scope = add_ordering(scope)
    scope.to_sql
  end

  def filtered_scope
    Sources::Inventory.joins(:sources_shop, :sources_car_class, :ota_account)
                      .left_joins(:sources_inventory_type)
                      .where.not(export_status: %i[failed notified], external_id: nil)
                      .where(ota_accounts: { deleted: false })
                      .where(sources_shops: { shop_id: shop.id })
                      .where(sources_car_classes: { car_class_id: car_classes })
                      .where(ota_id: ota_ids)
                      .by_date(start_date..end_date)
  end

  def add_select_subquery(scope)
    scope.select(<<~SQL)
      sources_car_classes.car_class_id,
      sources_shops.shop_id,
      sources_inventories.date,
      SUM(sources_inventories.booked_inventory) AS booked_inventory
    SQL
  end

  def add_grouping(scope)
    scope.group("sources_inventories.date", "sources_shops.shop_id", "sources_car_classes.car_class_id")
  end

  def add_select_booked_inventories(scope)
    scope.select(<<~SQL)
      COALESCE(
        JSONB_OBJECT_AGG(sources_inventories.ota_id, sources_inventories.booked_inventory),
        '{}'::JSONB
      ) AS booked_inventories_by_ota
    SQL
  end

  def add_select_sale_stop(scope)
    scope.select(<<~SQL)
      ARRAY_AGG(sources_inventories.ota_id) FILTER (#{SALE_STOP_FILTER_QUERY}) AS sale_stop_ota_ids
    SQL
  end

  def add_ordering(scope)
    scope.order(date: :asc)
  end
end
