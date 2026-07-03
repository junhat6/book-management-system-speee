class CreateRentals < ActiveRecord::Migration[8.1]
  def change
    create_table :rentals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.datetime :returned_at

      t.timestamps
    end

    # returned_at が NULL（貸出中）の行に限り book_id を一意にする
    add_index :rentals, :book_id, unique: true,
      where: "returned_at IS NULL",
      name: "index_rentals_on_book_id_when_active"
  end
end
