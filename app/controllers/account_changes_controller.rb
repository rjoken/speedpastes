class AccountChangesController < ApplicationController
    def show
        req = AccountChangeRequest.find_signed!(params[:token], purpose: :account_change)

        unless req.usable?
            return redirect_to root_path, alert: "This account change link has expired or has already been used"
        end

        User.transaction do
            case req.kind.to_sym
            when :email
                req.user.update!(email: req.new_email)
            when :username
                req.user.update!(username: req.new_username)
            when :password
                req.user.update!(password_digest: req.new_password_digest)
            end

            req.update!(used_at: Time.current)
        end

        redirect_to root_path, notice: "Your account has been updated successfully"
    rescue ActiveSupport::MessageVerifier::InvalidSignature
        redirect_to root_path, alert: "Invalid account change link"
    end
end
