-- DATABASE: woodegg
DROP SCHEMA IF EXISTS woodegg CASCADE;

BEGIN;

CREATE SCHEMA woodegg;
SET search_path = woodegg;

CREATE TABLE topics (
	id serial primary key,
	topic varchar(32)
);

CREATE TABLE subtopics (
	id serial primary key,
	topic_id integer not null REFERENCES topics(id),
	subtopic varchar(64)
);

-- {COUNTRY} instead of country name.
-- to normalize, to see same question across many countries
CREATE TABLE template_questions (
	id serial primary key,
	subtopic_id integer not null REFERENCES subtopics(id),
	question text
);
CREATE INDEX tqti ON template_questions(subtopic_id);

CREATE TABLE questions (
	id serial primary key,
	template_question_id integer not null REFERENCES template_questions(id),
	country char(2) not null,
	question text
);
CREATE INDEX qtqi ON questions(template_question_id);

CREATE TABLE answers (
	id serial primary key,
	question_id integer not null REFERENCES questions(id),
	person_id integer not null,
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	payable boolean,
	answer text,
	sources text
);
CREATE INDEX anqi ON answers(question_id);
CREATE INDEX anpi ON answers(person_id);
CREATE INDEX ansa ON answers(started_at);
CREATE INDEX anfa ON answers(finished_at);
CREATE INDEX anpy ON answers(payable);

CREATE TABLE books (
	id serial primary key,
	country char(2) not null,
	title text,
	isbn text
);

CREATE TABLE editors (
	id serial primary key,
	person_id integer not null UNIQUE,
	bio text
);

CREATE TABLE books_editors (
	book_id integer not null REFERENCES books(id),
	editor_id integer not null REFERENCES editors(id),
	PRIMARY KEY (book_id, editor_id)
);

CREATE TABLE researchers (
	id serial primary key,
	person_id integer not null UNIQUE,
	bio text
);

CREATE TABLE books_researchers (
	book_id integer not null REFERENCES books(id),
	researcher_id integer not null REFERENCES researchers(id),
	PRIMARY KEY (book_id, researcher_id)
);

CREATE TABLE essays (
	id serial primary key,
	question_id integer not null REFERENCES questions(id),
	person_id integer not null,
	book_id integer not null REFERENCES books(id),
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	payable boolean,
	cleaned_at timestamp(0) with time zone,
	cleaned_by varchar(24),
	content text,
	comment text
);
CREATE INDEX esqi ON essays(question_id);
CREATE INDEX espi ON essays(person_id);
CREATE INDEX essa ON essays(started_at);
CREATE INDEX esfa ON essays(finished_at);
CREATE INDEX espy ON essays(payable);
CREATE INDEX esca ON essays(cleaned_at);

COMMIT;