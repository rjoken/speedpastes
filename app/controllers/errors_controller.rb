class ErrorsController < ApplicationController
    def show
        @code = params[:code] || 500
        @message = params[:message] || "Internal Server Error"
        render status: @code
    end
end
