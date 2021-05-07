# frozen_string_literal: true

module FastLand
  module Worker
    class Sync
      include Sidekiq::Worker
      include Sidekiq::Status::Worker
      sidekiq_options queue: :product_sync2, retry: false

      def perform(*args)
        puts "product_sync_log: job_start"
        sync_log = SyncLog.create({ start_at: DateTime.now })

        FastLand::Shopify::Basic.connect
        # sync_products
        clear_unneeded_pages
        sync_products_by_tags
        sync_products_by_collections
        sync_products_by_vendors
        sync_products_by_vhs

        sync_log.end_at = DateTime.now
        sync_log.status = :success
        sync_log.save
        puts "product_sync_log: job_end"
      end

      def clear_unneeded_pages
        pages = Page.all
        pages.each do |page|
          product = Product.find_by(page_id: page.id)
          unless product.present?
            Page.delete(page.id)
          end
        end
      end

      def sync_products
        index_product = 1
        FastLand::Shopify::Basic.connect

        variables = FastLand::Shopify::Variables.products(num_products: 25, num_collections: 10)
        while true
          products = FastLand::Shopify::Product.get_products_by(variables: variables)
          products["edges"].each do |product|
            sync(shopify_product: product, index_product: index_product)
            index_product+= 1
          end

          # Check if more products exist
          has_more = products.dig("pageInfo", "hasNextPage")
          break unless has_more

          variables[:cursor_product] = products.dig("edges").last.dig("cursor")
        end
      end

      def sync(shopify_product:, index_product:)
        retries = 0
        begin
          shopify_product_handle = shopify_product.dig("node", "handle")
          shopify_product_tags = shopify_product.dig("node", "tags")
          shopify_product_vendor = shopify_product.dig("node", "vendor")
          puts "product_sync_log: checking handle(#{index_product}) = #{shopify_product_handle} ..."

          Destination.all.each do |destination|
            puts "product_sync_log: checking destination = #{destination.destination} ..."
            if ProductHandle.exists?(handle: shopify_product_handle, destination_id: destination.id)
              puts "product_sync_log: handle(#{shopify_product_handle}) is already synced"
            else
              # Check product tags
              puts "product_sync_log: checking tags..."
              tag_synced = false
              Tag.by_tags(shopify_product_tags).each do |tag|
                puts "product_sync_log: checking tag = #{tag.tag} ..."
                product = Product.find_by(tag_id: tag.id, destination_id: destination.id)
                if product.present?
                  product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination_id)
                  if product_handle_row.nil?
                    ProductHandle.create({
                      handle: shopify_product_handle,
                      destination_id: destination_id,
                      product_id: product.id
                    })
                  end
                  tag_synced = true
                  puts "product_sync_log: handle(#{shopify_product_handle}) is synced from tag(#{tag.tag})"
                  break
                end
              end

              # Check product collections
              unless tag_synced
                puts "product_sync_log: checking collections ..."
                collection_synced = false

                collection_titles = FastLand::Shopify::Product.get_collection_titles(shopify_product: shopify_product)
                Collection.by_titles(collection_titles).each do |collection|
                  puts "product_sync_log: checking collection = #{collection.title} ..."
                  product = Product.find_by(collection_id: collection.id, destination_id: destination.id)
                  if product.present?
                    product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination_id)
                    if product_handle_row.nil?
                      ProductHandle.create({
                        handle: shopify_product_handle,
                        destination_id: destination_id,
                        product_id: product.id
                      })
                    end
                    collection_synced = true
                    puts "product_sync_log: handle(#{shopify_product_handle}) is synced from collection(#{collection.title})"
                    break
                  end
                end

                # Check product vendor
                unless collection_synced
                  puts "product_sync_log: checking vendor = #{shopify_product_vendor} ..."
                  vendor = Vendor.find_by(vendor: shopify_product_vendor)
                  if vendor.present?
                    product = Product.find_by(vendor_id: vendor.id, destination_id: destination.id)
                    if product.present?
                      product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination_id)
                      if product_handle_row.nil?
                        ProductHandle.create({
                          handle: shopify_product_handle,
                          destination_id: destination_id,
                          product_id: product.id
                        })
                      end
                      puts "product_sync_log: handle(#{shopify_product_handle}) is synced from vendor(#{shopify_product_vendor})"
                      break
                    end
                  end
                end
              end
            end
          end
        rescue Exception => e
          puts "product_sync_log: error - #{e}"
          # Retry 3 times
          retries += 1
          FastLand::Shopify::Basic.connect
          retry if retries <= 3
        end
      end

      # Sync products by tags
      def sync_products_by_tags
        puts "product_sync_log: INFO - checking tags"
        Tag.all.each do |tag|
          puts "product_sync_log: INFO - tag: #{tag.tag}"
          shopify_products = FastLand::Shopify::Product.get_all_products_by_tag(tag: tag.tag)
          Destination.all.each do |destination|
            puts "product_sync_log: INFO - destination: #{destination.destination}"
            synced_product_handles = tag.product_handles(destination_id: destination.id)

            # Remove old synced products
            remove_synced_products(product_handles: synced_product_handles - shopify_products, destination_id: destination.id)

            product = Product.find_by(tag_id: tag.id, destination_id: destination.id)
            if product.nil?
              puts "product_sync_log: INFO - tag: #{tag.tag} is not posted with destination #{destination.destination}"
            else
              shopify_products.each do |shopify_product_handle|
                if ProductHandle.exists?(handle: shopify_product_handle, destination_id: destination.id)
                  puts "product_sync_log: INFO - handle: #{shopify_product_handle} is already synced"
                else
                  product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination.id)
                  if product_handle_row.nil?
                    product_handle_row = ProductHandle.create({
                      handle: shopify_product_handle,
                      destination_id: destination.id,
                      product_id: product.id
                    })
                  end

                  product_row = Product.find_by(destination_id: destination.id, product_handle_id: product_handle_row.id)
                  if product_row.present?
                    product_row.page_id = product.page_id
                    product_row.save
                  else
                    Product.create({
                      page_id: product.page_id,
                      destination_id: destination.id,
                      product_handle_id: product_handle_row.id
                    })
                  end
                  puts "product_sync_log: ACTION - handle: #{shopify_product_handle} is synced"
                end
              end
            end
          end
        end
      end

      # Sync products by collections
      def sync_products_by_collections
        puts "product_sync_log: INFO - checking collections"
        Collection.all.each do |collection|
          puts "product_sync_log: INFO - collection: #{collection.title}"
          shopify_products = FastLand::Shopify::Product.get_all_products_in_collection(collection_handle: collection.title)
          Destination.all.each do |destination|
            puts "product_sync_log: INFO - destination: #{destination.destination}"
            synced_product_handles = collection.product_handles(destination_id: destination.id)

            # Remove old synced products
            remove_synced_products(product_handles: synced_product_handles - shopify_products, destination_id: destination.id)

            product = Product.find_by(collection_id: collection.id, destination_id: destination.id)
            if product.nil?
              puts "product_sync_log: INFO - collection: #{collection.title} is not posted with destination #{destination.destination}"
            else
              # Sync collection
              if ProductHandle.exists?(handle: collection.title, destination_id: destination.id)
                puts "collection_sync_log: INFO - handle: #{collection.title} is already synced"
              else
                product_handle_row = ProductHandle.find_by(handle: collection.title, destination_id: destination.id)
                if product_handle_row.nil?
                  product_handle_row = ProductHandle.create({
                    handle: collection.title,
                    destination_id: destination.id,
                    product_id: product.id
                  })
                end

                collection_row = Product.find_by(destination_id: destination.id, collection_id: collection.id)
                if collection_row.present?
                  collection_row.page_id = product.page_id
                  collection_row.product_handle_id = product_handle_row.id
                  collection_row.save
                else
                  Product.create({
                    page_id: product.page_id,
                    destination_id: destination.id,
                    collection_id: collection.id
                  })
                end
                puts "collection_sync_log: ACTION - handle: #{collection.title} is synced"
              end

              shopify_products.each do |shopify_product_handle|
                if ProductHandle.exists?(handle: shopify_product_handle, destination_id: destination.id)
                  puts "product_sync_log: INFO - handle: #{shopify_product_handle} is already synced"
                else
                  product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination.id)
                  if product_handle_row.nil?
                    product_handle_row = ProductHandle.create({
                      handle: shopify_product_handle,
                      destination_id: destination.id,
                      product_id: product.id
                    })
                  end

                  product_row = Product.find_by(destination_id: destination.id, product_handle_id: product_handle_row.id)
                  if product_row.present?
                    product_row.page_id = product.page_id
                    product_row.save
                  else
                    Product.create({
                      page_id: product.page_id,
                      destination_id: destination.id,
                      product_handle_id: product_handle_row.id
                    })
                  end
                  puts "product_sync_log: ACTION - handle: #{shopify_product_handle} is synced"
                end
              end
            end
          end
        end
      end

      # Sync products by vendors
      def sync_products_by_vendors
        puts "product_sync_log: INFO - checking vendors"
        Vendor.all.each do |vendor|
          puts "product_sync_log: INFO - vendor: #{vendor.vendor}"
          shopify_products = FastLand::Shopify::Product.get_all_products_by_vendor(vendor: vendor.vendor)
          Destination.all.each do |destination|
            puts "product_sync_log: INFO - destination: #{destination.destination}"
            synced_product_handles = vendor.product_handles(destination_id: destination.id)

            # Remove old synced products
            remove_synced_products(product_handles: synced_product_handles - shopify_products, destination_id: destination.id)

            product = Product.find_by(vendor_id: vendor.id, destination_id: destination.id)
            if product.nil?
              puts "product_sync_log: INFO - vendor: #{vendor.vendor} is not posted with destination #{destination.destination}"
            else
              shopify_products.each do |shopify_product_handle|
                if ProductHandle.exists?(handle: shopify_product_handle, destination_id: destination.id)
                  puts "product_sync_log: INFO - handle: #{shopify_product_handle} is already synced"
                else
                  product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination.id)
                  if product_handle_row.nil?
                    product_handle_row = ProductHandle.create({
                      handle: shopify_product_handle,
                      destination_id: destination.id,
                      product_id: product.id
                    })
                  end

                  product_row = Product.find_by(destination_id: destination.id, product_handle_id: product_handle_row.id)
                  if product_row.present?
                    product_row.page_id = product.page_id
                    product_row.save
                  else
                    Product.create({
                      page_id: product.page_id,
                      destination_id: destination.id,
                      product_handle_id: product_handle_row.id
                    })
                  end
                  puts "product_sync_log: ACTION - handle: #{shopify_product_handle} is synced"
                end
              end
            end
          end
        end
      end

      # Sync products by virtual handles
      def sync_products_by_vhs
        puts "product_sync_log: INFO -checking virtual handles"
        VirtualHandle.all.each do |virtual_handle|
          vh = Vh.find(virtual_handle.vh_id)
          puts "product_sync_log: INFO - virtual handle: #{vh.name}"
          shopify_products = FastLand::Shopify::Product.get_all_products_by_vh(vh: vh)
          puts "<><>Product<><>"
          puts shopify_products
          Destination.all.each do |destination|
            puts "product_sync_log: INFO - destination: #{destination.destination}"
            synced_product_handles = virtual_handle.product_handles(destination_id: destination.id)

            # Remove old synced products
            remove_synced_products(product_handles: synced_product_handles - shopify_products, destination_id: destination.id)

            product = Product.find_by(vh_id: virtual_handle.vh_id, destination_id: destination.id)
            if product.nil?
              puts "product_sync_log: INFO - Virtual handle: #{vh.name} is not posted with destination #{destination.destination}"
            else
              shopify_products.each do |shopify_product_handle|
                if ProductHandle.exists?(handle: shopify_product_handle, destination_id: destination.id)
                  puts "product_sync_log: INFO - handle: #{shopify_product_handle} is already synced"
                else
                  product_handle_row = ProductHandle.find_by(handle: shopify_product_handle, destination_id: destination.id)
                  if product_handle_row.nil?
                    product_handle_row = ProductHandle.create({
                      handle: shopify_product_handle,
                      destination_id: destination.id,
                      product_id: product.id
                    })
                  end

                  product_row = Product.find_by(destination_id: destination.id, product_handle_id: product_handle_row.id)
                  if product_row.present?
                    product_row.page_id = product.page_id
                    product_row.save
                  else
                    Product.create({
                      page_id: product.page_id,
                      destination_id: destination.id,
                      product_handle_id: product_handle_row.id
                    })
                  end
                  puts "product_sync_log: ACTION - handle: #{shopify_product_handle} is synced"
                end
              end
            end
          end
        end
      end

      # Remove already synced products in destination
      def remove_synced_products(product_handles:, destination_id:)
        if product_handles.any?
          product_handle_ids = ProductHandle.where(handle: product_handles).where(destination_id: destination_id).pluck(:id)
          # Remove product handles
          ProductHandle.where(handle: product_handles).where(destination_id: destination_id).destroy_all
          # Remove products
          # Product.where(product_handle_id: product_handle_ids).where(destination_id: destination_id).destroy_all
          product_handles.each { |product_handle| puts "product_sync_log: WARNING - handle: #{product_handle} is removed from synced data" }
        end
      end
    end
  end
end
