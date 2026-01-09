class ScratchpadsController < ApplicationController
  before_action :require_login!
  before_action :set_scratchpad

  def show
  end

  def update
    if @scratchpad.update(scratchpad_params)
        respond_to do |format|
            format.json { head :no_content }
        end
    else
        respond_to do |format|
            format.json { render json: @scratchpad.errors.full_messages.to_sentence, status: :unprocessable_entity }
        end
    end
  end

  private

  def set_scratchpad
    @scratchpad = current_user.scratchpad || current_user.build_scratchpad
  end

  def scratchpad_params
    params.require(:scratchpad).permit(:body)
  end
end
