require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  context 'as admin user' do
    before :each do
      sign_in admin
    end

    describe 'GET #index' do
      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end

  context 'not logged into portus' do
    describe 'GET #index' do
      it 'redirects to login page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'as normal user' do
    before :each do
      sign_in user
    end

    describe 'GET #index' do
      it 'blocks access' do
        get :index
        expect(response.status).to eq(401)
      end
    end
  end

  context 'PUT toggle admin' do
    before :each do
      sign_in admin
    end

    it 'changes the admin value of an user'do
      put :toggle_admin, id: user.id, format: :js

      user.reload
      expect(user).to be_admin
      expect(response.status).to eq 200
    end

    it 'does not allow the current user to "un-admin" itself' do
      put :toggle_admin, id: admin.id, format: :js

      admin.reload
      expect(admin).to be_admin
      expect(response.status).to eq(403)
    end

  end

end
