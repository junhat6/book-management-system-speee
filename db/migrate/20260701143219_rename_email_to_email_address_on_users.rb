class RenameEmailToEmailAddressOnUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :email, :email_address
    rename_index :users, :index_users_on_email, :index_users_on_email_address
  end
end
