# frozen_string_literal: true

module FastLand
  module Constants
    module Shopify
      SHOPIFY_PRODUCT = "PRODUCT"
      SHOPIFY_VARIANT = "VARIANT"
    end

    module Error
      # Parameter rows
      NO_EMPTY_ROWS           = "Name must be preceded by an empty row."
      INVALID_NAME            = "Name is not in the first column after an empty row."
      INVALID_DESTINATION      = "Invalid destination on line @line"
      INVALID_HANDLE          = "Invalid product handle on line @line"
      INVALID_COLLECTION       = "Invalid collection on line @line"
      INVALID_TAG             = "Invalid tag on line @line"
      INVALID_VENDOR           = "Invalid vendor on line @line"
      INVALID_VIRTUAL_HANDLE  = "Invalid virtual handle on line @line"
      INVALID_TEMPLATE        = "Invalid template name on line @line"
      NO_NAME_ROW             = "There is no name row."
      NO_DESTINATION_ROW       = "There is no destination row."
      NO_SHOPIFY_ROW           = "There is no handle, no tag, no collection, no vendor, no product type, and no virtual handle."
      MAX_NAME_ROWS_COUNT      = "There are 2+ name rows in the spec."
      MAX_DESTINATIONS_COUNT   = "There are 2+ destinations rows in the spec."
      MAX_VALUES_IN_ROW        = "There are 2+ values in the name row."

      # Parameter row value
      NO_NAME_VALUE            = "There is no name value."

      # Data header
      NO_WIDTH_COLUMN          = "There is no width row."
      NO_BEHAVIOR_COLUMN       = "There is no behavior column."
      NO_CONFIGURATION_COLUMN   = "There is no configuration column."
      NO_PRODUCT_COLUMN        = "There is no product column."
      NO_TEXT1_COLUMN          = "There is no text1 column."
      NO_IMAGE1_COLUMN         = "There is no image1 column."
      NO_LINK1_COLUMN          = "There is no link1 column."

      # Data rows
      NO_WIDTH_VALUE           = "There is no width value."
      NO_BEHAVIOR_VALUE        = "There is no behavior value."
      NO_CONFIGURATION_VALUE    = "There is no configuration value."
      INVALID_WIDTH            = "Invalid width on line @line"
      INAVLID_DATA_HEADER       = "Some data headers don't exist."
      INVALID_BEHAVIOR          = "Invalid behavior on line @line"
      INVALID_CONFIGURATION     = "Invalid configuration on line @line"
      INVALID_IMAGE            = "Image on line @line does not exist."
      INVALID_URL              = "Invalid URL on line @line"
      INVALID_VALUES_NEW_ROW    = "Invalid values in new row on line @line"
    end
  end
end
