# frozen_string_literal: true

class Theme < ApplicationRecord
  scope :active, -> { where(installed: true) }
end
