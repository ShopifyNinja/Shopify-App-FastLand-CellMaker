# frozen_string_literal: true

class Page < ApplicationRecord
  has_many :products

  def full_html
    [base_url, html].join("/")
  end

  def full_styles
    styles.split(",").map { |style| [base_url, style].join("/") }
  end

  def full_images
    images.split(",").map { |image| [base_url, image].join("/") }
  end

  def find_image(src:)
    return nil if src.nil?
    image = images.split(",").find { |img| img == src }
    image.present? ? [base_url, image].join("/") : nil
  end

  def full_fonts
    fonts.split(",").map { |font| [base_url, font].join("/") }
  end
end
