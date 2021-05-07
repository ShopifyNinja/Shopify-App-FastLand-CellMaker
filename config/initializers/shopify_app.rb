ShopifyApp.configure do |config|
  config.application_name = ENV["SHOPIFY_APP_NAME"]
  config.api_key = ENV['SHOPIFY_API_KEY']
  config.secret = ENV['SHOPIFY_API_PASSWORD']
  config.old_secret = ""
  config.scope = "read_themes, write_themes, read_products" # Consult this page for more scope options:
                                 # https://help.shopify.com/en/api/getting-started/authentication/oauth/scopes
  config.embedded_app = true
  config.api_version = ENV['SHOPIFY_API_VERSION']
  config.shop_session_repository = 'Shop'
  config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: false }
  config.webhooks = [
    {topic: 'app/uninstalled', address: "#{ENV['APP_DOMAIN']}/webhooks/app_uninstalled", format: 'json'},
  ]
end

# ShopifyApp::Utils.fetch_known_api_versions                        # Uncomment to fetch known api versions from shopify servers on boot
# ShopifyAPI::ApiVersion.version_lookup_mode = :raise_on_unknown    # Uncomment to raise an error if attempting to use an api version that was not previously known
