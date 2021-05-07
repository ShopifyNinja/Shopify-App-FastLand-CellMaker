# frozen_string_literal: true

class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage

  def api_version
    ShopifyApp.configuration.api_version
  end

  def connect
    ShopifyAPI::Base.clear_session
    session = ShopifyAPI::Session.new(domain: shopify_domain, token: shopify_token, api_version: ENV["SHOPIFY_API_VERSION"])
    ShopifyAPI::Base.activate_session(session)
  end
end
