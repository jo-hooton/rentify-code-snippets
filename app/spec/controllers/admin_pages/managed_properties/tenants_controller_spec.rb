require 'rails_helper'

describe AdminPages::ManagedProperties::TenantsController do
  before { login_with :admin }

  let!(:tenant) { create(:tenant, tenancy: tenancy, user: create(:user)) }
  let(:tenancy) { create(:tenancy, instruction: instruction, property: property) }
  let(:property) { create(:property) }
  let(:instruction) { create(:instruction_advantage, property: property) }

  describe 'on POST create' do
    let(:email) { 'name@name.com' }
    let(:lead_tenant) { "0" }

    let(:params) {
      {
        user: {
          first_name: 'Sam',
          last_name: 'Sam',
          email: email,
          phone: '07000000000',
          tenants_attributes: {
            '0' => {
              tenancy_id: tenancy.id,
              lead_tenant: lead_tenant
            }
          }
        },
        instruction_id: instruction.id
      }
    }

    def do_post(params = nil)
      post :create, params: params, format: :json
    end

    it 'creates the new user' do
      expect{ do_post(params) }.to change(User, :count).by 1
    end

    it 'responds with the correct path' do
      request = do_post(params)
      expect(request).to be_successful
      expect(request.body).to eq({ redirect_path: admin_pages_instruction_tenancy_path(instruction, tenancy) }.to_json)
    end
    it 'sets the correct flash notice' do
      do_post(params)
      expect(flash[:notice]).to eq("Sam's details have been added!")
    end

    context 'user exists on the tenancy' do
      let!(:existing_tenant) { create(:tenant, email: "name@name.com", user: existing_user, tenancy: tenancy) }
      let(:existing_user) { create(:user, email: "name@name.com") }
      it 'does not create new tenant' do
        expect{ do_post(params) }.to change(Tenant, :count).by 0
      end
    end
    context 'user exists but not on tenancy' do
      let!(:existing_user) { create(:user, email: "name@name.com") }

      it 'creates new tenant' do
        expect{ do_post(params) }.to change(Tenant, :count).by 1
      end
    end
    context 'invalid user' do
      let(:email) { nil }
      it 'does not create a new user' do
        expect{ do_post(params) }.to change(User, :count).by 0
      end
      it 'reponds with error message' do
        request = do_post(params)
        expect(request.status).to eq(422)
        body = JSON.parse(request.body)
        expect(body["errors"]["email"]).to eq(["Please enter a valid email address"])
      end
    end
    context 'lead tenant' do
      let(:lead_tenant) { "1" }
      it 'sets the lead tenant on the tenancy' do
        do_post(params)
        expect(tenancy.reload.lead_tenant).to eq(Tenant.last)
      end
    end
  end

  describe '#update' do
    let(:user_params) {
      {
        first_name: 'Sam',
        tenants_attributes: {
          '0' => {
            id: tenant.id,
            lead_tenant: '1'
          }
        }
      }
    }

    it 'updates the tenant' do
      patch :update, params: { instruction_id: instruction.id, id: tenant.id, user: user_params }, format: :json
      expect(tenant.reload.first_name).to eq("Sam")
    end

    it 'responds with the correct path' do
      request = patch :update, params: { instruction_id: instruction.id, id: tenant.id, user: user_params }, format: :json
      expect(request).to be_successful
      expect(request.body).to eq({ redirect_path: admin_pages_instruction_tenancy_path(instruction, tenant.tenancy) }.to_json)
    end

    it 'sets the correct flash notice' do
      patch :update, params: { instruction_id: instruction.id, id: tenant.id, user: user_params }, format: :json
      expect(flash[:notice]).to eq("Sam's details have been updated.")
    end

    context 'with errors' do
      before { tenancy.update_column :lead_tenant_id, tenant.id }
      let(:user_params) {
        {
          first_name: 'New',
          email: nil,
          tenants_attributes: {
            '0' => {
              id: tenant.id
            }
          }
        }
      }

      it 'reponds with 422' do
        patch :update, params: { instruction_id: instruction.id, id: tenant.id, user: user_params }, format: :json
        expect(response.status).to eq(422)
      end

      it 'responds with the error messages' do
        patch :update, params: { instruction_id: instruction.id, id: tenant.id, user: user_params }, format: :json
        expect(JSON.parse(response.body)["errors"]["email"]).to eq(["Please enter a valid email address"])
      end
    end

    context 'lead tenant' do
      let(:lead_tenant) { "1" }
      it 'sets the lead tenant on the tenancy' do
        patch :update, params: { instruction_id: instruction.id, id: tenant.id, user: user_params }, format: :json
        expect(tenancy.reload.lead_tenant).to eq(tenant)
      end
    end
  end

  describe '#destroy' do
    it 'deletes the tenant' do
      expect{ delete :destroy, params: { instruction_id: instruction.id, id: tenant.id }, format: :json }.to change(Tenant, :count).by(-1)
    end

    it 'responds with the correct path' do
      delete :destroy, params: { instruction_id: instruction.id, id: tenant.id }, format: :json
      expect(response).to be_successful
      expect(response.body).to eq({ redirect_path: admin_pages_instruction_tenancy_path(instruction, tenant.tenancy) }.to_json)
    end

    it 'sets the correct flash notice' do
      delete :destroy, params: { instruction_id: instruction.id, id: tenant.id }, format: :json
      expect(flash[:notice]).to eq("#{tenant.user.first_name} has been removed from tenancy.")
    end

    context 'with errors' do
      before do
        any_instance_of(Tenant) do |tenant|
          stub(tenant).is_destroyable? { false }
        end
      end
      it 'responds with 422' do
        delete :destroy, params: { instruction_id: instruction.id, id: tenant.id }, format: :json
        expect(response.status).to eq(422)
      end
      it 'responds with error message' do
        delete :destroy, params: { instruction_id: instruction.id, id: tenant.id }, format: :json
        expect(JSON.parse(response.body)["errors"]).to eq("Cannot delete tenant.")
      end
    end
  end
end
