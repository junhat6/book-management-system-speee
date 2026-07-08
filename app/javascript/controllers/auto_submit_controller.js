import { Controller } from "@hotwired/stimulus"

// select 等の change をトリガーに、検索ボタンを押さなくてもフォームを送信する
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
