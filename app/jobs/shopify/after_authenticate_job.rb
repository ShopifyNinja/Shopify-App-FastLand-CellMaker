# frozen_string_literal: true

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform(shop_domain:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      if shop.snippets_created == 0
        puts ">>> INFO - authenticate job starting..."

        fonts = %w(
          MyriadPro-Regular.woff
          MyriadPro-Light.woff
          MyriadPro-Bold.woff
          MyriadPro_Regular.woff
          MyriadPro_Light.woff
          MyriadPro_BoldCond.woff
          MyriadPro_Bold.woff
          HelveticaNeueLTStd_HvCn.woff
          HelveticaNeueLTStd_Cn.woff
          HelveticaNeueLTStd_BdCn.woff
          BasicBullets.woff
        )


        shop.with_shopify_session do
          themes = ShopifyAPI::Theme.all
          ac = ActionController::Base.new()
          themes.map do |theme|
            # Create 'fastland-a.liquid' & 'fastland-b.liquid'
            Destination.all.each do |row|
              if row.purpose_type == 0
                # General Purpose
                snippet_string = ac.render_to_string(template: "snippets/fastland", layout: false, locals: { host: ENV["APP_DOMAIN"], destination: row.destination })
              else
                # Special Purpose
                temp_snippet_string = ac.render_to_string(template: "snippets/fastland_special", layout: false, locals: { host: ENV["APP_DOMAIN"], destination: row.destination, content: row.dynamic_html })
                embed_html = "<div id=\"product-description-fastland-" + row.destination + "\"></div>"
                snippet_string = temp_snippet_string.sub! '@--dynamic_html--@', embed_html
              end
              file_name = "snippets/fastland-#{row.destination}.liquid"

              # If file exists, remove it first
              asset_file = ShopifyAPI::Asset.find(file_name, params: { theme_id: theme.id })
              if asset_file.present?
                asset_file.destroy
                puts ">>> ACTION - in theme(#{theme.id}), '#{file_name}' is deleted"
              else
                puts ">>>>> WARNING - in theme(#{theme.id}), '#{file_name}' does not exist."
              end

              # Create liquid file
              ShopifyAPI::Asset.create(key: file_name, value: snippet_string, theme_id: theme.id)
              puts ">>> ACTION - in theme(#{theme.id}), '#{file_name}' file is created"
            end

            # Create fonts
            fonts.each { |font| ShopifyAPI::Asset.create(key: "assets/#{font}", src: "https://cod.ag/fastland/fonts/#{font}", theme_id: theme.id) }
            puts ">>> INFO - in theme(#{theme.id}), fonts assets are created"
          end

          shop.snippets_created = 1
          shop.save
        end

        puts ">>> INFO - authenticate job end"
      end
    end
  end
end
