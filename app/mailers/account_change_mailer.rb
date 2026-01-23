class AccountChangeMailer < ApplicationMailer
    def confirm_change(request)
        @request = request
        @user = request.user

        token = request.signed_id(purpose: :account_change, expires_in: 2.hours)
        @url = url_for_request(request, token)

        mail(to: recipient_for(request), subject: subject_for(request))
    end

    private

    def url_for_request(request, token)
        case request.kind.to_sym
        when :password_reset
            edit_password_reset_url(token: token)
        else
            account_change_url(token)
        end
    end

    def recipient_for(request)
        return request.new_email if request.email?

        request.user.email
    end

    def subject_for(request)
        case request.kind.to_sym
        when :email
            "Confirm your email change"
        when :username
            "Confirm your username change"
        when :password
            "Confirm your password change"
        when :password_reset
            "Confirm your password reset"
        else
            "Confirm your account change"
        end
    end
end
