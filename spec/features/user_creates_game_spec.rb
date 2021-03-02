require 'rails_helper'

RSpec.feature 'USER creates a game', type: :feature do
  let(:user) { FactoryBot.create :user }

  let!(:questions) do
    (0..14).to_a.map do |i|
      FactoryBot.create(
        :question, level: i,
        text: "Когда была куликовская битва номер #{i + 1}?",
        answer1: '1380', answer2: '1381', answer3: '1382', answer4: '1383'
      )
    end
  end

  # Hам надо авторизовать пользователя
  before(:each) do
    login_as user
  end

  # Сценарий успешного создания игры
  scenario 'successfully' do
    visit '/'

    # Кликаем по ссылке "Новая игра"
    click_link 'Новая игра'

    # Ожидаем, что попадем на нужный url
    expect(page).to have_current_path '/games/1'
    expect(page).to have_content 'Когда была куликовская битва номер 1?'
    expect(page).to have_content '1380'
    expect(page).to have_content '1381'
    expect(page).to have_content '1382'
    expect(page).to have_content '1383'

    # save_and_open_page
  end
end
