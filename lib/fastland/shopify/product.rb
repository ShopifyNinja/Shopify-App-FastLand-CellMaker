# frozen_string_literal: true

module FastLand
  module Shopify
    class Product
      class << self
        # Get list of collections
        def get_products_by(variables:)
          query = FastLand::Shopify::Query.products
          result = nil
          while true
            result = ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h.dig("products")
            break if result.present?

            FastLand::Utils::Basic.wait(1)
          end
          result
        end

        # Get product by handle
        def get_product_by_handle(variables:, with_collection: true)
          query = FastLand::Shopify::Query.product_by_handle(with_collection: with_collection)
          ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h.dig("productByHandle")
        end

        # Get product by handle for excel parse
        def get_product_by_handle_name(handle:)
          variables = FastLand::Shopify::Variables.product_by_handle(handle: handle)
          query = FastLand::Shopify::Query.product_by_handle_name()
          ShopifyAPI::GraphQL::client.query(query, variables: variables).data.to_h.dig("productByHandle")
        end

        def get_collection_titles(shopify_product:)
          shopify_collections = shopify_product.dig("node", "collections", "edges")
          collections = shopify_collections.map { |shopify_collecion| shopify_collecion.dig("node", "title") }
          has_more = shopify_product.dig("node", "collections", "pageInfo", "hasNextPage")
          return collections unless has_more

          variables = FastLand::Shopify::Variables.product_by_handle(handle: shopify_product.dig("node", "handle"), num_collections: 10, cursor_collection: shopify_collections.last.dig("cursor"))
          while true
            product = get_product_by_handle(variables: variables)
            collections += product.dig("collections", "edges").map { |shopify_collecion| shopify_collecion.dig("node", "title") }

            # Check if more products exist
            has_more = product.dig("collections", "pageInfo", "hasNextPage")
            break unless has_more
            variables[:cursor_collection] = product.dig("collections", "edges").last.dig("cursor")
          end
          collections
        end

        # Get all products by query
        def get_all_products_by_query(query:)
          puts "product_sync_log: INFO - query: #{query}"
          variables = FastLand::Shopify::Variables.products(num_products: 25, query: "#{query}")
          all_products = []
          while true
            products = get_products_by(variables: variables)
            products.dig("edges").each do |product|
              handle = product.dig("node", "handle")
              # puts "product_sync_log: INFO - handle: #{handle}"
              all_products << handle
            end

            # Check if more products exist
            has_more = products.dig("pageInfo", "hasNextPage")
            break unless has_more
            variables[:cursor] = products.dig("edges").last.dig("cursor")
          end

          all_products
        end

        # Get all products in collection
        def get_all_products_in_collection(collection_handle:)
          puts "product_sync_log: INFO - collection: #{collection_handle}"
          variables = FastLand::Shopify::Variables.collection_by_handle(handle: collection_handle, num_products: 25)
          collection_products = []
          while true
            products = FastLand::Shopify::Collection.get_collection_by_handle(variables: variables)[:products]
            products.dig("edges").each do |product|
              handle = product.dig("node", "handle")
              # puts "product_sync_log: INFO - handle: #{handle}"
              collection_products << handle
            end

            # Check if more products exist
            has_more = products.dig("pageInfo", "hasNextPage")
            break unless has_more
            variables[:cursor] = products.dig("edges").last.dig("cursor")
          end

          collection_products
        end

        # Get all products by tag
        def get_all_products_by_tag(tag:)
          tag = tag.sub(/'/, %q(\\\'))
          get_all_products_by_query(query: "tag:'#{tag}'")
        end

        # Get all products by vendor
        def get_all_products_by_vendor(vendor:)
          vendor = vendor.sub(/'/, %q(\\\'))
          get_all_products_by_query(query: "vendor:'#{vendor}'")
        end

        # Get all products by virtual handle
        def get_all_products_by_vh(vh:)
          query = ""
          case vh.exp1_type
          when 0
            query += "tag:\"#{vh.exp1_value}\""
          when 1
            query += "tag:\"#{vh.exp1_value}\""
          when 2
            query += "vendor:\"#{vh.exp1_value}\""
          when 3
            query += "product_type:\"#{vh.exp1_value}\""
          end

          if vh.condition == 0
            query += " AND "
          else
            query += " OR "
          end

          case vh.exp2_type
          when 0
            query += "tag:\"#{vh.exp2_value}\""
          when 1
            query += "tag:\"#{vh.exp2_value}\""
          when 2
            query += "vendor:\"#{vh.exp2_value}\""
          when 3
            query += "product_type:\"#{vh.exp2_value}\""
          end

          get_all_products_by_query(query: query)
        end

        def vendor_not_exists(vendor:)
          products = get_all_products_by_vendor(vendor: vendor)
          products.length == 0
        end

        # Check if product handle exists
        def product_handle_exists?(handle:)
          variables = FastLand::Shopify::Variables.product_by_handle(handle: handle)
          product = ShopifyAPIRetry.retry(2) { get_product_by_handle(variables: variables, with_collection: false) }
          product.present?
        end
      end
    end
  end
end
