# frozen_string_literal: true

require "nokogiri"
require "open-uri"
require "uri"

class Api::V1::ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index, :create]

  def index
    shop = Shop.find_by(shopify_domain: params[:shop])
    if shop.nil?
      render json: { html: nil, error: "You have to install App on #{params[:shop]}", status: false }
    else
      destination = Destination.find_by(destination: params[:destination])

      # destination validation
      if destination.nil?
        render json: { html: nil, error: "Destination #{params[:destination]} is invalid", status: false }
      else
        handle = params[:handle]
        # Check if handle exists
        product_handle = ProductHandle.find_by(handle: handle, destination_id: destination.id)

        if product_handle.nil?
          render json: { html: nil, error: "Product does not exist", status: false }
        else
          product = Product.find_by(product_handle_id: product_handle.id, destination_id: destination.id)
          if product.nil?
            render json: { html: nil, styles: nil, status: false }
          else
            page = Page.find(product.page_id)
            # Get html
            doc = Nokogiri::HTML(URI.open(page.full_html))

            # # Change image src: <img src="">
            # doc.css("img").each do |node|
            #   src = node.attributes["src"].value
            #   image = product.find_image(src: src)
            #   node.attributes["src"].value = image if image.present?
            # end

            # # Change the background image url of inline-style
            # doc.css("div").each do |n|
            #   if n["style"].present?
            #     src = n["style"][/url\((.+)\)/, 1]
            #     if src.present?
            #       # Remove ' and " from src
            #       src = src.gsub(/'/, "").gsub(/"/, "")
            #       image = product.find_image(src: src)
            #       n["style"] = n["style"].gsub(src, image)
            #     end
            #   end
            # end
            render json: { html: doc.at("body").inner_html, wrappercode: page.wrappercode, styles: page.full_styles, status: true }
          end
        end
      end
    end
  end

  def create
    # return {error:"returned product params:#{products_params}"}
    result = validate?(products_params: products_params)
    unless result[:status]
      render json: { status: false, error: result[:error] }
    else
      destination_id = Destination.find_by(destination: products_params[:destination]).id

      # Get page info
      base_url = products_params[:base_url].chomp("/")&.strip
      html = products_params[:html]&.strip
      styles = products_params[:styles].reject { |style| style.empty? }.map(&:strip).uniq.join(",")
      images = products_params[:images].reject { |img| img.empty? }.map { |img| CGI.unescape(img&.strip) }.uniq.join(",")

      # Upsert page
      page = Page.find_by(base_url: base_url, html: html, styles: styles, images: images)
      if page.nil?
        wrappercode = Wrappercode.where(destination_id: destination_id, used: 0).first
        if wrappercode.present?
          page = Page.create({
            base_url: base_url,
            html: html,
            styles: styles,
            images: images,
            wrappercode: wrappercode.value
          })
          wrappercode.used = 1
          wrappercode.save
        else
          page = Page.create({
            base_url: base_url,
            html: html,
            styles: styles,
            images: images
          })
        end
      end

      # Check product handles
      successful_handles = result[:successful_handles]
      failed_handles = result[:failed_handles]
      if successful_handles.any?
        successful_handles.each do |handle|
          product_handle = ProductHandle.find_by(handle: handle, destination_id: destination_id)
          if product_handle.nil?
            product_handle = ProductHandle.create({
              handle: handle,
              destination_id: destination_id
            })
          end

          fastland_product = Product.find_by(product_handle_id: product_handle.id, destination_id: destination_id)
          if fastland_product.present?
            fastland_product.page_id = page.id
            fastland_product.save
          else
            fastland_product = Product.create({
              page_id: page.id,
              destination_id: destination_id,
              product_handle_id: product_handle.id
            })
          end

          # Store product id
          product_handle.product_id = fastland_product.id
          product_handle.save
        end
      end

      if products_params[:tags].any?
        products_params[:tags].each do |tag|
          tag_row = Tag.find_by(tag: tag)
          if tag_row.nil?
            tag_row = Tag.create({
              tag: tag
            })
          end

          product_row = Product.find_by(destination_id: destination_id, tag_id: tag_row.id)
          if product_row.present?
            product_row.page_id = page.id
            product_row.save
          else
            Product.create({
              page_id: page.id,
              destination_id: destination_id,
              tag_id: tag_row.id
            })
          end
        end
      end

      if products_params[:collections].present?
        products_params[:collections].each do |collection_title|
          collection_row = Collection.find_by(title: collection_title)
          if collection_row.nil?
            collection_row = Collection.create({
              title: collection_title
            })
          end

          product_row = Product.find_by(destination_id: destination_id, collection_id: collection_row.id)
          if product_row.present?
            product_row.page_id = page.id
            product_row.save
          else
            Product.create({
              page_id: page.id,
              destination_id: destination_id,
              collection_id: collection_row.id
            })
          end
        end
      end

      if products_params[:vendors].present?
        products_params[:vendors].each do |vendor|
          vendor_row = Vendor.find_by(vendor: vendor)
          if vendor_row.nil?
            vendor_row = Vendor.create({
              vendor: vendor
            })
          end

          product_row = Product.find_by(destination_id: destination_id, vendor_id: vendor_row.id)
          if product_row.present?
            product_row.page_id = page.id
            product_row.save
          else
            Product.create({
              page_id: page.id,
              destination_id: destination_id,
              vendor_id: vendor_row.id
            })
          end
        end
      end

      virtual_handles = VirtualHandle.all
      virtual_handles.each do |virtual_handle|
        if destination_id == virtual_handle.destination_id
          Product.where(page_id: page.id, destination_id: virtual_handle.destination_id, vh_id: virtual_handle.vh_id).delete_all
          Product.create({
            page_id: page.id,
            destination_id: virtual_handle.destination_id,
            vh_id: virtual_handle.vh_id
          })
        end
      end

      if successful_handles.empty? && products_params[:handles].any?
        render json: { status: false, error: "all product handles are invalid" }
      elsif failed_handles.any?
        render json: { status: false, error: "#{failed_handles.join(",")} are(is) invalid product handle(s)", successful_handles: successful_handles, failed_handles: failed_handles }
      else
        render json: { status: true }
      end
    end
  end

  # Sync
  def sync
    job_id = FastLand::Worker::Sync.perform_async
    session[:job_id] = job_id

    render json: { status: true }
  end

  # Check sync is done
  def check_sync
    job_id = session[:job_id]
    puts "product_sync_log(now): job_id = #{session[:job_id]}"
    completed = Sidekiq::Status.complete? job_id
    working = Sidekiq::Status.working? job_id
    puts "product_sync_log(now): completed = #{completed}, working = #{working}"
    render json: { completed: completed, working: working }
  end

  # Clear sync
  def clear_sync
    Page.delete_all
    ProductHandle.delete_all
    Product.delete_all
    Tag.delete_all
    Collection.delete_all
    Vendor.delete_all
    VirtualHandle.delete_all
    Wrappercode.delete_all

    render json: { status: true }
  end

  # Check validation
  def validate?(products_params:)
    # Check store validation
    if products_params[:store].nil?
      return { status: false, error: "Store is required" }
      # return {status: false, error: products_params}
    else
      if products_params[:store].include? ".myshopify.com"
        shop = Shop.find_by(shopify_domain: products_params[:store])
        if shop.nil?
          return { status: false, error: "You have to install App on #{products_params[:store]}" }
        end
      else
        return { status: false, error: "Store is invalid" }
      end
    end

    # Check destination validation
    if products_params[:destination].nil?
      return { status: false, error: "Destination is required" }
    else
      unless Destination.exists?(destination: products_params[:destination])
        return { status: false, error: "Destination is invalid" }
      end
    end

    successful_handles, failed_handles = [], []

    # if products_params[:handles].empty? && products_params[:tags].empty? && products_params[:collections].empty? && products_params[:vendors].empty?
    #   return { status: false, error: "You have to post data with product handle, tag, collecion, vendor" }
    # else
      if products_params[:handles].present?
        FastLand::Shopify::Basic.connect
        products_params[:handles].reject { |handle| handle.empty? }.uniq.each do |handle|
          retries = 0
          status = false
          begin
            shopify_product = ShopifyAPI::Product.find(:first, params: { handle: handle.strip })
            status = shopify_product.present?
          rescue
            FastLand::Shopify::Basic.connect
            retries += 1
            retry if retries <= 3
          end

          status ? successful_handles << handle.strip : failed_handles << handle
        end
      end
    # end

    # Check base url validation
    if products_params[:base_url].nil?
      return { status: false, error: "Base url is required" }
    end

    base_url = products_params[:base_url].chomp("/")
    # Check html validation
    if products_params[:html].nil?
      return { status: false, error: "HTML is required" }
    end

    # Check styles validation
    if products_params[:styles].nil?
      return { status: false, error: "Styles are required" }
    else
      invalid_style = products_params[:styles].find { |style| style unless FastLand::Utils::Basic.url_exists?(url: [base_url, style].join("/")) }
      if invalid_style.present?
        return { status: false, error: "#{invalid_style} is invalid style" }
      end
    end

    # Check images validation
    if products_params[:images].nil?
      return { status: false, error: "Images are required" }
    else
      invalid_image = products_params[:images].find { |image| image unless FastLand::Utils::Basic.url_exists?(url: [base_url, image].join("/")) }
      if invalid_image.present?
        return { status: false, error: "#{invalid_image} is invalid image" }
      end
    end

    # # Check fonts validation
    # if products_params[:fonts].nil?
    #   return { status: false, error: "Fonts are required" }
    # else
    #   invalid_font = products_params[:fonts].find { |font| font unless FastLand::Utils::Basic.url_exists?(url: [base_url, font].join("/")) }
    #   if invalid_font.present?
    #     return { status: false, error: "#{invalid_font} is invalid font" }
    #   end
    # end

    { status: true, successful_handles: successful_handles, failed_handles: failed_handles }
  end

  # Get report
  def report
    render json: { data: [] }
  end

  private
    def products_params
      params.permit(:store, :destination, :base_url, :html, handles: [], tags: [], collections: [], vendors: [], styles: [], images: [], fonts: [])
    end
end