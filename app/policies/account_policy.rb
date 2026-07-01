class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def cache_keys?
    @account_user.administrator? || @account_user.agent?
  end

  def limits?
    @account_user.administrator? || @account_user.agent?
  end

  def billings?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def test_email?
    @account_user.administrator?
  end

  def update_active_at?
    true
  end

  def subscription?
    @account_user.administrator?
  end

  def checkout?
    @account_user.administrator?
  end

  def toggle_deletion?
    @account_user.administrator?
  end

  def topup_checkout?
    @account_user.administrator?
  end

  def sales_manage?
    @account_user.custom_role&.permissions&.include?('sales_manage') || @account_user.administrator?
  end
end
