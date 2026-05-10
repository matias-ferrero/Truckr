require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("foo@bar.com").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }

    it "requires a password (Devise :validatable)" do
      expect(build(:user, password: nil)).not_to be_valid
    end

    it "canonicalises email to lower-case on save" do
      user = create(:user, email: "MIXED@Case.Com")
      expect(user.email).to eq("mixed@case.com")
    end

    it "treats blank email as missing" do
      expect(build(:user, email: "   ")).not_to be_valid
    end

    it "does not have a tax_id or dni_or_cuit column — fiscal identity lives on Carrier/Shipper" do
      expect(User.column_names).not_to include("tax_id", "dni_or_cuit")
    end

    it "stores hashed password in encrypted_password (Devise convention)" do
      expect(User.column_names).to include("encrypted_password")
      expect(User.column_names).not_to include("password_digest")
    end
  end

  describe "password complexity" do
    let(:base) { build(:user, password: nil) }

    it "rejects passwords shorter than 8 characters" do
      base.password = "Ab1cdef"
      expect(base).not_to be_valid
      expect(base.errors[:password]).to be_present
    end

    it "rejects passwords without an uppercase letter" do
      base.password = "password1"
      expect(base).not_to be_valid
      expect(base.errors[:password]).to include(a_string_matching(/mayúscula/))
    end

    it "rejects passwords without a lowercase letter" do
      base.password = "PASSWORD1"
      expect(base).not_to be_valid
      expect(base.errors[:password]).to include(a_string_matching(/minúscula/))
    end

    it "rejects passwords without a digit" do
      base.password = "Password"
      expect(base).not_to be_valid
      expect(base.errors[:password]).to include(a_string_matching(/dígito/))
    end

    it "accepts a strong password" do
      base.password = "Password1"
      expect(base).to be_valid
    end
  end

  describe "Devise password verification" do
    it "valid_password? returns true for the right password" do
      user = create(:user, password: "Password123")
      expect(user.valid_password?("Password123")).to be true
    end

    it "valid_password? returns false for the wrong password" do
      user = create(:user, password: "Password123")
      expect(user.valid_password?("nope")).to be false
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:carrier).dependent(:destroy) }
    it { is_expected.to have_one(:shipper).dependent(:destroy) }
  end

  describe "role predicates (ADR-008)" do
    let(:user) { create(:user) }

    it "carrier? is false without a carrier row" do
      expect(user.carrier?).to be false
    end

    it "carrier? becomes true when a carrier row exists" do
      create(:carrier, user: user)
      expect(user.reload.carrier?).to be true
    end

    it "shipper? mirrors carrier? but on shippers" do
      expect(user.shipper?).to be false
      create(:shipper, user: user)
      expect(user.reload.shipper?).to be true
    end

    it "supports both roles on the same user" do
      create(:carrier, user: user)
      create(:shipper, user: user)
      expect(user.reload.carrier?).to be true
      expect(user.reload.shipper?).to be true
    end
  end

  describe "scopes" do
    let!(:with_carrier) { create(:user, :with_carrier) }
    let!(:with_shipper) { create(:user, :with_shipper) }
    let!(:without_role) { create(:user) }

    it ".carriers returns only users with a carrier row" do
      expect(User.carriers).to contain_exactly(with_carrier)
    end

    it ".shippers returns only users with a shipper row" do
      expect(User.shippers).to contain_exactly(with_shipper)
    end
  end

  describe "cascading destroy" do
    it "destroys carrier and shipper rows when the user is destroyed" do
      user = create(:user, :with_carrier, :with_shipper)
      expect { user.destroy }
        .to change(Carrier, :count).by(-1)
        .and change(Shipper, :count).by(-1)
    end
  end

  describe "ransack allowlists (ActiveAdmin)" do
    it "exposes safe attributes" do
      expect(User.ransackable_attributes).to include("email", "full_name")
      expect(User.ransackable_attributes).not_to include("encrypted_password")
    end

    it "exposes carrier and shipper associations" do
      expect(User.ransackable_associations).to contain_exactly("carrier", "shipper")
    end
  end
end
