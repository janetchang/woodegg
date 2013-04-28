require 'sinatra'
root = File.dirname(File.dirname(File.realpath(__FILE__)))
require "#{root}/models.rb"

configure do
  # set root one level up, since this routes file is inside subdirectory
  set :root, root
  set :views, Proc.new { File.join(root, 'views/admin') }
end

use Rack::Auth::Basic, 'WoodEgg Admin' do |username, password|
  @@person = Person.find_by_email_pass(username, password)
end

before do
  redirect '/' unless @@person.admin?
  @person = @@person
end

get '/' do
  @pagetitle = 'admin home'
  @books_done = Book.done
  @books_not_done = Book.not_done
  erb :home
end

get '/book/:id' do
  @book = Book[params[:id]]
  @pagetitle = @book.title
  @done = @book.done?
  unless @done
    @questions_missing_essays = @book.questions_missing_essays
  end
  @questions = @book.questions
  @essays = @book.essays
  @editors = @book.editors
  @researchers = @book.researchers
  erb :book
end

get '/book/:id/questions' do
  @book = Book[params[:id]]
  @pagetitle = @book.title + ' questions'
  @questions = @book.questions
  erb :questions
end

get '/book/:id/essays' do
  @book = Book[params[:id]]
  @pagetitle = @book.title + ' essays'
  @essays = @book.essays
  # pre-load question for each essay into hash
  questions = @book.questions
  @question_for_essay = {}
  @essays.each do |e|
    @question_for_essay[e.id] = questions.select {|q| q[:id] == e.question_id}.pop
  end
  erb :essays
end
