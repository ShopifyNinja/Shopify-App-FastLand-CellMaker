class VirtualHandle < ApplicationRecord
  has_many :products
  
  def product_handles(destination_id:)
    product = Product.find_by(vh_id: vh_id, destination_id: destination_id)

    product.present? ? ProductHandle.where(product_id: product.id).pluck(:handle) : []
  end
end
