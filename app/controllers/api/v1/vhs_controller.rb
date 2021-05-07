class Api::V1::VhsController < AuthenticatedController
  # Get VH list
  def index
    vhs = []
    vhs = Vh.all

    render json: {
      data: vhs
    }
  end

  # Add or Update VH
  def save
    if row_data[:id] == 0
      row = Vh.new
    else
      row = Vh.find(row_data[:id])
    end

    row.name = row_data[:name]
    row.exp1_type = row_data[:exp1_type]
    row.exp1_value = row_data[:exp1_value]
    row.exp2_type = row_data[:exp2_type]
    row.exp2_value = row_data[:exp2_value]
    row.condition = row_data[:condition]
    row.save

    render json: {
      data: Vh.all
    }
  end

  # Delete VH
  def delete
    Vh.delete(id)

    render json: {
      data: Vh.all
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
