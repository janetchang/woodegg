require 'erb'
include ERB::Util
require 'sinatra'
require 'kramdown'
root = File.dirname(File.dirname(File.realpath(__FILE__)))
require "#{root}/models.rb"
require "#{root}/mailconfig.rb"

configure do
  set :root, root
  set :views, Proc.new { File.join(root, 'views/admin') }
end

use Rack::Auth::Basic, 'WoodEgg Admin' do |username, password|
  HTTPAuth.person = Person.find_by_email_pass(username, password)
end

before do
  redirect '/' unless HTTPAuth.person.admin?
  @person = HTTPAuth.person
end

# of submitted params, get only the ones with these keys
# USAGE:
#   Thought.update(just(%w(author_id contributor_id created_at source_url)))
def just(keyz)
  params.select {|k, v| keyz.include? k}
end

get '/' do
  @pagetitle = 'home'
  @userstats = Userstat.filter(:statkey.like 'proof%').all
  erb :home
end

post '/proof' do
  u = Userstat[params[:uid]]
  raise('no Userstat for %d' % params[:uid]) if u.nil?
  if params[:submit] == 'no'
    u.update(statkey: u.statkey.gsub('proof', 'nope'))
    redirect '/'
  else
    /proof-we13([a-z]{2})/.match u.statkey
    b = Book[country: $1.upcase]
    raise('no Book for %s' % $1.upcase) if b.nil?
    p = u.person
    raise('no Person for u %d with person_id %d' % [u.id, u.person_id]) if p.nil?
    c = p.customer
    # if they weren't a customer before, they are now!
    if c.nil?
      c = Customer.create(person_id: p.id)
      has_books = []
    else
      has_books = c.books
    end
    c.add_book(b) unless has_books.include? b
    c.email_post_proof(b)
    u.update(statkey: u.statkey.gsub('proof', 'bought'))
    redirect '/'
  end
end

get '/books' do
  @pagetitle = 'books'
  @books_done = Book.done
  erb :books
end

get '/book/:id' do
  @book = Book[params[:id]]
  @pagetitle = @book.short_title
  @done = @book.done?
  unless @done
    @questions_missing_essays = @book.questions_missing_essays
    @essays_uncleaned = @book.essays_uncleaned.all
  end
  @questions = @book.questions
  @essays = @book.essays
  @editors = @book.editors
  @researchers = @book.researchers
  erb :book
end

put '/book/:id' do
  b = Book[params[:id]]
  b.update(just(%w(title isbn asin leanpub intro salescopy)))
  redirect '/book/%d' % b.id
end

get '/book/:id/questions' do
  @book = Book[params[:id]]
  @pagetitle = @book.short_title + ' questions'
  @topicnest = Question.topicnest(@book.questions, Question.topichash(@book.country))
  erb :questions
end

get '/book/:id/essays' do
  @book = Book[params[:id]]
  @pagetitle = @book.short_title + ' essays'
  @essays = @book.essays
  @question_for_essay = Question.for_these(@essays)
  erb :essays
end

get '/essay/:id' do
  @essay = Essay[params[:id]]
  @pagetitle = 'essay #%d' % @essay.id
  erb :essay
end

put '/essay/:id' do
  e = Essay[params[:id]]
  e.update(just(%w(started_at finished_at payable cleaned_at cleaned_by content comment)))
  redirect '/essay/%d' % e.id
end

get '/question/:id' do
  @question = Question[params[:id]]
  @pagetitle = 'question #%d' % @question.id
  erb :question
end

get '/answer/:id' do
  @answer = Answer[params[:id]]
  @pagetitle = 'answer #%d' % @answer.id
  @question = @answer.question
  @researcher = @answer.researcher
  erb :answer
end

put '/answer/:id' do
  a = Answer[params[:id]]
  a.update(just(%w(started_at finished_at payable answer sources)))
  redirect '/answer/%d' % a.id
end

get '/editor/:id' do
  @editor = Editor[params[:id]]
  @pagetitle = 'EDITOR: %s' % @editor.name
  @person_url = WoodEgg.config['woodegg_person_url'] % @editor.person_id
  erb :editor
end

get %r{/editor/([0-9]+)/essays/(finished|unfinished|unpaid|unjudged)} do |id,filtr|
  @editor = Editor[id]
  @pagetitle = "#{filtr} essays for #{@editor.name}"
  @essays = @editor.send("essays_#{filtr}")
  @question_for_essays = Question.for_these(@essays)
  erb :editor_essays
end

put '/editor/:id' do
  e = Editor[params[:id]]
  e.update(just(%w(bio)))
  redirect '/editor/%d' % e.id
end

post '/editor/:id/approval' do
  e = Editor[params[:id]]
  e.approve_finished_unjudged_essays
  redirect '/editor/%d' % e.id
end

get '/researcher/:id' do
  @researcher = Researcher[params[:id]]
  @pagetitle = 'RESEARCHER: %s' % @researcher.name
  @person_url = WoodEgg.config['woodegg_person_url'] % @researcher.person_id
  @ok_to_delete = (@researcher.answers_dataset.count == 0) ? true : false
  erb :researcher
end

get %r{/researcher/([0-9]+)/answers/(finished|unfinished|unpaid|unjudged)} do |id,filtr|
  @researcher = Researcher[id]
  @pagetitle = "#{filtr} answers for #{@researcher.name}"
  @answers = @researcher.send("answers_#{filtr}")
  @question_for_answers = Question.for_these(@answers)
  erb :researcher_answers
end

put '/researcher/:id' do
  r = Researcher[params[:id]]
  r.update(just(%w(bio)))
  redirect '/researcher/%d' % r.id
end

delete '/researcher/:id' do
  r = Researcher[params[:id]]
  r.destroy
  redirect '/researchers'
end

get '/researchers' do
  @pagetitle = 'researchers'
  @researchers = Researcher.all_people.sort_by(&:name)
  erb :researchers
end

post '/researchers' do
  x = Researcher.create(person_id: params[:person_id].to_i)
  redirect '/researcher/%d' % x.id
end

get '/editors' do
  @pagetitle = 'editors'
  @editors = Editor.order(:id).all
  erb :editors
end

post '/editors' do
  x = Editor.create(person_id: params[:person_id].to_i)
  redirect '/editor/%d' % x.id
end

get '/customers' do
  @pagetitle = 'all customers'
  @customers = Customer.order(:id).all
  @person_id = params[:person_id]
  erb :customers
end

post '/customers' do
  c = Customer.create(person_id: params[:person_id])
  redirect '/customer/%d' % c.id
end

get '/book/:id/customers' do
  @book = Book[params[:id]]
  @pagetitle = 'customers of ' + @book.short_title
  @customers = @book.customers
  erb :customers
end

get '/customer/:id' do
  @customer = Customer[params[:id]]
  @pagetitle = 'customer: ' + @customer.name
  @books = @customer.books
  @books_to_add = Book.order(:title).all - @books
  @person_url = WoodEgg.config['woodegg_person_url'] % @customer.person_id
  @sent = params[:sent]
  erb :customer
end

post '/customer/:id/books' do
  c = Customer[params[:id]]
  has_books = c.books
  if params[:book_id] == 'all'
    Book.all.each do |b|
      c.add_book(b) unless has_books.include? b
    end
  else
    b = Book[params[:book_id]]
    unless b.nil?
      c.add_book(b) unless has_books.include? b
    end
  end
  redirect '/customer/%d' % c.id
end

post '/customer/:id/email' do
  c = Customer[params[:id]]
  opts = {}
  unless params[:subject].empty?
    opts[:subject] = params[:subject]
  end
  unless params[:message].empty?
    opts[:message] = params[:message]
  end
  c.email_first(opts)
  redirect '/customer/%d?sent=sent' % c.id
end

get '/stats' do
  @pagetitle = 'stats'
  @grid = Countries.userstats_grid
  @person_url_d = WoodEgg.config['woodegg_person_url']
  @newest = Userstat.newest_woodegg
  erb :stats
end

get '/stats/:country/:val' do
  @country_code = params[:country]
  @country_name = Countries.hsh[@country_code] || 'Any Country'
  @val = params[:val]
  @pagetitle = @country_name + ' ' + @val
  @people = Person.country_val(@country_code, @val)
  @person_url_d = WoodEgg.config['woodegg_person_url']
  erb :stats2
end

get '/tidbits' do
  if params[:tag_id]
    @tidbits = Tag[params[:tag_id]].tidbits
  else
    @tidbits = Tidbit.order(:id.desc).all
  end
  @all_tags = Tag.order(:name).all
  erb :tidbits
end

post '/tidbits' do
  t = Tidbit.create(created_at: Time.now())
  redirect '/tidbit/%d' % t.id
end

get '/tidbit/:id' do
  @tidbit = Tidbit[params[:id]]
  @all_tags = Tag.order(:name).all
  erb :tidbit
end

put '/tidbit/:id' do
  t = Tidbit[params[:id]]
  t.update(just(%w(created_at created_by url intro content)))
  redirect '/tidbit/%d' % t.id
end

delete '/tidbit/:id' do
  t = Tidbit[params[:id]]
  t.destroy
  redirect '/tidbits'
end

post '/tidbit/:id/tags' do
  t = Tidbit[params[:id]]
  # can post either tag_name, to make new, or tag_id, to use existing
  tag = nil
  if params[:tag_name].empty? == false
    tag = Tag.create(name: params[:tag_name])
  elsif params[:tag_id].to_i > 0
    tag = Tag[params[:tag_id]]
  end
  t.add_tag(tag) if tag
  redirect '/tidbit/%d' % t.id
end

post '/tidbit/:id/questions' do
  t = Tidbit[params[:id]]
  t.add_question(Tag[params[:question_id]])
  redirect '/tidbit/%d' % t.id
end

delete '/tidbit/:id/tag/:tag_id' do
  t = Tidbit[params[:id]]
  t.remove_tag(Tag[params[:tag_id]])
  redirect '/tidbit/%d' % t.id
end

delete '/tidbit/:id/question/:question_id' do
  t = Tidbit[params[:id]]
  t.remove_question(Question[params[:question_id]])
  redirect '/tidbit/%d' % t.id
end

