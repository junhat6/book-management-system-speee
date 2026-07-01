fitzgerald = Author.create!(name: "F. Scott Fitzgerald")
lee = Author.create!(name: "Harper Lee")

gatsby = Book.create!(
  title: "The Great Gatsby",
  isbn: "978-3-16-148410-0",
  published_year: 1925,
  publisher: "Scribner",
  authors: [ fitzgerald ]
)

mockingbird = Book.create!(
  title: "To Kill a Mockingbird",
  isbn: "978-0-06-112008-4",
  published_year: 1960,
  publisher: "J.B. Lippincott & Co.",
  authors: [ lee ]
)
