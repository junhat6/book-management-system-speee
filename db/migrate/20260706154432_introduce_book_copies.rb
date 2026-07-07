class IntroduceBookCopies < ActiveRecord::Migration[8.1]
  # 書誌（books）と物理的な1冊（book_copies）を分離し、
  # 貸出（rentals）を「本」ではなく「コピー」に紐づける。
  # 在庫数はコピーの行数から導出するため、カウンタの二重管理は行わない。
  def up
    create_table :book_copies do |t|
      t.references :book, null: false, foreign_key: true
      t.timestamps
    end

    add_reference :rentals, :book_copy, foreign_key: true

    # 既存データ移行: 各書籍に1冊のコピーを作り、既存の貸出をそのコピーへ付け替える
    execute <<~SQL
      INSERT INTO book_copies (book_id, created_at, updated_at)
      SELECT id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM books
    SQL
    execute <<~SQL
      UPDATE rentals
      SET book_copy_id = (
        SELECT book_copies.id FROM book_copies
        WHERE book_copies.book_id = rentals.book_id
      )
    SQL

    change_column_null :rentals, :book_copy_id, false

    remove_index :rentals, name: "index_rentals_on_book_id_when_active"
    remove_reference :rentals, :book, foreign_key: true

    # 「同じコピーのアクティブな貸出は同時に1件まで」を DB 層で保証する部分ユニーク index
    add_index :rentals, :book_copy_id,
              unique: true,
              where: "returned_at IS NULL",
              name: "index_rentals_on_book_copy_id_when_active"
  end

  def down
    add_reference :rentals, :book, foreign_key: true

    execute <<~SQL
      UPDATE rentals
      SET book_id = (
        SELECT book_copies.book_id FROM book_copies
        WHERE book_copies.id = rentals.book_copy_id
      )
    SQL

    change_column_null :rentals, :book_id, false

    remove_index :rentals, name: "index_rentals_on_book_copy_id_when_active"
    remove_reference :rentals, :book_copy, foreign_key: true

    add_index :rentals, :book_id,
              unique: true,
              where: "returned_at IS NULL",
              name: "index_rentals_on_book_id_when_active"

    drop_table :book_copies
  end
end
