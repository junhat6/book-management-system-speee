module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :admin?
  end

  private
    def admin?
      authenticated? && Current.user.admin?
    end

    def require_admin
      redirect_to root_path, alert: "この操作は管理者のみ行えます。" unless admin?
    end
end
