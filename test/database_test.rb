require "minitest/autorun"
require "pg"

require_relative "../database_connection"

class DatabaseTest < Minitest::Test
  def setup
    @db = DatabaseConnection.new
  end

  def teardown
    @db.close
  end

  def create_template(name)
    db = PG.connect(dbname: 'ls_quiz')
    db.exec_params("INSERT INTO templates (name, created_on) VALUES ($1, $2)", [name, 'NOW()'])
    db.close
  end

  def delete_template(id)
    db = PG.connect(dbname: 'ls_quiz')
    db.exec_params("DELETE FROM questions WHERE template_id = $1", [id])
    db.exec_params("DELETE FROM templates WHERE id = $1", [id])
    db.close
  end

  def create_template_question(value, template_id)
    db = PG.connect(dbname: 'ls_quiz')
    db.exec_params("INSERT INTO questions (value, created_on, template_id) VALUES ($1, $2, $3)", [value, "NOW()", template_id])

    db.close
  end

  def create_test(template_id)
    db = PG.connect(dbname: 'ls_quiz')
    db.exec_params("INSERT INTO tests (created_on, template_id) VALUES ($1, $2)", ["NOW()", template_id])

    db.close
  end

  def delete_test(id)
    db = PG.connect(dbname: 'ls_quiz')
    db.exec_params("DELETE FROM tests WHERE id = $1", [id])

    db.close
  end

  def find_last_template_id
    db = PG.connect(dbname: 'ls_quiz')
    result = db.exec_params("SELECT MAX(id) FROM templates")

    db.close

    result.map do |tuple|
      {
        id: tuple["max"].to_i
      }
    end.first[:id]
  end

  def find_template(id)
    db = PG.connect(dbname: 'ls_quiz')
    result = db.exec_params("SELECT * FROM templates WHERE id = $1", [id])

    db.close

    result.map do |tuple|
      {
        id: tuple["max"].to_i,
        name: tuple["name"],
        created_on: tuple["created_on"]
      }
    end.first
  end

  def find_last_question_id
    db = PG.connect(dbname: 'ls_quiz')
    result = db.exec_params("SELECT MAX(id) FROM questions")

    db.close

    result.map do |tuple|
      {
        id: tuple["max"].to_i
      }
    end.first[:id]
  end

  def find_question(id)
    db = PG.connect(dbname: 'ls_quiz')
    result = db.exec_params("SELECT * FROM questions WHERE id = $1", [id]).map do |tuple|
      {
        question_id: tuple["id"],
        question_value: tuple["value"],
        created_on: tuple["created_on"],
        answer: tuple["answer"]
      }
    end.first

    db.close

    result
  end

  def find_last_test_id
    db = PG.connect(dbname: 'ls_quiz')
    result = db.exec_params("SELECT MAX(id) FROM tests")

    db.close

    result.map do |tuple|
      {
        id: tuple["max"].to_i
      }
    end.first[:id]
  end

  def find_answer(question_id, test_id)
    db = PG.connect(dbname: 'ls_quiz')
    result = db.exec_params("SELECT * FROM tests_questions WHERE question_id = $1 AND test_id = $2", [question_id, test_id])
    db.close

    result.map do |tuple|
      {
        id: tuple["id"].to_i,
        question_id: tuple["question_id"].to_i,
        test_id: tuple["test_id"].to_i,
        answer: tuple["answer"]
      }
    end.first
  end

  def add_answer(question_id, test_id, answer)
    db = PG.connect(dbname: 'ls_quiz')
    db.exec_params("INSERT INTO tests_questions (question_id, test_id, answer) VALUES ($1, $2, $3)", [question_id, test_id, answer])

    db.close
  end

  # all_templates
  # Returns an array of hashes
  def test_all_templates
    assert_instance_of(Array, @db.all_templates)
  end

  # create_new_template
  # Returns a hash that has an id
  def test_create_new_template_returns_hash
    new_template = @db.create_new_template("Test Template")
    assert_instance_of(Hash, new_template)

    delete_template(new_template[:id])
  end

  # find_template
  # returns a hash
  def test_find_template_returns_hash
    create_template("Test Template")
    template_id = find_last_template_id
    template = @db.find_template(template_id)

    assert_instance_of(Hash, template)

    delete_template(template_id)
  end

  # create_template_question
  # Ensures question is created
  def test_create_template_question_creates_question
    create_template("Test Template")
    template_id = find_last_template_id
    sample_question = "What is a closure?"

    @db.create_template_question(sample_question, template_id)

    # Connect to database
    # Find question in template
    # assert whether question was found in template
    pg_connection = PG.connect(dbname: 'ls_quiz')
    result = pg_connection.exec_params("SELECT * FROM questions WHERE value = $1", [sample_question]).map do |tuple|
      {
        value: tuple["value"]
      }
    end.first

    assert_equal(result[:value], sample_question)

    # Delete template
    delete_template(template_id)
  end

  # find_questions_for_template
  # returns an array of hashes
  def test_find_questions_for_template
    create_template("Test Template")
    template_id = find_last_template_id

    create_template_question("Template Question 1", template_id)
    create_template_question("Template Question 2", template_id)
    create_template_question("Template Question 3", template_id)

    result = @db.find_questions_for_template(template_id)

    assert_instance_of(Array, result)
    assert_equal(3, result.length)

    delete_template(template_id)
  end

  # update_template_name
  # Ensure that template name is updated
  def test_update_template_name
    create_template("Test Template")
    template_id = find_last_template_id
    new_name = "Renamed_Template"

    @db.update_template_name(template_id, new_name)

    template_name = find_template(template_id)[:name]
    assert_equal(new_name, template_name)

    delete_template(template_id)
  end

  # update_template_question
  # Ensure that template question is updated
  def test_update_template_question
    create_template("Test Template")
    template_id = find_last_template_id
    initial_question_value = "Question 1"
    revised_question_value = "Revised question 1"

    create_template_question(initial_question_value, template_id)
    question_id = find_last_question_id

    @db.update_template_question(question_id, revised_question_value)
    question = find_question(question_id)
    assert_equal(question[:question_value], revised_question_value)

    delete_template(template_id)
  end

  # delete_template
  # Ensure that template doesn't exist anymore
  def test_delete_template
    create_template("Test Template")
    template_id = find_last_template_id

    @db.delete_template(template_id)

    template = find_template(template_id)
    assert_nil(template)
  end

  # create_new_test
  # Ensure that method returns a hash
  def test_create_new_test
    # Create a new template
    # Create three questions
    # Create a new test
    # Assert that method returns a hash

    create_template("Test Template")
    template_id = find_last_template_id
    create_template_question("Question 1", template_id)
    create_template_question("Question 2", template_id)
    create_template_question("Question 3", template_id)

    test = @db.create_new_test(template_id)
    assert_instance_of(Hash, test)

    delete_template(template_id)
  end

  # find_test
  # Ensure that method returns a hash
  def test_find_test
    create_template("Test Template")
    template_id = find_last_template_id
    create_test(template_id)

    test = @db.find_test(find_last_test_id)
    assert_instance_of(Hash, test)

    delete_template(template_id)
  end

  # find_last_test_id
  # Ensure that method's last test id equals last_test_id
  def test_find_last_test_id
    create_template("Test Template")
    template_id = find_last_template_id
    create_test(template_id)
    last_test_id = @db.find_last_test_id

    assert_equal(last_test_id[:id], find_last_test_id)

    delete_template(template_id)
  end

  # find_tests_for_template
  # Ensure that method returns an array of hashes
  def test_find_tests_for_template
    create_template("Test Template")
    template_id = find_last_template_id
    create_test(template_id)
    tests = @db.find_tests_for_template(template_id)

    assert_instance_of(Array, tests)

    delete_template(template_id)
  end

  # add_answer
  # Ensure that method adds answer
  def test_add_answer
    create_template("Test Template")
    template_id = find_last_template_id
    create_template_question("Question 1", template_id)
    create_test(template_id)

    question_id = find_last_question_id
    test_id = find_last_test_id

    @db.add_answer(question_id, test_id, "Answer 1")
    answer = find_answer(question_id, test_id)[:answer]

    assert_equal(answer, "Answer 1")
    delete_template(template_id)
  end

  # find_questions_and_answers_for_test
  # Ensure that method returns an array of hashes
  def test_find_questions_answers_for_test
    create_template("Test Template")
    template_id = find_last_template_id
    create_template_question("Question 1", template_id)
    create_test(template_id)

    question_id = find_last_question_id
    test_id = find_last_test_id

    add_answer(question_id, test_id, "Answer 1")
    questions_and_answers = @db.find_questions_and_answers_for_test(test_id)

    assert_instance_of(Array, questions_and_answers)

    delete_template(template_id)
  end

  # delete_test_from_templates
  # Ensure that test is gone from templates
  def test_delete_test_from_templates
    create_template("Test Template")
    template_id = find_last_template_id
    create_test(template_id)
    test_id = find_last_test_id

    @db.delete_test_from_templates(test_id)

    refute_equal(test_id, find_last_test_id)

    delete_template(template_id)
  end
end
