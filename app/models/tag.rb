# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :products

  default_scope { order(created_at: :desc) }
  scope :by_tags, -> (tags) { where(tag: tags).order(created_at: :desc) }

  def product_handles(destination_id:)
    product = Product.find_by(tag_id: id, destination_id: destination_id)

    product.present? ? ProductHandle.where(product_id: product.id).pluck(:handle) : []
  end
end
