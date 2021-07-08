class Api::V1::DoublePricesController < ApiApplicationController
  include Dry::Monads[:result]

  before_action :authenticate_user!

  def index
    result = Loyalty::Manzana::DoublePrices.call(user: current_user, shop: shop)

    case result
    when Success
      @double_price_products = result.value!
      @double_price_products = @double_price_products.page(page).per(per_page)
    when Failure
      respond_with_error(result.failure)
    end
  end

  private

  def shop
    @shop ||= Shop.actual.find(params.require(:shop_id))
  end

  def per_page
    params[:count] || MAX_PRODUCTS_PER_PAGE
  end
end
