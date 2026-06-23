class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.string :isbn
      t.integer :published_year
      t.string :publisher

      t.timestamps

      t.index :isbn, unique: true
    end
  end
end
