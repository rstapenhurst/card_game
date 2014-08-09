require 'test_helper'

class CardAttributesControllerTest < ActionController::TestCase
  setup do
    @card_attribute = card_attributes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:card_attributes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create card_attribute" do
    assert_difference('CardAttribute.count') do
      post :create, card_attribute: { attribute: @card_attribute.attribute, attribute_order: @card_attribute.attribute_order, card_template_id: @card_attribute.card_template_id, value: @card_attribute.value }
    end

    assert_redirected_to card_attribute_path(assigns(:card_attribute))
  end

  test "should show card_attribute" do
    get :show, id: @card_attribute
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @card_attribute
    assert_response :success
  end

  test "should update card_attribute" do
    patch :update, id: @card_attribute, card_attribute: { attribute: @card_attribute.attribute, attribute_order: @card_attribute.attribute_order, card_template_id: @card_attribute.card_template_id, value: @card_attribute.value }
    assert_redirected_to card_attribute_path(assigns(:card_attribute))
  end

  test "should destroy card_attribute" do
    assert_difference('CardAttribute.count', -1) do
      delete :destroy, id: @card_attribute
    end

    assert_redirected_to card_attributes_path
  end
end
