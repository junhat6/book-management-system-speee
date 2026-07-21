class BookItemsController < ApplicationController
  before_action :require_admin
  before_action :set_book

  def create
    @book.items.create!
    redirect_to @book, notice: "「#{@book.title}」の在庫を1冊追加しました。"
  end

  def destroy
    item = @book.items.find(params[:id])
    if item.destroy
      redirect_to @book, notice: "「#{@book.title}」の在庫を1冊削除しました。", status: :see_other
    else
      redirect_to @book, alert: item.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end
end
