class Admin::UsersController < ApplicationController
    before_action :require_login!
    before_action :require_admin!
    before_action :set_user

    def invite_codes
        @invite_codes = InviteCode.where(created_by_id: @user.id).order(created_at: :desc)
    end

    def generate_invite_codes
        count = 5
        InviteCodes::Generate.call(user: @user, count: count)

        redirect_to profile_path(@user.id), notice: "Generated #{count} invite codes for #{@user.username}."
    end

    def ban
        if @user == current_user
            return redirect_to profile_path(@user.id), alert: "You cannot ban yourself."
        end

        if @user.admin?
            return redirect_to profile_path(@user.id), alert: "You cannot ban another admin."
        end

        Users::Anonymize.call(user: @user)
        redirect_to root_path, notice: "Bomb has been planted."
    end

    def remove_avatar
        @user.avatar.purge_later
        redirect_to profile_path(@user.id), notice: "User avatar has been removed."
    end

    private

    def require_admin!
        redirect_to root_path, alert: "Not authorized" unless current_user&.admin?
    end

    def set_user
        @user = User.find_by!("lower(username) = ?", params[:user_username].to_s.downcase)
    end
end
