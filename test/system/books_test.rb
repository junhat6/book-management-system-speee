require "application_system_test_case"

class BooksTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit books_url
    assert_selector "h1", text: "蔵書一覧"
  end

  test "既存の著者・タグをチップから選んで本を登録できる" do
    tag = Tag.create!(name: "文学")
    sign_in_as users(:one)

    visit new_book_url
    fill_in "タイトル", with: "吾輩は猫である"
    fill_in "ISBN", with: "9784000000001"
    fill_in "出版年", with: "1905"
    fill_in "出版社", with: "岩波書店"

    find("label", text: authors(:one).name).click
    find("label", text: tag.name).click

    click_on "登録する"

    assert_text "吾輩は猫である"
    assert_text authors(:one).name
    assert_text tag.name
  end

  test "著者名で絞り込むと一致しないチップが隠れる" do
    sign_in_as users(:one)

    visit new_book_url

    assert_selector "label", text: authors(:one).name
    assert_selector "label", text: authors(:two).name

    fill_in "著者名で絞り込み", with: authors(:two).name

    assert_selector "label", text: authors(:two).name
    assert_no_selector "label", text: authors(:one).name
  end

  private

  def sign_in_as(user)
    visit new_session_url
    fill_in "メールアドレス", with: user.email_address
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    assert_text "ログインしました"
  end
end
