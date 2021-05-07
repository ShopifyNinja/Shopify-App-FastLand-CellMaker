# frozen_string_literal: true

class Collection < ApplicationRecord
  has_many :products

  default_scope { order(created_at: :desc) }
  scope :by_titles, -> (titles) { where(title: titles).order(created_at: :desc) }

  def product_handles(destination_id:)
    product = Product.find_by(collection_id: id, destination_id: destination_id)

    product.present? ? ProductHandle.where(product_id: product.id).pluck(:handle) : []
  end
end
