# frozen_string_literal: true

class Api::V1::FilesController < AuthenticatedController
  def parse
    uploaded_file = params[:file]
    file_path = FastLand::Utils::Basic.local_file(file_name: uploaded_file.original_filename)
    File.open(file_path, "wb") { |f| f.write(uploaded_file.read) }
    job_id = FastLand::Worker::Parse.perform_async(file_path)

    session[:job_id] = job_id

    render json: { status: true }
  end

  def is_parsing
    job_id = session[:job_id]
    completed = Sidekiq::Status.complete? job_id
    working = Sidekiq::Status.working? job_id
    errors = Sidekiq::Status.get job_id, :errors
    errors = errors&.split("|")

    render json: { completed: completed, working: working, errors: errors }
  end

  private
    def file_params
      params.require(:file).permit(:file_name)
    end
end
