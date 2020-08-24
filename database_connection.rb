# Create a class that interacts with the database
require 'pg'


class DatabaseConnection
  def initialize
    @connection = PG.connect(dbname: 'ls_quiz')
    setup_schema
  end

  def close
    @connection.close
  end

def all_templates
  # Input: None
  # Output: An array of hashes where each hash represents a template
  # Return an array of hashes

  result = @connection.exec_params("SELECT * FROM templates")

  result.map do |tuple|
    {
      template_id: tuple["id"].to_i,
      template_name: tuple["name"],
      created_on: tuple["created_on"],
    }
  end
end

def create_new_template(name, created_on='NOW()')
  # Input: Name, created_on
  # Output: None
  # Takes name, created_on (default value) and create a new template with arguments. Returns id
  @connection.exec_params("INSERT INTO templates (name, created_on) VALUES ($1, $2)", [name, created_on])

  result = @connection.exec_params("SELECT MAX(id) FROM templates")
  result.map do |tuple|
    {
      id: tuple["max"].to_i
    }
  end.first
end

def delete_template(id)
  # Input: id
  # Output: none
  # Deletes template with the id of inputted id
  # @connection.exec_params("DELETE FROM questions WHERE template_id = $1", [id])
  @connection.exec_params("DELETE FROM templates WHERE id = $1", [id])
end

def update_template_name(template_id, template_name)
  # Input: id, new template name
  # Output: none
  # Updates name of the template where id is id
  @connection.exec_params("UPDATE templates SET name = $1 WHERE id = $2", [template_name, template_id])
end

def create_template_question(value, created_on='NOW()', template_id)
  # Input: value, template_id
  # Output: None
  # Adds new question with template_id to questions table
  @connection.exec_params("INSERT INTO questions (value, created_on, template_id) VALUES ($1, $2, $3)", [value, created_on, template_id])
end

def update_template_question(question_id, value)
  # Input: id, template question
  # Output: none
  # Updates questions of template where id is id
  @connection.exec_params("UPDATE questions SET value = $1 WHERE id = $2", [value, question_id])
end

def find_template(id)
  # Input: id
  # Output: Template with id of id
result = @connection.exec_params("SELECT * FROM templates WHERE id = $1", [id])
result.map do |tuple|
  {
    template_id: tuple["id"].to_i,
    template_name: tuple["name"],
    created_on: tuple["created_on"],
  }
end.first
end

def find_questions_for_template(id)
  @connection.exec_params("SELECT * FROM questions WHERE template_id = $1", [id]).map do |tuple|
    {
      question_id: tuple["id"],
      question_value: tuple["value"],
      created_on: tuple["created_on"],
      answer: tuple["answer"]
    }
  end
end

def create_new_test(created_on='NOW()', template_id)
  # Input: created_on, template_id
  # Output: None
  # Creates a new test with columns of created_on and template_id
  @connection.exec_params("INSERT INTO tests (created_on, template_id) VALUES ($1, $2)", [created_on, template_id])

  result = @connection.exec_params("SELECT MAX(id) FROM tests")
  result.map do |tuple|
    {
      id: tuple["max"]
    }
  end.first
end

def delete_test_from_templates(id)
  # Input: a test_id
  # Output: None
  # Delete a test that has test_id

  @connection.exec_params("DELETE FROM tests WHERE id = $1", [id])
end

def find_tests_for_template(template_id)
  # Input: template_id
  # Output: Finds tests with template_id
  @connection.exec_params("SELECT * FROM tests WHERE template_id = $1", [template_id]).map do |tuple|
    {
      test_id: tuple["id"],
      created_on: tuple["created_on"]
    }
  end
end

def find_test(test_id)
  @connection.exec_params("SELECT * FROM tests WHERE id = $1", [test_id]).map do |tuple|
    {
      test_id: tuple["id"],
      created_on: tuple["created_on"]
    }
  end.first
end

def find_last_test_id
  result = @connection.exec_params("SELECT MAX(id) FROM tests")
  result.map do |tuple|
    {
      id: tuple["max"].to_i
    }
  end.first
end

def add_answer(question_id, test_id, answer)
  @connection.exec_params("INSERT INTO tests_questions (question_id, test_id, answer) VALUES ($1, $2, $3)", [question_id, test_id, answer])
end

def find_questions_and_answers_for_test(test_id)
  result = @connection.exec_params("SELECT tests_questions.id, question_id, test_id, answer, value, tests.created_on AS tests_created_on, questions.template_id FROM tests_questions JOIN questions ON questions.id = tests_questions.question_id JOIN tests ON tests.id = tests_questions.test_id WHERE test_id = $1", [test_id])

  result.map do |tuple|
    {
      id: tuple["id"].to_i,
      question_id: tuple["question_id"].to_i,
      test_id: tuple["test_id"].to_i,
      template_id: tuple["template_id"].to_i,
      question: tuple["value"],
      answer: tuple["answer"],
      test_created_on: tuple["test_created_on"]
    }
  end
end

  def setup_schema
    result = @connection.exec("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'questions';")

    if result[0]["count"] == "0"
      system 'psql -d ls_quiz < schema.sql'
    end
  end
end
