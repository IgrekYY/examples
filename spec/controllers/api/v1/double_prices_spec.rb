require 'rails_helper'

RSpec.describe Loyalty::Manzana::DoublePrices do
  describe '#call' do
    context 'when there aro no regions in Manzana loyalty in region' do
      it "returns 'no_shop_with_manzana_guid_in_region' error " do
        user = create(:user, discount_card_ean_128_code: nil)
        shop = build_stubbed(:shop)

        result = described_class.call(user: user, shop: shop)

        expect(result.failure).to eq(:no_shop_with_manzana_guid_in_region)
      end
    end

    context 'when user not registered in Manzana' do
      it "returns 'user_not_registered_in_manzana_loyalty' error " do
        region = create(:region)
        user = create(:user, discount_card_ean_128_code: nil)
        shop = create(:shop, region: region, manzana_guid: '1234-1234')

        result = described_class.call(user: user, shop: shop)

        expect(result.failure).to eq(:user_not_registered_in_manzana_loyalty)
      end
    end

    context 'when region not supported by Manzana' do
      it "returns 'region_not_included_in_manzana_loyalty' error " do
        region = create(:region, manzana_guid: '1234-1234')
        user = create(:user, :registered_in_manzana)
        shop = create(:shop, region: region, manzana_guid: '1234-1234')

        result = described_class.call(user: user, shop: shop)

        expect(result.failure).to eq(:region_not_included_in_manzana_loyalty)
      end
    end

    context 'when everything correct' do
      it 'returns list of products' do
        region = create(:region, allow_manzana: true)
        shop = create(:shop, region: region, manzana_guid: '1234-1234')
        user = create(:user, :registered_in_manzana, loyalty_level: create(:loyalty_level))
        gold_erp_id = 'D0000001'
        product1 = create(:product, gold_erp_id: gold_erp_id, offline_prices: { shop.id.to_s => { 'current' => 80.0 } },
                                    stocks: { shop.id.to_s => 3.0 }).tap(&:reload)
        product2 = create(:product, gold_erp_id: 'D123123121', offline_prices: { shop.id.to_s => { 'current' => 80.0 } },
                                    stocks: { shop.id.to_s => 3.0 }).tap(&:reload)
        double_product = create(:double_price_product, gold_erp_id: gold_erp_id, product: product1, shop: shop, price: 40.0)
        shop.update!(product_gold_erp_ids: [product1.gold_erp_id, product2.gold_erp_id])

        result = described_class.call(user: user, shop: shop)

        expect(result.value!).to eq([double_product])
      end
    end
  end
end
