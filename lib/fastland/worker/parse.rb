# frozen_string_literal: true

require "roo"
require "csv"
require "writeexcel"
require "open-uri"

module FastLand
  module Worker
    $master_wizard_id = 0
    $wrappercode_array = []
    class Parse
      include Sidekiq::Worker
      include Sidekiq::Status::Worker
      include FastLand::Constants::Error
      sidekiq_options queue: :file_parser2, retry: false

      def perform(file_path)
        puts "INFO - starting parsing ..."
        parse_file(file_path: file_path)
        puts "INFO - parsing end"
      end

      def parse_file(file_path:)
        puts "WARNING - starting file parsing..."
        FastLand::Shopify::Basic.connect
        result = FastLand::Catalog.validate_user
        options = {
          base_url: Setting.last&.base_url,
          configurations: FastLand::Catalog.configurations(customer_id: result[:customer_id]),
          #product_tags: FastLand::Shopify::Store.all_product_tags,
          #product_vendors: FastLand::Shopify::Store.all_product_vendors,
          virtual_handles: Vh.pluck(:name),
          templates: Template.pluck(:name)
        }
        $master_wizard_id = Template.where(default_value: 1).first.wizard_id

        if is_clear?(file_path: file_path)
          puts "INFO - remove started"
          result1 = clear_sync(file_path: file_path)
          
          if result1[:status]
            puts "INFO - successfully removed"
          else
            puts "ERROR - #{result1[:error]}"
            store errors: result1[:error]
          end
        elsif is_validate?(file_path: file_path, options: options)
          if result[:status]
            session_id = result[:session_id]
            # Create new file for ProcessCellMaker
            max_retries = 3
            times_retried = 0

            begin
              new_file_path = create_file(file_path: file_path)

            rescue Net::ReadTimeout => error
              if times_retried < max_retries
                times_retried += 1
                puts "Failed to <do the thing>, retry #{times_retried}/#{max_retries}"
                retry
              else
                puts "Exiting script. <explanation of why this is unlikely to recover>"
                exit(1)
              end
            end
            
            result1 = FastLand::Catalog.process_cell_maker(session_id: session_id, store_name: ShopifyAPI::Shop.current.myshopify_domain, file_path: new_file_path, master_wizard_id: $master_wizard_id)
            # Remove file
            # File.exist?(txt_file_name) && File.delete(txt_file_name)
            if result1[:status]
              if $wrappercode_array != []
                $wrappercode_array.each do |wrappercode_row|
                  row = Wrappercode.new
                  row.value = wrappercode_row[1]
                  row.destination_id = wrappercode_row[0]
                  row.used = 0
                  row.save
                end
                $wrappercode_array = []
              end
              puts "INFO - successfully sent"
            else
              puts "ERROR - #{result1[:error]}"
              store errors: result1[:error]
            end
          end
        end
      end

      def is_clear?(file_path:)
        return false unless File.exist?(file_path)

        xls = Roo::Excel.new(file_path)
        sheet = xls.sheet(0)
        first_row = sheet.first_row
        last_row = sheet.last_row
        first_column = sheet.first_column
        last_column = sheet.last_column
        clear = false
        (first_row..last_row).each do |row_index|
          row = (first_column..last_column).map { |col_index| sheet.cell(row_index, col_index) }
          puts row[0]
          if downcase(row[0]) == 'clear'
            clear = true
          end
        end

        clear
      end

      def clear_sync(file_path:)
        return false unless File.exist?(file_path)

        xls = Roo::Excel.new(file_path)
        sheet = xls.sheet(0)
        first_row = sheet.first_row
        last_row = sheet.last_row
        first_column = sheet.first_column
        last_column = sheet.last_column
        destination_id = 0
        (first_row..last_row).each do |row_index|
          row = (first_column..last_column).map { |col_index| sheet.cell(row_index, col_index) }
          value = row[1]
          case downcase(row[0])
          when 'destination'
            destination_id = Destination.where(destination: value).first.id
          when 'collection'
            next if Collection.where(title: value).first == nil
            collection_id = Collection.where(title: value).first.id
            product_id = Product.where(destination_id: destination_id, collection_id: collection_id).first.id
            product_handles = ProductHandle.where(product_id: product_id, destination_id: destination_id).pluck(:id)

            Collection.where(id: collection_id).delete_all
            ProductHandle.where(product_id: product_id, destination_id: destination_id).delete_all
            Product.where(id: product_id, destination_id: destination_id).delete_all
            product_handles.each do |product_handle|
              Product.where(destination_id: destination_id, product_handle_id: product_handle).delete_all
            end
          when 'tag'
            next if Tag.where(tag: value).first == nil
            tag_id = Tag.where(tag: value).first.id
            product_id = Product.where(destination_id: destination_id, tag_id: tag_id).first.id
            product_handles = ProductHandle.where(product_id: product_id, destination_id: destination_id).pluck(:id)

            Tag.where(id: tag_id).delete_all
            ProductHandle.where(product_id: product_id, destination_id: destination_id).delete_all
            Product.where(id: product_id, destination_id: destination_id).delete_all
            product_handles.each do |product_handle|
              Product.where(destination_id: destination_id, product_handle_id: product_handle).delete_all
            end
          when 'virtual handle'
            next if Vh.where(name: value).first == nil
            vh_id = Vh.where(name: value).first.id
            virtual_handle_id = VirtualHandle.where(vh_id: vh_id).first.id
            product_id = Product.where(destination_id: destination_id, vh_id: vh_id).first.id
            product_handles = ProductHandle.where(product_id: product_id, destination_id: destination_id).pluck(:id)

            VirtualHandle.where(id: virtual_handle_id).delete_all
            ProductHandle.where(product_id: product_id, destination_id: destination_id).delete_all
            Product.where(id: product_id, destination_id: destination_id).delete_all
            product_handles.each do |product_handle|
              Product.where(destination_id: destination_id, product_handle_id: product_handle).delete_all
            end
          when 'vendor'
            next if Vendor.where(vendor: value).first == nil
            vendor_id = Vendor.where(vendor: value).first.id
            product_id = Product.where(destination_id: destination_id, vendor_id: vendor_id).first.id
            product_handles = ProductHandle.where(product_id: product_id, destination_id: destination_id).pluck(:id)

            Vendor.where(id: vendor_id).delete_all
            ProductHandle.where(product_id: product_id, destination_id: destination_id).delete_all
            Product.where(id: product_id, destination_id: destination_id).delete_all
            product_handles.each do |product_handle|
              Product.where(destination_id: destination_id, product_handle_id: product_handle).delete_all
            end
          when 'handle'
            product_handle_id = ProductHandle.where(handle: value, destination_id: destination_id).first.id
            ProductHandle.where(id: product_handle_id, destination_id: destination_id).delete_all
            Product.where(product_handle_id: product_handle_id, destination_id: destination_id).delete_all
          when 'product_type'
            next
          end
        end

        { status: true }
      end

      def is_validate?(file_path:, options:)
        # Check the file existence
        return false unless File.exist?(file_path)

        # Get all specs
        result = all_specs(file_path: file_path)
        specs = result[:specs]
        errors = result[:errors]

        if errors.present?
          store errors: errors.join("|")
          false
        else
          parse_specs(specs: specs, options: options)
        end
      end

      def create_file(file_path:)
        file_name = file_path&.sub("public/files/", "")
        unless File.directory?("public/cell_maker")
          Dir.mkdir "public/cell_maker"
        end
        unless File.directory?("public/product_images")
          Dir.mkdir "public/product_images"
        end
        new_file_path = ["public/cell_maker", file_name].join("/")
        xls = Roo::Excel.new(file_path)
        new_xls = WriteExcel.new(new_file_path)
        sheet = xls.sheet(0)
        worksheet = new_xls.add_worksheet
        first_row = sheet.first_row
        last_row = sheet.last_row
        first_column = sheet.first_column
        last_column = sheet.last_column
        handle_index = 0
        template_index = 0
        wrappercode_index = 0
        row_start = 1
        final_data = ['']
        (first_row..last_row).each do |row_index|
          empry_row = ['']
          (first_column..last_column + 1).each do |col_index|
            empry_row[col_index - 1] = ''
          end
          final_data[row_index - 1] = empry_row
        end

        (first_row..last_row).each do |row_index|
          row = (first_column..last_column).map { |col_index| sheet.cell(row_index, col_index) }
          row[last_column] = ''
          final_data[row_index - 1] = row if final_data[row_index - 1][0] == ''
          
          handle_exist = (row.include? 'Handle') || (row.include? 'handle')
          if downcase(row[0]) == 'template'
            template_index = row_index
          end
          if downcase(row[0]) == 'wrappercode'
            wrappercode_index = row_index
          end
          if downcase(row[0]) == 'width' && handle_exist
            data_row_key = row
            row_key_index = row_index
            final_data_row_key = ['']
            row.each_with_index do |col, index|
              final_data_row_key[index] = col
            end
            data_row_start = row_index + 1
            sequence = 0
            final_data_row_key[last_column] = '#$#_JJJsequence'
            (data_row_start..last_row).each do |data_row_index|
              data_row = (first_column..last_column).map { |data_col_index| sheet.cell(data_row_index, data_col_index) }
              data_row[last_column] = ''
              final_data_row = data_row
              product = ['']
              link = ''
              handle = ''

              break if downcase(data_row[0]) == 'name'

              (first_column..last_column).each do |data_col_index|
                case downcase(data_row_key[data_col_index])
                when 'handle'
                  handle_index = data_col_index
                  handle = data_row[data_col_index]
                  break if handle == nil
                  product = FastLand::Shopify::Product.get_product_by_handle_name(handle: handle)
                when 'link1'
                  link = "https://" + ENV["SHOPIFY_DOMAIN"] + "/products/" + handle unless handle == nil
                  if data_row[data_col_index] == nil
                    final_data_row[data_col_index] = link
                  else
                    final_data_row[data_col_index] = data_row[data_col_index]
                  end
                when 'annotation1'
                  final_data_row_key[data_col_index] = "#$#_annotation1"
                when 'shopifyproduct'
                  case data_row[data_col_index]
                  when 'title'
                    final_data_row_key[data_col_index] = "#$#_title"
                    final_data_row[data_col_index] = product['title']
                  when 'body_html'
                    final_data_row_key[data_col_index] = "#$#_body_html"
                    final_data_row[data_col_index] = product['bodyHtml']
                  end
                when 'shopifymeta'
                  metafield_data = product['metafields'].to_h.dig("edges")
                  final_data_row_key[data_col_index] = "#$#_" + data_row[data_col_index] unless final_data_row_key[data_col_index].include? "#$#_"
                  meta_key = data_row[data_col_index]
                  metafield_data.each do |meta|
                    meta_data = meta.dig("node")
                    if meta_data['key'] == meta_key
                      final_data_row[data_col_index] = meta_data['value']
                      break
                    end
                  end
                when 'shopifyvariant'
                  variant_data = product['variants'].to_h.dig("edges").first.dig("node")
                  case data_row[data_col_index]
                  when 'sku'
                    final_data_row_key[data_col_index] = "#$#_sku"
                    final_data_row[data_col_index] = variant_data['sku']
                  when 'price'
                    final_data_row_key[data_col_index] = "#$#_price"
                    final_data_row[data_col_index] = variant_data['price']
                  end
                when 'image1'
                  image_file_name = data_row[data_col_index]
                  if image_file_name == nil
                    unless product[0] == ''
                      image_data = product['images'].to_h.dig("edges").first.dig("node")
                      final_data_row[data_col_index] = get_shopify_image(handle: handle, src: image_data['originalSrc'])
                    end
                  end
                when 'configuration'
                  unless data_row[data_col_index] ==  'new row'
                    if data_row[0] != '' && data_row[0] != nil
                      puts "NOT NEW ROW"
                      final_data_row[last_column] = sequence
                      sequence += 1
                    end
                  end
                else
                  
                end
              end
              row_index = data_row_index
              final_data[data_row_index - 1] = final_data_row
            end
            final_data[row_key_index - 1] = final_data_row_key
          end
        end

        final_data.each_with_index do |row, row_index|
          if (template_index - 1 > row_index) || (template_index == 0)
            index = row_index
          elsif template_index - 1 < row_index
            index = row_index - 1
          end
          if (wrappercode_index - 1 > row_index) || (wrappercode_index == 0)
            index = row_index
          elsif wrappercode_index - 1 < row_index
            index = row_index - 1
          end
          row.each_with_index do |col, col_index|
            if (handle_index > col_index) || (handle_index == 0)
              worksheet.write_string(index, col_index, col)
            elsif handle_index < col_index
              worksheet.write_string(index, col_index - 1, col)
            end
          end
        end

        new_xls.close
        new_file_path
      end

      # Download image from Shopify CDN to local
      def get_shopify_image(handle: ,src:)
        extension = ''
        if downcase(src).include? "jpg"
          extension = '.jpg'
        elsif downcase(src).include? "jpeg"
          extension = '.jpeg'
        elsif downcase(src).include? "gif"
          extension = '.gif'
        elsif downcase(src).include? "png"
          extension = '.png'
        end

        source = "public/product_images/" + handle + extension
        destination = ENV["APP_DOMAIN"] + "/product_images/" + handle + extension
        open(source, 'wb') do |file|
          file << open(src).read
        end

        destination
      end

      # Get all specs
      def all_specs(file_path:, sheet_index: 0)
        # Read all specs in the sheet
        xls = Roo::Excel.new(file_path)
        sheet = xls.sheet(sheet_index)
        first_row = sheet.first_row
        last_row = sheet.last_row
        first_column = sheet.first_column
        last_column = sheet.last_column

        # Split specs by spec
        specs, spec, errors = [], [], []
        empty_rows_count = 0
        last_row_empty = false
        count = {
          row: {
            name: 0
          }
        }
        row_start = 1
        (first_row..last_row).each do |row_index|
          row = (first_column..last_column).map { |col_index| sheet.cell(row_index, col_index) }

          if is_row_empty(row: row)
            next if last_row_empty

            if spec.any?
              # Store row start with spec
              specs << { spec: spec, row_start: row_start }
              spec = []
            end
            last_row_empty = true
            empty_rows_count += 1
          else
            # Get names row count
            if downcase(row[0]) == "name"
              count[:row][:name] += 1
            end
            # Get row start of spec
            row_start = row_index if spec.empty?
            spec << row
            if row_index == last_row
              specs << { spec: spec, row_start: row_start }
            end
            last_row_empty = false
          end
        end

        errors << NO_EMPTY_ROWS if count[:row][:name] > 1 && empty_rows_count == 0

        { specs: specs, errors: errors }
      end

      # Parse specs
      def parse_specs(specs:, options:)
        # Check specs
        errors = []
        specs.each { |spec|
          errors = check_spec(spec: spec[:spec], row_start: spec[:row_start], errors: errors, options: options)
        }
        errors = errors.uniq

        # Store errors
        store errors: errors.join("|")

        errors.empty?
      end

      # Check spec
      def check_spec(spec:, row_start:, errors:, options:)
        base_url = options[:base_url]
        configurations = options[:configurations]
        # product_tags = options[:product_tags]
        # product_vendors = options[:product_vendors]
        virtual_handles = options[:virtual_handles]
        templates = options[:templates]

        # Init
        count = {
          row: {
            name: 0,
            destination: 0,
            handle: 0,
            tag: 0,
            collection: 0,
            vendor: 0,
            virtual_handle: 0,
            product_type: 0
          },
          column: {
            width: 0
          },
          value: {
            name: 0,
            destination: 0,
            handle: 0,
            tag: 0,
            collection: 0,
            vendor: 0,
            virtual_handle: 0,
            product_type: 0
          }
        }
        index = {
          column: {
            behavior: 0,
            configuration: 0,
            product: 0,
            text1: 0,
            image1: 0,
            link1: 0
          },
          row: {
            parameter_header_start: 0,
            data_header: 0,
            data_row_start: 0,
            new: 0
          }
        }
        index[:row][:data_header] = 0
        destination_id = 0

        # Check if the column is name column after empty row validation
        if downcase(spec[0][0]) != "name"
          errors << INVALID_NAME
        end

        (0..spec.size-1).each do |row_index|
          line = row_start + row_index
          # Check the first column
          case downcase(spec[row_index][0])
          when "name"
            index[:row][:parameter_header_start] = row_index
            count[:row][:name] += 1
            count[:value][:name] = spec[row_index]&.compact.size
          when "destination"
            count[:row][:destination] += 1
            count[:value][:destination] = spec[row_index]&.compact.size
            if spec_destinations.exclude? spec[row_index][1]
              errors << detailed_error(error: INVALID_DESTINATION, line: line)
            end
            destination = Destination.find_by(destination: spec[row_index][1])
            if destination.present?
              destination_id = destination.id
            end
          when "handle"
            count[:row][:handle] += 1
            count[:value][:handle] = spec[row_index]&.compact.size
            # Check product handle validation
            product_handle = spec[row_index][1]
            product_handle_exists = FastLand::Shopify::Product.product_handle_exists?(handle: product_handle)
            unless product_handle_exists
              errors << detailed_error(error: INVALID_HANDLE, line: line)
            end
          when "tag"
            count[:row][:tag] += 1
            count[:value][:tag] = spec[row_index]&.compact.size
            tag = spec[row_index][1]
            # if tag.present? && product_tags.exclude?(tag)
            #   errors << detailed_error(error: INVALID_TAG, line: line)
            # end
          when "collection"
            count[:row][:collection] += 1
            count[:value][:collection] = spec[row_index]&.compact.size
            # Check collection handle validation
            collection_handle = spec[row_index][1]
            collection_handle_exists = FastLand::Shopify::Collection.collection_handle_exists?(handle: collection_handle)
            unless collection_handle_exists
              errors << detailed_error(error: INVALID_COLLECTION, line: line)
            end
          when "vendor"
            count[:row][:vendor] += 1
            count[:value][:vendor] = spec[row_index]&.compact.size
            vendor = spec[row_index][1]
            puts vendor
            if vendor.present? && vendor_not_exists(vendor: vendor)
              errors << detailed_error(error: INVALID_VENDOR, line: line)
            end
          when "virtual handle"
            count[:row][:virtual_handle] += 1
            count[:value][:virtual_handle] = spec[row_index]&.compact.size
            virtual_handle = spec[row_index][1]
            if virtual_handle.present? && virtual_handles.exclude?(virtual_handle)
              errors << detailed_error(error: INVALID_VIRTUAL_HANDLE, line: line)
            else
              vh_id = Vh.where(name: virtual_handle).first[:id]
              VirtualHandle.where(vh_id: vh_id, destination_id: destination_id).delete_all unless VirtualHandle.where(vh_id: vh_id, destination_id: destination_id) == nil
              newRow = VirtualHandle.new
              newRow.vh_id = vh_id
              puts destination_id
              newRow.destination_id = destination_id
              newRow.save
            end
          when "product_type"
            count[:row][:product_type] += 1
            count[:value][:product_type] = spec[row_index]&.compact.size
          when "template"
            template_name = spec[row_index][1]
            if template_name.present? && templates.exclude?(template_name)
              errors << detailed_error(error: INVALID_TEMPLATE, line: line)
            else
              $master_wizard_id = Template.where(name: template_name).first.wizard_id
            end
          when "width"
            index[:row][:data_header] = row_index
            count[:column][:width] += 1
            data_header_row = spec[row_index]&.map { |field| downcase(field) }
            # errors << INAVLID_DATA_HEADER if (data_headers - data_header_row).any?

            non_existence_errors = {
              behavior: NO_BEHAVIOR_COLUMN,
              configuration: NO_CONFIGURATION_COLUMN,
              # product: NO_PRODUCT_COLUMN,
              text1: NO_TEXT1_COLUMN,
              image1: NO_IMAGE1_COLUMN,
              link1: NO_LINK1_COLUMN
            }
            non_existence_errors.each do |key, value|
              col_index = data_header_row.index(key.to_s)
              col_index = col_index ? col_index : -1
              if col_index > 0
                index[:column][key] = col_index
              else
                errors << value
              end
            end
          when "wrappercode"
            puts ">> Wrappercode found"
            $wrappercode_array << [destination_id, spec[row_index][1]]
          else
            # Data rows
            if index[:row][:data_header] > 0 && row_index >= index[:row][:data_header] + 1
              # Configuration value validation
              if index[:column][:configuration] > 0
                configuration = spec[row_index][index[:column][:configuration]]
                if configuration.present?
                  if configuration == "new row"
                    index[:row][:new] = row_index
                    if spec[row_index]&.compact.size > 1
                      errors << detailed_error(error: INVALID_VALUES_NEW_ROW, line: line)
                    end
                  else
                    if configurations.exclude?(configuration)
                    # unless configurations.to_s.include?(configuration)
                      errors << detailed_error(error: INVALID_CONFIGURATION, line: line)
                    end
                  end
                else
                  errors << NO_CONFIGURATION_VALUE
                end
              end

              # Check width
              width = spec[row_index][0]
              if width.present?
                unless width.kind_of?(Float) || width.kind_of?(Integer)
                  errors << detailed_error(error: INVALID_WIDTH, line: line)
                end
              else
                errors << NO_WIDTH_VALUE if row_index >= index[:row][:data_header] + 1 && row_index != index[:row][:new]
              end

              # Behavior value validation
              if index[:column][:behavior] > 0
                behavior = spec[row_index][index[:column][:behavior]]
                if behavior.present?
                  if spec_behaviors.exclude?(behavior)
                    errors << detailed_error(error: INVALID_BEHAVIOR, line: line)
                  end
                else
                  errors << NO_BEHAVIOR_VALUE if row_index >= index[:row][:data_header] + 1 && row_index != index[:row][:new]
                end
              end

              # Image validation
              if index[:column][:image1] > 0
                image = spec[row_index][index[:column][:image1]]
                if image.present?
                  unless FastLand::Utils::Basic.url_exists?(url: base_url + image)
                    errors << detailed_error(error: INVALID_IMAGE, line: line)
                  end
                end
              end

              # Link validation
              if index[:column][:link1] > 0
                link = spec[row_index][index[:column][:link1]]
                # if link.present?
                #   unless FastLand::Utils::Basic.url?(string: link)
                #     errors << detailed_error(error: INVALID_URL, line: line)
                #   end
                # end
              end
            else
              error = "Invalid label on line #{row_index+1} of spec \"#{spec[index[:row][:parameter_header_start]][1]}\""
              errors << error
            end
          end
        end

        ## Parameter rows ##
        # no column validations
        errors << NO_NAME_ROW if count[:row][:name] == 0
        errors << NO_DESTINATION_ROW if count[:row][:destination] == 0
        if count[:row][:handle] + count[:row][:tag] + count[:row][:collection] + count[:row][:vendor] + count[:row][:product_type] + count[:row][:virtual_handle] == 0
          errors << NO_SHOPIFY_ROW
        end

        # Rows row count validation
        errors << MAX_NAME_COLUMNS_COUNT if count[:row][:name] > 1
        errors << MAX_DESTINATIONS_COUNT if count[:row][:destination] > 1

        # Paramter row value existence
        if count[:row][:name] > 0 && count[:value][:name] < 2
          errors << NO_NAME_VALUE
        end

        # Parameter row values count validation
        if count[:value][:name] > 2 || count[:value][:destination] > 2 || count[:value][:handle] > 2 ||
          count[:value][:tag] > 2 || count[:value][:collection] > 2 || count[:value][:vendor] > 2 ||
          count[:value][:product_type] > 2
          errors << MAX_VALUES_IN_COLUMN
        end

        ## Data header rows ##
        errors << NO_WIDTH_COLUMN if count[:column][:width] == 0
        errors
      end

      def vendor_not_exists(vendor:)
        FastLand::Shopify::Product.vendor_not_exists(vendor: vendor)
      end

      private
        def parameter_headers
          %w(
            name
            destination
            handle
            tag
            collection
            vendor
            producttype
          )
        end

        def data_headers
          %w(
            width
            behavior
            configuration
            product
            text1
            image1
            link1
          )
        end

        def spec_destinations
          %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
        end

        def spec_behaviors
          %w(stack resize)
        end

        def downcase(str)
          str&.to_s&.downcase
        end

        def is_row_empty(row:)
          !row.any?
        end

        def detailed_error(error:, line: nil)
          error = error.gsub("@line", line.to_s) if line.present?
          error
        end
    end
  end
end
