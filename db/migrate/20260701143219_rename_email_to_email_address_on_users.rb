class RenameEmailToEmailAddressOnUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :email, :email_address
  end
end
