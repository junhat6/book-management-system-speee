class RenameBookCopiesToBookItems < ActiveRecord::Migration[8.1]
  # rename_index で部分インデックス（where: "returned_at IS NULL"）をそのままリネームすると
  # 条件が失われ通常のUNIQUE制約として再作成されてしまうため、この1本だけ明示的に張り直す
  def up
    rename_table :book_copies, :book_items
    rename_column :rentals, :book_copy_id, :book_item_id

    rename_index :book_items, "index_book_copies_on_book_id", "index_book_items_on_book_id"
    rename_index :rentals, "index_rentals_on_book_copy_id", "index_rentals_on_book_item_id"

    remove_index :rentals, name: "index_rentals_on_book_copy_id_when_active"
    add_index :rentals, :book_item_id,
              unique: true,
              where: "returned_at IS NULL",
              name: "index_rentals_on_book_item_id_when_active"
  end

  def down
    # この時点ではまだ rename_column（下の行）を実行していないため、
    # カラム名は book_item_id のまま（up の add_index と対称的な状態）
    remove_index :rentals, name: "index_rentals_on_book_item_id_when_active"
    add_index :rentals, :book_item_id,
              unique: true,
              where: "returned_at IS NULL",
              name: "index_rentals_on_book_copy_id_when_active"

    rename_index :rentals, "index_rentals_on_book_item_id", "index_rentals_on_book_copy_id"
    rename_index :book_items, "index_book_items_on_book_id", "index_book_copies_on_book_id"

    rename_column :rentals, :book_item_id, :book_copy_id
    rename_table :book_items, :book_copies
  end
end
