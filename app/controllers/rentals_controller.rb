class RentalsController < ApplicationController
  rescue_from ActiveRecord::RecordNotUnique, with: :book_already_rented

  before_action :set_book, only: :create

  def create
    @rental = @book.rentals.new(user: Current.user)
    if @rental.save
      redirect_to @book, notice: "「#{@book.title}」を借りました。"
    else
      redirect_to @book, alert: @rental.errors.full_messages.to_sentence
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def book_already_rented
    redirect_to @book, alert: "ちょうど貸出中になったため借りられませんでした。"
  end
end
