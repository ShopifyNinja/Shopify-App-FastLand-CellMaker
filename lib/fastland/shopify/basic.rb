# frozen_string_literal: true

module FastLand
  module Shopify
    class Basic
      class << self
        include FastLand::Constants::Shopify

        def connect
          shop = Shop.find_by_shopify_domain(ENV["SHOPIFY_DOMAIN"])
          shop.connect if shop.present?
        end

        def convert_gid_to_id(type:, gid:)
          return nil if gid.nil?

          case type
          when SHOPIFY_PRODUCT then gid&.sub("gid://shopify/Product/", "")&.to_i
          when SHOPIFY_VARIANT then gid&.sub("gid://shopify/ProductVariant/", "")&.to_i
          else nil
          end
        end

        def convert_id_to_gid(type:, id:)
          return nil if id.nil?

          case type
          when SHOPIFY_PRODUCT then "gid://shopify/Product/#{id}"
          when SHOPIFY_VARIANT then "gid://shopify/ProductVariant/#{id}"
          else nil
          end
        end
      end
    end
  end
end
