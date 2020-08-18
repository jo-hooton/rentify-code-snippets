class AdminPages::ManagedProperties::TenantsController < AdminPages::AdminController
  layout 'adminstrap'

  load_resource :instruction, params: :instruction_id
  load_resource :tenant, params: :id, only: %i[update destroy]

  def create
    @tenancy = Tenancy.find(user_params[:tenants_attributes]['0'][:tenancy_id])
    @user = User.find_or_initialize_by(email: user_params[:email].strip)
    @user.assign_attributes(user_params.except(:email))
    @user.password = SecureRandom.hex unless @user.persisted?
    @user.tenants.last.assign_attributes(@user.slice(:name, :email, :phone))
    @user.validate_phone = true
    @user.needs_name = true
    if @user.save
      @tenancy.generate_and_send_ast
      @tenancy.update(lead_tenant: @user.tenants.last) if user_params[:tenants_attributes]['0'][:lead_tenant] == '1'
      flash[:notice] = "#{@user.first_name}'s details have been added!"
      respond_to do |format|
        format.json {
          render(
            json: {
              redirect_path: admin_pages_instruction_tenancy_path(@instruction, @tenancy)
            },
            status: :created
          )
        }
      end

    else
      respond_to do |format|
        format.json { render json: { errors: @user.errors }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @tenant.tenancy.lead_tenant = @tenant if user_params[:tenants_attributes]['0'][:lead_tenant] == '1'
    @user = @tenant.user
    @user.assign_attributes(user_params)
    @tenant.assign_attributes(@user.slice(:name, :email, :phone))
    @user.validate_phone = true
    @user.needs_name = true
    if @user.save && @tenant.save
      @tenant.tenancy.generate_and_send_ast
      flash[:notice] = "#{@user.first_name}'s details have been updated."
      respond_to do |format|
        format.json {
          render(
            json: {
              redirect_path: admin_pages_instruction_tenancy_path(@instruction, @tenant.tenancy)
            },
            status: :ok
          )
        }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @user.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @tenant.is_destroyable?
      @user = @tenant.user
      @tenant.destroy
      flash[:notice] = "#{@user.first_name} has been removed from tenancy."
      respond_to do |format|
        format.json {
          render(
            json: {
              redirect_path: admin_pages_instruction_tenancy_path(@instruction, @tenant.tenancy)
            },
            status: :ok
          )
        }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: "Cannot delete tenant." }, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :phone,
      tenants_attributes: %i(
        id permitted_occupier lead_tenant skip_financial_reference
        skip_landlord_reference tenancy_id
      )
    )
  end
end
