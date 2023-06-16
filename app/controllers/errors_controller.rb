class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.js { render status: 404, json: {error: "not found"} }
      format.html { render status: 404 }
      format.all { render status: 404, formats: [:html] }
    end
  end

  def internal_error
    respond_to do |format|
      format.js { render status: 500, json: {error: "internal server error"} }
      format.html { render status: 500 }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.js { render status: 422, json: {error: "unprocessable entity"} }
      format.html { render status: 422 }
    end
  end
end
