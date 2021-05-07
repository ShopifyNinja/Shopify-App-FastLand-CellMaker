# frozen_string_literal: true

module FastLand
  module Shopify
    class Collection
      class << self
        # Get list of collections
        def get_collections_by(variables:)
          query = FastLand::Shopify::Query.collections
          ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h.dig("collections")
        end

        # Get all collections
        def get_all_collections
          variables = FastLand::Shopify::Variables.collections(num_collections: 25)
          all_collections = []
          while true
            collections = get_collections_by(variables: variables)
            all_collections += collections["edges"]

            # Check if more products exist
            has_more = collections.dig("pageInfo", "hasNextPage")
            break unless has_more
            variables[:cursor] = collections.dig("edges").last.dig("cursor")
          end

          all_collections
        end

        # Get collection by handle
        def get_collection_by_handle(variables:, with_products: true)
          query = FastLand::Shopify::Query.collection_by_handle(with_products: with_products)

          if with_products
            result = nil
            while true
              result = ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h.dig("collectionByHandle")
              break if result.present?

              FastLand::Utils::Basic.wait(time: 1)
            end

            { products: result&.dig("products") }
          else
            ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h.dig("collectionByHandle")
          end
        end

        # Check if collection handle exists
        def collection_handle_exists?(handle:)
          variables = FastLand::Shopify::Variables.collection_by_handle(handle: handle)
          collection = ShopifyAPIRetry.retry(2) { get_collection_by_handle(variables: variables, with_products: false) }
          collection.present?
        end
      end
    end
  end
end
