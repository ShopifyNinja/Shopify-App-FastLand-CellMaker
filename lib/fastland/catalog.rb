# frozen_string_literal: true

require "uri"
require "rest-client"

module FastLand
  module Catalog
    class << self
      def validate_user
        uri = URI("http://webservices.catalog-on-demand.com/aservices/api.do")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        request.set_form_data("Operation" => "ValidateUser", "UserID" => "#{ENV["CATALOG_USER"]}", "Password" => "#{ENV["CATALOG_PASSWORD"]}")
        response = http.request(request)

        return { status: false, error: "Failed to validate user - #{response.code} error" } unless response.code == "200"

        doc = Nokogiri::XML(response.read_body)
        session_id = doc.xpath("//SessionID")&.first&.content
        if session_id.nil?
          error = doc.xpath("//Error//Description")&.first&.content
          puts "ERROR - #{error}"
          { status: false, error: error }
        else
          customer_id = doc.xpath("//User//CustomerID")&.first&.content
          puts "INFO - session_id: #{session_id}, customer_id: #{customer_id}"
          { status: true, session_id: session_id, customer_id: customer_id }
        end
      end

      def process_cell_maker(session_id:, store_name:, file_path:, master_wizard_id:)
        base_url = Setting.last&.base_url

        return { status: false } unless base_url.present? && master_wizard_id.present?

        file_link = file_path&.sub("public/", "")
        file_link = [ENV["APP_DOMAIN"], file_link].join("/")

        uri = URI("http://webservices.catalog-on-demand.com/onDemandPublishingProcessor.do")
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 200
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(
          "Operation" => "ProcessCellMaker",
          "SessionID" => session_id,
          "StoreName" => store_name,
          "APIEndpoint" => "#{ENV["APP_DOMAIN"]}/api/v1/product",
          "BaseURL" => base_url,
          "MasterWizardID" => master_wizard_id,
          "FileLink" => file_link
        )
        response = http.request(request)

        return { status: false, error: "Failed to process job - #{response.code} error" } unless response.code == "200"

        doc = Nokogiri::XML(response.read_body)
        error = doc.xpath("//Error//Description")&.first&.content
        if error.present?
          return { status: false, error: error }
        end
        { status: true }
      end

      def configurations(customer_id:)
        response = RestClient.get "http://wizard.catalog-on-demand.com/api/results/customers/#{customer_id}/configurations"
        return [] unless response.code == 200
        result = JSON.parse(response.body)
        data = result.map { |res| res["name"][/\[(.*?)\]/, 1] }&.compact
        data + ["new row"]
      rescue Exception => e
        puts "ERROR - #{e.class}:#{e.message}"
      end
    end
  end
end
