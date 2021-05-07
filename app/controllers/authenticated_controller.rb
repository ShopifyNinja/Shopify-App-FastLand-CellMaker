# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include ShopifyApp::Authenticated

  # before_action :connect

  # private
  #   def connect
  #     FastLand::Shopify::Basic.connect
  #   end
end
