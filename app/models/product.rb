# frozen_string_literal: true

class Product < ApplicationRecord
  belongs_to :page
  belongs_to :destination, optional: true
  belongs_to :collection, optional: true
  belongs_to :vendor, optional: true
  belongs_to :tag, optional: true
  belongs_to :virtual_handle, optional: true
  belongs_to :product_handle, optional: true
end
