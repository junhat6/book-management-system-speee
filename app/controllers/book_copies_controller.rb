class BookCopiesController < ApplicationController
  before_action :set_book

  def create
    @book.copies.create!
    redirect_to @book, notice: "「#{@book.title}」の在庫を1冊追加しました。"
  end

  def destroy
    copy = @book.copies.find(params[:id])
    if copy.destroy
      redirect_to @book, notice: "「#{@book.title}」の在庫を1冊削除しました。", status: :see_other
    else
      redirect_to @book, alert: copy.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end
end
