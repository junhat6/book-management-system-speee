class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "しばらく時間をおいてから再度お試しください。" }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "パスワード再設定用のメールを送信しました。メールの指示に従ってパスワードを再設定してください。"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "パスワードを再設定しました。"
    else
      redirect_to edit_password_path(params[:token]), alert: "パスワードが一致しませんでした。"
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "パスワード再設定用のリンクが無効か、有効期限が切れています。"
    end
end
