require 'rails_helper'

# Тест (match) на шаблон users/show.html.erb
RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryBot.create(:user, name: 'PlayerName') }

  before(:each) do
    assign(:user, user)

    assign(:games, [
      double(name: "1 game"),
      double(name: "2 game")
    ])

    stub_template("users/_game.html.erb" => "<%= game.name %> <%= Time.now %>")
  end

  context 'user != current user' do
    before(:each) { render }

    it 'renders player names' do
      expect(rendered).to match 'Player'
      expect(rendered).to match 'PlayerName'
    end

    it 'shows users games list' do
      expect(rendered).to match /1/
      expect(rendered).to match /2/
    end

    it 'renders player names' do
      expect(rendered).to match 'Player'
    end

    it 'checks that other users cant see text and link to change pass' do
      expect(rendered).not_to match 'Сменить имя и пароль'
      expect(rendered).not_to have_link('Сменить имя и пароль', href: "/users/edit.#{user.id}")
    end
  end

  context 'user == current_user' do
    before(:each) do
      sign_in user
      render
    end

    it 'users can see link to change pass' do
      expect(rendered).to have_link('Сменить имя и пароль', href: "/users/edit.#{user.id}")
    end
  end
end
