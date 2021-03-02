require 'rails_helper'

# https://relishapp.com/rspec/rspec-core/v/2-5/docs/helper-methods/let-and-let
RSpec.feature "USER views other user profile", type: :feature do
  let!(:user_another_example) { FactoryBot.create :user }

  let(:user) { FactoryBot.create :user }

  let(:game1) { FactoryBot.create(:game, user: user_another_example, current_level: 1, finished_at: "2021-03-02 21:12:10") }
  let(:game2) { FactoryBot.create(:game, user: user_another_example, current_level: 2, finished_at: "2021-03-02 21:12:11") }
  let(:game3) { FactoryBot.create(:game, user: user_another_example, current_level: 3, finished_at: "2021-03-02 21:12:12") }

  scenario 'successfully' do
    visit '/'

    click_link user_another_example.name
    expect(page).to have_selector :table
    expect(page).to have_text(user_another_example.name)
    expect(page).not_to have_text('Сменить имя и пароль')

    # pry.binding

    expect(page).to have_content '#'
    expect(page).to have_content 'Дата'
    expect(page).to have_content 'Вопрос'
    expect(page).to have_content 'Выигрыш'
    expect(page).to have_content 'Подсказки'

    # save_and_open_page
  end
end
