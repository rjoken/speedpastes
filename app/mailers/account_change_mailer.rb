class AccountChangeMailer < ApplicationMailer
    def confirm_change(request)
        @request = request
        @user = request.user

        token = request.signed_id(purpose: :account_change, expires_in: 2.hours)
        @url = account_change_url(token)

        mail(to: recipient_for(request), subject: subject_for(request))
    end

    private

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
        else
            "Confirm your account change"
        end
    end
end
