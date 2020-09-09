require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "redcarpet"

require_relative 'database_connection'

before do
  @storage = DatabaseConnection.new
end

after do
  @storage.close
end

def select_questions(params)
  params.select {|key, _| key.start_with?("question_")}
end

get "/" do
  redirect "/templates"
end

# GET /templates - view all templates
get "/templates" do
  @templates = @storage.all_templates

  erb :list_templates, layout: :layout
end

# GET /templates/new - create a new template
get "/templates/new" do
  erb :new_template, layout: :layout
end

# POST /templates - adds a new template to templates
post "/templates" do
  template_name = params["template_name"]
  template_id = @storage.create_new_template(template_name)[:id]
  questions = select_questions(params)

  questions.each do |key, value|
    @storage.create_template_question(value, template_id)
  end

  status 202
end

# GET /templates/template_id - view an individual template
get "/templates/:template_id" do
  @template_id = params[:template_id].to_i

  @template = @storage.find_template(@template_id)

  @questions = @storage.find_questions_for_template(@template_id)
  erb :list_template, layout: :layout
end

# GET /templates/template_id/edit - edit an individual test
get "/templates/:template_id/edit" do
  template_id = params[:template_id].to_i

  @template = @storage.find_template(template_id)
  @questions = @storage.find_questions_for_template(template_id)
  erb :edit_template, layout: :layout
end

post "/templates/:template_id" do
  template_name = params[:template_name]
  template_id = params[:template_id].to_i
  questions = select_questions(params)

  @storage.update_template_name(template_id, template_name)

  questions.each do |key, value|
    question_id = key.split("_")[-1].to_i
    @storage.update_template_question(question_id, value)
  end

  # redirect to templates/template_id
  redirect "/templates/#{template_id}"
end

post "/templates/:template_id/delete" do
  template_id = params[:template_id].to_i
  @storage.delete_template(template_id)

  redirect "/templates"
end

# GET /templates/template_id/tests
get "/templates/:template_id/tests" do
  @template_id = params[:template_id].to_i

  @template = @storage.find_template(@template_id)
  @tests = @storage.find_tests_for_template(@template_id)

  erb :list_tests, layout: :layout
end

# GET /templates/template_id/tests/new
get "/templates/:template_id/tests/new" do
  @template_id = params[:template_id].to_i
  @template = @storage.find_template(@template_id)
  # Create a new test
  @test_id = @storage.create_new_test(@template_id)[:id].to_i
  # Get that test
  @test = @storage.find_test(@test_id)
  @questions = @storage.find_questions_for_template(@template_id)
  # Send test and questions
  erb :new_test
end

# POST /templates/template_id/tests
post "/templates/:template_id/tests" do
  question_ids_and_answers = select_questions(params)
  template_id = params[:template_id].to_i
  test_id = @storage.find_last_test_id[:id].to_i

  question_ids_and_answers.each do |question_id, answer|
    id = question_id.split("_")[-1].to_i
    @storage.add_answer(id, test_id, answer)
  end

  redirect "/templates/#{template_id}/tests"
end

# GET /templates/template_id/tests/test_id
get "/templates/:template_id/tests/:test_id" do
  # Get questions and answers
  @template_id = params[:template_id].to_i
  @test_id = params[:test_id].to_i

  @questions_and_answers = @storage.find_questions_and_answers_for_test(@test_id)

  markdown_renderer = Redcarpet::Render::HTML.new(escape_html: true, prettify: true)
  @markdown_obj = Redcarpet::Markdown.new(markdown_renderer, extensions = {})

  erb :list_test, layout: :layout
end

# POST /templates/template_id/tests/test_id/delete
post "/templates/:template_id/tests/:test_id/delete" do
  template_id = params[:template_id].to_i
  test_id = params[:test_id].to_i
  @storage.delete_test_from_templates(test_id)

  redirect "/templates/#{template_id}/tests"
end
