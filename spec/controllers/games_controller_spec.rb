# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов для незалогиненного юзера (Анонимус)
  context 'Anonymous' do
    # из экшена show анона посылаем
    it '#show kick from' do
      get :show, id: game_w_questions.id

      # проверяем ответ
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    # аноним не может вызывать действие show у GamesController
    # game GET    /games/:id(.:format)            games#show
    it '#show get games without registration' do
      get :show, id: game_w_questions.id

      # expect(response.status).to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq 'Вам необходимо войти в систему или зарегистрироваться.'
    end

    # аноним не может создавать действие create у GamesController
    # games POST   /games(.:format)                games#create
    it '#create post games without registration' do
      post :create

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq 'Вам необходимо войти в систему или зарегистрироваться.'
    end

    # answer_game PUT    /games/:id/answer(.:format)     games#answer
    it '#answer put games without registration' do
      put :answer, id: game_w_questions.id

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq 'Вам необходимо войти в систему или зарегистрироваться.'
    end

    # take_money_game PUT    /games/:id/take_money(.:format) games#take_money
    it '#take_money put games without registration' do
      put :take_money, id: game_w_questions.id

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq 'Вам необходимо войти в систему или зарегистрироваться.'
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # юзер может создать новую игру
    it 'creates game' do
      # сперва накидаем вопросов, из чего собирать новую игру
      generate_questions(15)

      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      # проверяем состояние этой игры
      expect(game.finished?).to be false
      expect(game.user).to eq(user)

      # и редирект на страницу этой игры
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    # юзер пытается создать игру, не закончив старую
    it 'user creates second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be false
      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game)
      expect(game).to be_nil

      # и редирект на страницу старой игры
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    # юзер видит свою игру
    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      expect(game.finished?).to be false
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end

    # юзер не должен видеть чужую игру
    it '#show alien game' do
      alien_game = FactoryBot.create(:game_with_questions)

      get :show, id: alien_game.id

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(root_path) # user должен быть перенаправлен
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    # юзер отвечает на игру корректно - игра продолжается
    it 'answers correct' do
      right_answer = game_w_questions.current_game_question.correct_answer_key

      put :answer, id: game_w_questions.id, letter: right_answer

      game = assigns (:game)

      expect(game.finished?).to be false
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be true # удачный ответ не заполняет flash
    end

    # юзер неправильно отвечает на игру - игра заканчивается
    it 'answers wrong' do
      right_answer = game_w_questions.current_game_question.correct_answer_key
      wrong_answer = (['a', 'b', 'c', 'd'] - [right_answer]).sample

      put :answer, id: game_w_questions.id, letter: wrong_answer
      game = assigns(:game)

      expect(game.finished?).to be true

      user.reload
      expect(response).to redirect_to(user_path(user))
      expect(response.status).to be
      expect(flash[:alert]).to be
    end

    # тест на отработку "50/50"
    it 'uses fifty_fifty_help' do
      right_answer = game_w_questions.current_game_question.correct_answer_key

      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.fifty_fifty_used).to be false

      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :fifty_fifty
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be false
      expect(game.fifty_fifty_used).to be true
      expect(game.current_game_question.help_hash[:fifty_fifty]).to be_an Array
      expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
      expect(game.current_game_question.help_hash[:fifty_fifty]).to include(right_answer)
      expect(response).to redirect_to(game_path(game))
    end

    # тест на отработку "помощи зала"
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be false

      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be false
      expect(game.audience_help_used).to be true
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    # тест, пользователь берет деньги до конца игры
    it 'uses audience take_money' do
      game_w_questions.update_attribute(:current_level, 1)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)

      expect(game.finished?).to be true
      expect(game.prize).to be == 100

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end
  end
end
