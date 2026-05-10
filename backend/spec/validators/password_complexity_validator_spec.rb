require "rails_helper"

RSpec.describe PasswordComplexityValidator do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :password
      def self.name = "DummyPasswordHolder"
      validates :password, password_complexity: true
    end
  end

  it "is valid for a password with upper, lower, digit" do
    obj = dummy_class.new
    obj.password = "Aa1xxxxx"
    expect(obj).to be_valid
  end

  it "is invalid without an uppercase letter" do
    obj = dummy_class.new
    obj.password = "aa1xxxxx"
    expect(obj).not_to be_valid
    expect(obj.errors[:password]).to include(a_string_matching(/mayúscula/))
  end

  it "is invalid without a lowercase letter" do
    obj = dummy_class.new
    obj.password = "AA1XXXXX"
    expect(obj).not_to be_valid
    expect(obj.errors[:password]).to include(a_string_matching(/minúscula/))
  end

  it "is invalid without a digit" do
    obj = dummy_class.new
    obj.password = "Aaaxxxxx"
    expect(obj).not_to be_valid
    expect(obj.errors[:password]).to include(a_string_matching(/dígito/))
  end

  it "skips validation when password is blank (handled elsewhere)" do
    obj = dummy_class.new
    obj.password = nil
    expect(obj).to be_valid
  end
end
