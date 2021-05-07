# frozen_string_literal: true

module FastLand
  module Shopify
    class Query
      class << self
        # List of products
        def products
          ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
            query($num_products: Int, $cursor: String, $query: String!) {
              products(first: $num_products, after: $cursor, query: $query) {
                pageInfo {
                  hasNextPage
                }
                edges {
                  cursor
                  node {
                    handle
                  }
                }
              }
            }
          GRAPHQL
        end

        # List of collections
        def collections
          ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
            query($num_collections: Int, $cursor: String, $collection_sort_key: CollectionSortKeys) {
              collections(first: $num_collections, after: $cursor, sortKey: $collection_sort_key) {
                pageInfo {
                  hasNextPage
                }
                edges {
                  cursor
                  node {
                    handle
                    title
                    productsCount
                  }
                }
              }
            }
          GRAPHQL
        end

        # Return a product by its handle
        def product_by_handle(with_collection: true)
          if with_collection
            ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
              query($handle: String!, $num_collections: Int, $cursor_collection: String) {
                productByHandle(handle: $handle) {
                  handle
                  collections(first: $num_collections, after: $cursor_collection) {
                    pageInfo {
                      hasNextPage
                    }
                    edges {
                      cursor
                      node {
                        title
                      }
                    }
                  }
                }
              }
            GRAPHQL
          else
            ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
              query($handle: String!) {
                productByHandle(handle: $handle) {
                  handle
                }
              }
            GRAPHQL
          end
        end

        # Return a product by its handle
        def product_by_handle_name
          ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
            query($handle: String!) {
              productByHandle(handle: $handle) {
                bodyHtml
                handle
                id
                images(first: 1) {
                  edges {
                    node {
                      originalSrc
                    }
                  }
                }
                options {
                  name
                }
                productType
                tags
                title
                variants(first: 1) {
                  edges {
                    node {
                      price
                      sku
                      title
                      id
                    }
                  }
                }
                metafields(first: 250) {
                  edges {
                    node {
                      key
                      value
                    }
                  }
                }
                vendor
              }
            }
          GRAPHQL
        end

        # Return a collection by its handle
        def collection_by_handle(with_products: true)
          if with_products
            ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
              query($handle: String!, $num_products: Int, $cursor: String) {
                collectionByHandle(handle: $handle) {
                  title
                  products(first: $num_products, after: $cursor) {
                    pageInfo {
                      hasNextPage
                    }
                    edges {
                      cursor
                      node {
                        handle
                      }
                    }
                  }
                }
              }
            GRAPHQL
          else
            ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
              query($handle: String!) {
                collectionByHandle(handle: $handle) {
                  handle
                }
              }
            GRAPHQL
          end
        end

        # Get product tags
        def product_tags
          ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
            query($num_tags: Int!)
            {
              shop{
                productTags(first: $num_tags){
                  pageInfo{
                    hasNextPage
                  }
                  edges{
                    node
                    cursor
                  }
                }
              }
            }
          GRAPHQL
        end

        # Get product vendors
        def product_vendors
          ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
            query($num_vendors: Int!)
            {
              shop{
                productVendors(first: $num_vendors){
                  pageInfo{
                    hasNextPage
                  }
                  edges{
                    node
                    cursor
                  }
                }
              }
            }
          GRAPHQL
        end
        # Get Tags list by products
        def product_tags_list
          ShopifyAPI::GraphQL.client.parse <<~GRAPHQL
            query($num_products: Int, $cursor: String) {
              products(first: $num_products, after: $cursor) {
                pageInfo {
                  hasNextPage
                }
                edges {
                  cursor
                  node {
                    tags
                  }
                }
              }
            }
          GRAPHQL
        end
      end
    end
  end
end
