module BooksHelper
  # 一覧の絞り込み・並び替え状態を URL 間で引き継ぐための共通パラメータ。
  # page を含めないのは意図的：絞り込みや並び順が変わると同じページ番号は
  # 別の中身を指すため、常に1ページ目からやり直す
  def preserved_list_params(overrides = {})
    {
      q: params[:q].presence,
      tag_id: params[:tag_id].presence,
      sort: params[:sort].presence,
      direction: params[:direction].presence
    }.merge(overrides).compact
  end

  def sort_link(column, label)
    active = params[:sort] == column
    # 不正な direction はモデル側で昇順として扱うため、表示・トグルも昇順起点に揃える
    current_direction = params[:direction] == "desc" ? "desc" : "asc"
    next_direction = active && current_direction == "asc" ? "desc" : "asc"
    arrow = active ? (current_direction == "asc" ? " ▲" : " ▼") : ""

    link_to "#{label}#{arrow}",
            books_path(preserved_list_params(sort: column, direction: next_direction)),
            class: "link link-hover"
  end
end
