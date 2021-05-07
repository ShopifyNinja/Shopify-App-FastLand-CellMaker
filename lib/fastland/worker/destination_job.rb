# frozen_string_literal: true

require "shopify_api_retry"

module FastLand
  module Worker
    class DestinationJob
      include Sidekiq::Worker
      include Sidekiq::Status::Worker
      sidekiq_options queue: :destination2, retry: false

      def perform(domain, destination_id, method)
        puts "> INFO - destination JOB starting..."
        puts "> INFO - domain: #{domain}"

        ShopifyAPI::Base.clear_session
        shop = Shop.find_by_shopify_domain(domain)
        shop.connect

        update_themes(destination_id, method)
        puts "> INFO - destination JOB ended..."
      end

      def update_themes(destination_id, method)
        case method
        when 0
          # Destination is Added
          themes = Theme.where(installed: 1).select(:shopify_theme_id)
          add_snippets(destination_id, themes)
          add_fonts(themes)
        when 1
          # Destination is Edited
          themes = Theme.where(installed: 1).select(:shopify_theme_id)
          delete_snippets(destination_id, themes)
          add_snippets(destination_id, themes)
        when 2
          # Destination is Deleted
          themes = Theme.select(:shopify_theme_id)
          delete_snippets(destination_id, themes)
          Destination.delete(destination_id)
          #delete_fonts(destination, themes)
        end
      end

      def add_snippets(destination_id, themes)
        destination = Destination.find(destination_id)
        ac = ActionController::Base.new()
        if destination.purpose_type == 0
          # General Purpose
          snippet_string = ac.render_to_string(template: "snippets/fastland", layout: false, locals: { host: ENV["APP_DOMAIN"], destination: destination.destination })
        else
          # Special Purpose
          temp_snippet_string = ac.render_to_string(template: "snippets/fastland_special", layout: false, locals: { host: ENV["APP_DOMAIN"], destination: destination.destination, content: destination.dynamic_html })
          embed_html = "<div id=\"product-description-fastland-" + destination.destination + "\"></div>"
          snippet_string = temp_snippet_string.sub! '@--dynamic_html--@', embed_html
        end
        file_name = "snippets/fastland-#{destination.destination}.liquid"
        themes.each do |theme|
          ShopifyAPI::Asset.create(key: file_name, value: snippet_string, theme_id: theme.shopify_theme_id)
          puts ">>> ACTION - '#{file_name}' file is created"
        end
      end

      def delete_snippets(destination_id, themes)
        destination = Destination.find(destination_id)
        file_name = "snippets/fastland-#{destination.destination}.liquid"
        themes.each do |theme|
          ShopifyAPIRetry.retry(2) {
            begin
              asset_file = ShopifyAPI::Asset.find(file_name, params: { theme_id: theme.shopify_theme_id })
              if asset_file.present?
                asset_file.destroy
                puts ">>> ACTION - '#{file_name}' is deleted"
              else
                puts ">>>>> WARNING - '#{file_name}' does not exist."
              end
            rescue ActiveResource::ResourceNotFound
              puts ">>>>> WARNING - '#{file_name}' does not exist."
            end
          }
        end
      end

      def add_fonts(themes)
        themes.each do |theme|
          fonts.each do |font|
            file_name = "assets/#{font}"
            ShopifyAPI::Asset.create(key: file_name, src: "https://cod.ag/fastland/fonts/#{font}", theme_id: theme.shopify_theme_id)
            puts ">>> ACTION - '#{file_name}' file is created"
          end
        end
      end

      def delete_fonts(themes)
        themes.each do |theme|
          fonts.each do |font|
            ShopifyAPIRetry.retry(2) {
              begin
                file_name = "asset/#{font}"
                asset_file = ShopifyAPI::Asset.find(file_name, params: { theme_id: theme.shopify_theme_id })
                if asset_file.present?
                  asset_file.destroy
                  puts ">>> ACTION - '#{file_name}' is deleted"
                end
              rescue ActiveResource::ResourceNotFound
                puts ">>>>> WARNING - '#{file_name}' does not exist."
              end
            }
          end
        end
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