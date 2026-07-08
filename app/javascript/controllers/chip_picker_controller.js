import { Controller } from "@hotwired/stimulus"

// 著者・タグをチップ状のチェックボックスで選ばせるUI。
// 検索欄への入力で候補を絞り込み、選択件数を表示する。
export default class extends Controller {
  static targets = ["query", "option", "count"]

  connect() {
    this.updateCount()
  }

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()

    this.optionTargets.forEach((option) => {
      const matches = option.dataset.name.includes(query)
      option.classList.toggle("hidden", !matches)
    })
  }

  updateCount() {
    const checkedCount = this.optionTargets.filter((option) =>
      option.querySelector("input[type=checkbox]").checked
    ).length

    this.countTarget.textContent = checkedCount > 0 ? `${checkedCount}件選択中` : ""
  }
}
