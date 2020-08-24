CREATE TABLE questions (
    id integer NOT NULL,
    value text NOT NULL,
    created_on date NOT NULL,
    template_id integer
);

CREATE TABLE templates (
    id integer NOT NULL,
    name text,
    created_on date
);

CREATE TABLE tests (
    id integer NOT NULL,
    created_on date NOT NULL,
    template_id integer
);

CREATE TABLE tests_questions (
    id integer NOT NULL,
    question_id integer NOT NULL,
    test_id integer NOT NULL,
    answer text
);
