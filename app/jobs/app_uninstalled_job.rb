# frozen_string_literal: true

class AppUninstalledJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    puts ">>> INFO - app uninstalling starting..."

    shop = Shop.find_by(shopify_domain: shop_domain)

    shop.with_shopify_session do
      themes = ShopifyAPI::Theme.all
      file_names = Destination.all.map { |row| "snippets/fastland-#{row.destination}.liquid" }

      themes.each do |theme|
        file_names.each do |file_name|
          asset_file = ShopifyAPI::Asset.find(file_name, params: { theme_id: theme.id })
          if asset_file.present?
            asset_file.destroy
            puts ">>> ACTION - in theme(#{theme.id}), '#{file_name}' is deleted"
          else
            puts ">>>>> WARNING - in theme(#{theme.id}), '#{file_name}' does not exist."
          end
        end
      end
    end

    shop.destroy

    puts ">>> INFO - app uninstalling end"
  end
end
