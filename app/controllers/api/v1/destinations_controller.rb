class Api::V1::DestinationsController < AuthenticatedController
    # Get Destination list
    def index
      destinations = []
      destinations = Destination.all
  
      render json: {
        data: destinations
      }
    end
  
    # Add or Update Destination
    def save
      if row_data[:id] == 0
        row = Destination.new
      else
        row = Destination.find(row_data[:id])
      end
  
      row.destination = row_data[:destination]
      row.purpose_type = row_data[:purpose_type]
      row.dynamic_html = row_data[:dynamic_html]
      row.dynamic_html = '' if row_data[:purpose_type] == 0
      row.save

      domain = ShopifyAPI::Shop.current.myshopify_domain
      destination = Destination.find_by destination: row_data[:destination]
      method = 0
      method = 1 unless row_data[:id] == 0
      
      job_id = FastLand::Worker::DestinationJob.perform_async(domain, destination.id, method)
      
      session[:destination_job_id] = job_id

      render json: {status: true}
    end
  
    # Delete Destination
    def delete
      domain = ShopifyAPI::Shop.current.myshopify_domain
      destination = Destination.find(id)
      method = 2

      job_id = FastLand::Worker::DestinationJob.perform_async(domain, destination.id, method)
      
      session[:destination_job_id] = job_id

      render json: {status: true}
    end

    def is_working
      job_id = session[:destination_job_id]
      completed = Sidekiq::Status.complete? job_id
      working = Sidekiq::Status.working? job_id

      destinations = Destination.all
      render json: {
        completed: completed,
        working: working,
        destinations: destinations
      }
    end
  
    private
      def row_data
        params.require(:row_data)
      end
      def id
        params.require(:id)
      end
end
  