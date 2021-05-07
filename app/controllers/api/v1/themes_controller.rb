# frozen_string_literal: true

class Api::V1::ThemesController < AuthenticatedController
  # Get active themes
  def index
    themes = []

    # Get existing themes in the database
    current_shopify_theme_ids = Theme.pluck(:shopify_theme_id)

    # Get all existing themes in the store
    shopify_themes = ShopifyAPI::Theme.all
    store_shopify_theme_ids = []
    shopify_themes.each do |shopify_theme|
      if current_shopify_theme_ids.include? shopify_theme.id
        Theme.where(shopify_theme_id: shopify_theme.id).update({
          name: shopify_theme.name,
          role: shopify_theme.role
        })
      else
        themes << {
          shopify_theme_id: shopify_theme.id,
          name: shopify_theme.name,
          role: shopify_theme.role,
          installed: false
        }
      end
      store_shopify_theme_ids << shopify_theme.id
    end

    # Insert themes
    Theme.insert_all(themes) if themes.any?

    # Delete themes
    removed_theme_ids = current_shopify_theme_ids - store_shopify_theme_ids
    Theme.where(shopify_theme_id: removed_theme_ids).destroy_all if removed_theme_ids.any?

    themes = Theme.select(:shopify_theme_id, :name).map { |theme|
      {
        value: theme.shopify_theme_id,
        label: theme.name
      }
    }

    render json: { themes: themes, installed_theme_ids: Theme.active.pluck(:shopify_theme_id) }
  end

  # Install files
  def install
    domain = ShopifyAPI::Shop.current.myshopify_domain
    shopify_theme_ids = installation_params[:selected_themes]
    active_theme_ids = Theme.active.pluck(:shopify_theme_id)
    new_shopify_theme_ids = shopify_theme_ids - active_theme_ids
    deactive_shopify_theme_ids = active_theme_ids - shopify_theme_ids
    job_id = FastLand::Worker::Installation.perform_async(domain, new_shopify_theme_ids, deactive_shopify_theme_ids)

    session[:install_job_id] = job_id

    render json: { status: true }
  end

  # Check installation
  def is_installing
    job_id = session[:install_job_id]
    completed = Sidekiq::Status.complete? job_id
    working = Sidekiq::Status.working? job_id

    themes, installed_theme_ids = [], []
    if completed
      themes = Theme.select(:shopify_theme_id, :name).map { |theme|
        {
          value: theme.shopify_theme_id,
          label: theme.name
        }
      }
      installed_theme_ids = Theme.active.pluck(:shopify_theme_id)
    end

    render json: {
      completed: completed,
      working: working,
      themes: themes,
      installed_theme_ids: installed_theme_ids
    }
  end

  private
    def installation_params
      params.permit(selected_themes: [])
    end
end
