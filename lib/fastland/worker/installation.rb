# frozen_string_literal: true

require "shopify_api_retry"

module FastLand
  module Worker
    class Installation
      include Sidekiq::Worker
      include Sidekiq::Status::Worker
      sidekiq_options queue: :installation2, retry: false

      def perform(domain, new_shopify_theme_ids, deactive_shopify_theme_ids)
        puts "> INFO - installtion JOB starting..."
        puts "> INFO - domain: #{domain}"

        ShopifyAPI::Base.clear_session
        shop = Shop.find_by_shopify_domain(domain)
        shop.connect

        # Get all destinations
        destinations = Destination.all
        # Active themes
        new_shopify_theme_ids.map { |shopify_theme_id| update_theme(destinations, shopify_theme_id, true) }
        # Deactive thems
        deactive_shopify_theme_ids.map { |shopify_theme_id| update_theme(destinations, shopify_theme_id, false) }

        puts "> INFO - installation JOB end"
      end

      def update_theme(destinations, shopify_theme_id, active)
        puts "> INFO - theme(#{shopify_theme_id}) #{active ? "activating..." : "deactivating"}"
        theme = ShopifyAPIRetry.retry(2) { ShopifyAPI::Theme.find(shopify_theme_id) }
        ac = ActionController::Base.new()
        # Create 'fastland-a.liquid' & 'fastland-b.liquid'
        destinations.each do |row|
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
          ShopifyAPIRetry.retry(2) {
            begin
              asset_file = ShopifyAPI::Asset.find(file_name, params: { theme_id: theme.id })
              # Remove liquid file
              unless active
                if asset_file.present?
                  asset_file.destroy
                  puts ">>> ACTION - '#{file_name}' is deleted"
                else
                  puts ">>>>> WARNING - '#{file_name}' does not exist."
                end
              end
            rescue ActiveResource::ResourceNotFound
              # puts ">>>>> WARNING - '#{file_name}' does not exist."

              # Create liquid file
              if active
                ShopifyAPI::Asset.create(key: file_name, value: snippet_string, theme_id: theme.id)
                puts ">>> ACTION - '#{file_name}' file is created"
              end
            end
          }
        end

        # Create fonts
        fonts.each do |font|
          file_name = "assets/#{font}"
          ShopifyAPIRetry.retry(2) {
            begin
              asset_file = ShopifyAPI::Asset.find(file_name, params: { theme_id: theme.id })
              # Remove font asset file
              unless active
                asset_file.destroy
                puts ">>> ACTION - '#{file_name}' is deleted"
              end
            rescue ActiveResource::ResourceNotFound
              # puts ">>>>> WARNING - '#{file_name}' does not exist."

              # Create font asset file
              if active
                ShopifyAPI::Asset.create(key: file_name, src: "https://cod.ag/fastland/fonts/#{font}", theme_id: theme.id)
                puts ">>> ACTION - '#{file_name}' file is created"
              end
            end
          }
        end

        # Update install status
        theme_row = Theme.find_by_shopify_theme_id(theme.id)
        theme_row.update({
          shopify_theme_id: theme.id,
          name: theme.name,
          role: theme.role,
          installed: active
        })
      end

      private
        def fonts
          %w(
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
        end
    end
  end
end
