ENV['testing'] = 'test'
require 'test/unit'
require_relative '../models.rb'

class TestResearcher < Test::Unit::TestCase
  include Fixtures::Tools

  def test_researcher
    x = Researcher[1]
    assert_equal x.name, @fixtures['Person']['gongli']['name']
    assert_equal x.email, @fixtures['Person']['gongli']['email']
    x = Researcher[2]
    assert_equal x.name, @fixtures['Person']['yoko']['name']
    assert_equal x.email, @fixtures['Person']['yoko']['email']
    x = Researcher[3]
    assert_equal x.name, @fixtures['Person']['oompa']['name']
    assert_equal x.email, @fixtures['Person']['oompa']['email']
    rap = Researcher.all_people
    assert_equal 3, rap.count
    assert_equal({:active => true, :id=>2, :person_id=>8, :bio=>'Yes I am Yoko Ono', :name=>'Yoko Ono', :email=>'yoko@ono.com'}, rap[1].values)
  end

  def test_researcher_assocations
    assert_equal [6,7,8,9], Researcher[2].answers.map(&:id)
    assert_equal [], Researcher[3].answers
    assert_equal [Book[3]], Researcher[3].books
    assert_equal [], Researcher[1].topics_unfinished
    assert_equal [Topic[2]], Researcher[2].topics_unfinished
    assert_equal [Topic[1],Topic[2]], Researcher[3].topics_unfinished
    assert_equal [], Researcher[1].subtopics_unfinished_in_topic(2)
    assert_equal [], Researcher[2].subtopics_unfinished_in_topic(1)
    assert_equal [Subtopic[3],Subtopic[4]], Researcher[2].subtopics_unfinished_in_topic(2)
    assert_equal [Subtopic[1],Subtopic[2]], Researcher[3].subtopics_unfinished_in_topic(1)
    assert_equal [Subtopic[3],Subtopic[4]], Researcher[3].subtopics_unfinished_in_topic(2)
    assert_equal [Question[3],Question[4]], Researcher[3].questions_unfinished_in_subtopic(3)
    assert_equal 5, Researcher[1].answers_finished_count
    assert_equal [5,4,3,2,1], Researcher[1].answers_finished.map(&:id)
    assert_equal 3, Researcher[2].answers_finished_count
    assert_equal [8,7,6], Researcher[2].answers_finished.map(&:id)
    assert_equal 0, Researcher[3].answers_finished_count
    assert_equal [], Researcher[3].answers_finished
    assert_equal [1,2,3,4,5], Researcher[1].questions_answered.map(&:id)
    assert_equal [6,7,8], Researcher[2].questions_answered.map(&:id)
    assert_equal [], Researcher[3].questions_answered
    assert_equal Book[3].questions, Researcher[3].questions
    assert_equal [], Researcher[1].questions_unanswered
    assert_equal [Question[9],Question[10]], Researcher[2].questions_unanswered
    assert_equal [1,2,3,4,5], Researcher[3].questions_unanswered.map(&:id)
    assert_equal [Answer[9]], Researcher[2].answers_unfinished
    assert_equal [], Researcher[3].answers_unfinished
    assert_equal [Answer[6],Answer[7]], Researcher[2].answers_unpaid
    assert_equal [Answer[4],Answer[5]], Researcher[1].answers_unjudged
    assert_equal [6,7,8,9], Researcher[2].question_ids_answered
    assert_equal [], Researcher[3].question_ids_answered
    assert_equal 0, Researcher[1].howmany_unassigned
    assert_equal 1, Researcher[2].howmany_unassigned
    assert_equal 5, Researcher[3].howmany_unassigned
  end

  def test_new_researcher
    r = Researcher.create(person_id: 6)
    r.add_book(Book[2])
    assert_equal 5, r.howmany_unassigned
    assert_equal [6,7,8,9,10], r.questions_unanswered.map(&:id)
  end

  def test_researcher_without_books
    Researcher.create(person_id: 6)
    assert_equal [Researcher[4]], Researcher.without_books
  end
end

class TestWriter < Test::Unit::TestCase
  include Fixtures::Tools

  def test_writer
    x = Writer[1]
    assert_equal x.name, @fixtures['Person']['veruca']['name']
    assert_equal x.email, @fixtures['Person']['veruca']['email']
    x = Writer[2]
    assert_equal x.name, @fixtures['Person']['charlie']['name']
    assert_equal x.email, @fixtures['Person']['charlie']['email']
  end

  def test_writer_without_books
    Writer.create(person_id: 6)
    assert_equal [Writer[3]], Writer.without_books
  end
end

class TestCustomer < Test::Unit::TestCase
  include Fixtures::Tools

  def test_customer
    x = Customer[1]
    assert_equal x.name, @fixtures['Person']['augustus']['name']
    assert_equal x.email, @fixtures['Person']['augustus']['email']
  end
end

class TestEditor < Test::Unit::TestCase
  include Fixtures::Tools

  def test_editor
    x = Editor[1]
    assert_equal x.name, @fixtures['Person']['derek']['name']
    assert_equal x.email, @fixtures['Person']['derek']['email']
    x = Editor[2]
    assert_equal x.name, @fixtures['Person']['wonka']['name']
    assert_equal x.email, @fixtures['Person']['wonka']['email']
  end

  def test_editor_essays
    x = Editor[2]
    assert_equal [Essay[6]], x.essays_edited
    assert_equal [Essay[7],Essay[8]], x.essays_unedited
    assert_equal [Question[6]], x.questions_edited
    assert_equal [Question[7],Question[8]], x.questions_unedited
  end

  def test_editor_without_books
    Editor.create(person_id: 6)
    assert_equal [Editor[3]], Editor.without_books
  end
end

class TestTopic < Test::Unit::TestCase
  include Fixtures::Tools

  def test_topic
    x = Topic[1]
    assert_equal 'Country', x.topic
    assert_equal [Subtopic[1], Subtopic[2]], x.subtopics
  end

  def test_topic_assocations
    x = Topic[2]
    assert_equal [TemplateQuestion[3], TemplateQuestion[4], TemplateQuestion[5]], x.template_questions
    assert_equal [3,4,5,8,9,10], x.questions.map(&:id)
  end
end

class TestSubtopic < Test::Unit::TestCase
  include Fixtures::Tools

  def test_subtopic
    x = Subtopic[3]
    assert_equal 'is it fun?', x.subtopic
    assert_equal Topic[2], x.topic
    assert_equal [TemplateQuestion[3], TemplateQuestion[4]], x.template_questions
  end

  def test_subtopic_questions
    x = Subtopic[3]
    assert_equal [Question[3], Question[4], Question[8], Question[9]], x.questions
    assert_equal [Question[3], Question[4]], x.questions_for_country('CN')
  end
end

class TestTemplateQuestion < Test::Unit::TestCase
  include Fixtures::Tools

  def test_template_question
    x = TemplateQuestion[1]
    assert_equal 'how big is {COUNTRY}?', x.question
    assert_equal Subtopic[1], x.subtopic
    assert_equal Topic[1], x.topic
    assert_equal [Question[1], Question[6]], x.questions
  end

  def test_template_question_assocations
    x = TemplateQuestion[3]
    assert_equal [Answer[3], Answer[8]], x.answers
    assert_equal [Essay[3],Essay[8]], x.essays
  end
end

class TestQuestion < Test::Unit::TestCase
  include Fixtures::Tools

  def test_question
    x = Question[1]
    assert_equal 'how big is China?', x.question
    assert_equal [Book[1], Book[3]], x.books
    assert_equal [Answer[1]], x.answers
    assert_equal [Essay[1]], x.essays
    assert_equal TemplateQuestion[1], x.template_question
    assert_equal Subtopic[1], x.subtopic
    assert_equal Topic[1], x.topic
    assert_equal [Researcher[1]], x.researchers
    assert_equal [Editor[1]], x.editors
    assert_equal [], x.tidbits
    x = Question[4]
    assert_equal [Tidbit[1]], x.tidbits
  end

  def test_question_class
    assert_equal 5, Question.total_for_country('CN')
    assert_equal 0, Question.total_for_country('ZZ')
    assert_equal({1=>'how big is China?', 2=>'how old is China?', 3=>'what is fun in China?', 4=>'do they laugh in China?', 5=>'what language in China?'}, Question.hash_for_country('CN'))
    assert_equal [Question[3],Question[4]], Question.for_subtopic_and_country(3, 'CN')
    assert_equal({6=>{topic: 'Country', subtopic: 'how big'}, 7=>{topic: 'Country', subtopic: 'how old'}, 8=>{topic: 'Culture', subtopic: 'is it fun?'}, 9=>{topic: 'Culture', subtopic: 'is it fun?'}, 10=>{topic: 'Culture', subtopic: 'what language?'}}, Question.topichash('JP'))
    th = Question.topicnest(Book[2].questions, Question.topichash('JP'))
    assert_equal 2, th.size
    assert_equal({'how big' => [Question[6]], 'how old' => [Question[7]]}, th['Country'])
    assert_equal({1 => Question[1], 3=> Question[3]}, Question.for_these(Answer.where(id: [1,3]).all))
    assert_equal({2 => Question[2], 4=> Question[4]}, Question.for_these(Essay.where(id: [2,4]).all))
  end
end

class TestAnswer < Test::Unit::TestCase
  include Fixtures::Tools

  def test_answer
    x = Answer[7]
    assert_equal Question[7], x.question
    assert_equal Researcher[2], x.researcher
    assert_equal [Essay[7]], x.essays
    assert_equal [Book[2]], x.books
    assert_equal Subtopic[2], x.subtopic
    assert_equal Topic[1], x.topic
    assert x.finished?
    refute Answer[9].finished?
  end

  def test_answer_class
    assert_equal [Answer[4], Answer[5]], Answer.unjudged
    assert_equal [Answer[9]], Answer.unfinished
    assert_equal({'CN' => 5, 'JP' => 4}, Answer.count_per_country_hash)
  end

  def test_answer_fj
    assert_equal Answer[4], Answer.unjudged_next
    assert_equal Answer[9], Answer.unfinished_next
  end
end

class TestBook < Test::Unit::TestCase
  include Fixtures::Tools

  def test_book
    x = Book[1]
    assert_equal 'China 2013: How To', x.title
    assert_equal 'China 2013', x.short_title
    assert_equal 'How To', x.sub_title
    assert_equal({'pdf' => 'ChinaStartupGuide2013.pdf', 'epub' => 'ChinaStartupGuide2013.epub', 'mobi' => 'ChinaStartupGuide2013.mobi'}, x.filename_hash)
  end

  def test_download_url
    # https://s3-ap-southeast-1.amazonaws.com/woodegg/ChinaStartupGuide2013.pdf?AWSAccessKeyId=BLAHBLAHBLAH&Expires=1372837301&Signature=bLaHbLaH
    x = Book[1]
    u = x.download_url('pdf')
    assert_match /^https:\/\//, u
    assert u.include? 'ChinaStartupGuide2013.pdf'
    assert_match /AWSAccessKeyId=[A-Z0-9]{20}&/, u
    assert_match /Expires=\d+&/, u
    assert_match /Signature=\S+\Z/, u
  end

  def test_book_associations
    x = Book[1]
    assert_equal 2, x.topics.size
    assert_equal 'Country', x.topics[0].topic
    assert_equal 4, x.subtopics.size
    assert_equal 'how big', x.subtopics[0].subtopic
    assert_equal 5, x.template_questions.size
    assert_equal 'how big is {COUNTRY}?', x.template_questions[0].question
    assert_equal [1,2,3,4,5], x.questions.map(&:id)
    assert x.questions.map(&:question).all? {|q| q.include? 'China'}
    assert_equal [1,2,3,4,5], x.answers.map(&:id)
    assert x.answers.map(&:answer).all? {|q| q.include? 'China'}
    assert_equal [1,2,3,4,5], x.essays.map(&:id)
    assert x.essays.map(&:content).all? {|q| q.include? 'China'}
    assert_equal [Researcher[1]], x.researchers
    assert_equal [Writer[1]], x.writers
    assert_equal [Editor[1]], x.editors
    assert_equal [Customer[1]], x.customers
    x = Book[3]
    assert_equal [1,2,3,4,5], x.questions.map(&:id)
    assert_equal [1,2,3,4,5], x.answers.map(&:id)
    assert_equal [], x.essays
  end

  def test_books
    assert_equal [Book[1],Book[2],Book[3]], Book.order(:id).all
    assert_equal [Book[1]], Book.available
    assert_equal [Book[1]], Book.done
    assert_equal [Book[2],Book[3]], Book.not_done
    assert Book[1].done?
    refute Book[2].done?
    refute Book[3].done?
  end

  def test_books_missing
    assert_equal [], Book[1].questions_missing_essays
    assert_equal 0, Book[1].questions_missing_essays_count
    assert_equal [Question[10]], Book[2].questions_missing_essays
    assert_equal 1, Book[2].questions_missing_essays_count
    assert_equal [], Book[1].essays_unedited.all
    assert_equal 2, Book[2].essays_unedited.count
    assert_equal [Essay[7],Essay[8]], Book[2].essays_unedited.all
  end

end

class TestEssay < Test::Unit::TestCase
  include Fixtures::Tools

  def test_essay
    x = Essay[1]
    assert_equal Writer[1], x.writer
    assert_equal [Editor[1]], x.editors
    assert_equal Book[1], x.book
    assert_equal Question[1], x.question
    assert_equal Subtopic[1], x.subtopic
    assert_equal Topic[1], x.topic
    assert Essay[1].finished?
    refute Essay[9].finished?
  end

  def test_essay_class
    assert_equal [Essay[8]], Essay.unjudged
    assert_equal [Essay[9]], Essay.unfinished
    assert_equal [Essay[6],Essay[7],Essay[8],Essay[9]], Essay.for_country('JP')
    assert_equal({'CN' => 5, 'JP' => 4}, Essay.country_howmany)
    assert_equal 2, Essay.howmany_unedited
    assert_equal Essay[7], Essay.next_unedited_for(2)
    assert_equal Essay[8], Essay.next_unedited
  end

end

class TestTag < Test::Unit::TestCase
  include Fixtures::Tools

  def test_tag
    x = Tag[1]
    assert_equal 'China', x.name
    assert_equal [Tidbit[1]], x.tidbits
  end
end

class TestTidbit < Test::Unit::TestCase
  include Fixtures::Tools

  def test_tidbit
    x = Tidbit[1]
    assert /China/ === x.content
    x = Tidbit[2]
    assert /Japan/ === x.content
    assert_equal [Question[6],Question[7]], x.questions
    assert_equal [Tag[2]], x.tags
  end
end

class TestUpload < Test::Unit::TestCase
  include Fixtures::Tools

  def test_upload
    r = Researcher[3]
    x = Upload[3]
    assert_equal 3, r.uploads.count
    assert_equal x, r.uploads.pop
    assert_equal r, x.researcher
  end

  def test_uploaded_status
    assert_equal 'uploaded', Upload[1].uploaded_status
    assert_match /uploading/, Upload[2].uploaded_status
    assert_match /not uploaded/, Upload[3].uploaded_status
  end

  def test_missing_info
    assert_equal [Upload[2], Upload[3]], Upload.missing_info.all
    r = Researcher[3]
    assert_equal [Upload[2], Upload[3]], Upload.missing_info_for(r.id)
    refute Upload[1].missing_info?
    assert Upload[2].missing_info?
    assert Upload[3].missing_info?
  end
end

