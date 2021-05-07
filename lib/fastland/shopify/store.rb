# frozen_string_literal: true

module FastLand
  module Shopify
    class Store
      class << self
        # Get tags
        # def product_tags(variables:)
        #   query = FastLand::Shopify::Query.product_tags
        #   result = nil
        #   retries = 1
        #   ShopifyAPIRetry.retry(2) {
        #     while retries <= 3
        #       result = ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h&.dig("shop", "productTags")
        #       break if result.present?

        #       retries += 1
        #     end
        #   }

        #   result
        # end

        # Get all tags
        # def all_product_tags
        #   variables = FastLand::Shopify::Variables.product_tags(num_tags: 250)
        #   all_tags = []
        #   while true
        #     tags = product_tags(variables: variables)
        #     all_tags += tags["edges"].map { |tag| tag.dig("node") }

        #     # Check if more products exist
        #     has_more = tags.dig("pageInfo", "hasNextPage")
        #     break unless has_more
        #     variables[:cursor] = tags.dig("edges").last.dig("cursor")
        #   end

        #   all_tags
        # end

        def product_tags(variables:)
          query = FastLand::Shopify::Query.product_tags_list
          tags = []
          retries = 1
          ShopifyAPIRetry.retry(2) {
            while retries <= 3
              tags = ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h&.dig("products")
              break if tags == nil || tags.any?

              retries += 1
            end
          }

          tags
        end

        # Get all tags by Yaroslav
        def all_product_tags
          variables = FastLand::Shopify::Variables.product_with_tags(num_products: 250)
          all_tags = []
          while true
            tags = product_tags(variables: variables)
            # puts tags
            # return
            # all_tags += tags["node"].map { |tag| tag.dig("node")}
            unless tags == nil
              tags.dig("edges").each do |item|
                item["node"].dig("tags").each do |tag|
                  unless all_tags.include? tag
                    all_tags.push(tag)
                  end
                end
              end

              has_more = tags.dig("pageInfo", "hasNextPage")
              break unless has_more
              variables[:cursor] = tags.dig("edges").last.dig("cursor")
            else
              break
            end
          end

          all_tags
        end

        # Get vendors
        def product_vendors(variables:)
          query = FastLand::Shopify::Query.product_vendors
          vendors = []
          retries = 1
          ShopifyAPIRetry.retry(2) {
            while retries <= 3
              vendors = ShopifyAPI::GraphQL.client.query(query, variables: variables).data.to_h&.dig("shop", "productVendors")
              break if vendors == nil || vendors.any?

              retries += 1
            end
          }

          vendors
        end

        # Get all vendors
        def all_product_vendors
          variables = FastLand::Shopify::Variables.product_vendors(num_vendors: 250)
          all_vendors = []
          while true
            vendors = product_vendors(variables: variables)
            all_vendors += vendors["edges"].map { |vendor| vendor.dig("node") }

            # Check if more products exist
            has_more = vendors.dig("pageInfo", "hasNextPage")
            break unless has_more
            variables[:cursor] = vendors.dig("edges").last.dig("cursor")
          end

          all_vendors
        end
      end
    end
  end
end
