# frozen_string_literal: true

module FastLand
  module Shopify
    class Variables
      class << self
        # Variables for collections query
        def collections(num_collections:, cursor_product: nil, collection_sort_key: "ID")
          variables = {
            num_collections: num_collections,
            collection_sort_key: collection_sort_key
          }
          cursor_product.present? && variables[:cursor_product] = cursor_product
          variables
        end

        # Variables for products query
        def products(num_products:, cursor: nil, query: nil)
          variables = {
            num_products: num_products
          }
          cursor.present? && variables[:cursor] = cursor
          query.present? && variables[:query] = query
          variables
        end

        # Variables for products query
        def product_by_handle(handle:, num_collections: nil, cursor_collection: nil)
          variables = {
            handle: handle
          }
          num_collections.present? && variables[:num_collections] = num_collections
          cursor_collection.present? && variables[:cursor_collection] = cursor_collection
          variables
        end

        # Variables for collectionByHandle query
        def collection_by_handle(handle:, num_products: nil, cursor: nil)
          variables = {
            handle: handle
          }
          num_products.present? && variables[:num_products] = num_products
          cursor.present? && variables[:cursor] = cursor
          variables
        end

        # Variables for product tags
        def product_tags(num_tags:, cursor: nil)
          variables = {
            num_tags: num_tags
          }
          variables[:cursor] = cursor if cursor.present?
          variables
        end

        # Variables for product vendors
        def product_vendors(num_vendors:, cursor: nil)
          variables = {
            num_vendors: num_vendors
          }
          variables[:cursor] = cursor if cursor.present?
          variables
        end

        # Variables for products with tags
        def product_with_tags(num_products:, cursor: nil)
          variables = {
            num_products: num_products
          }
          cursor.present? && variables[:cursor] = cursor
          variables
        end
      end
    end
  end
end
