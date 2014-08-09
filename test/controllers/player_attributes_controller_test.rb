require 'test_helper'

class PlayerAttributesControllerTest < ActionController::TestCase
  setup do
    @player_attribute = player_attributes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:player_attributes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create player_attribute" do
    assert_difference('PlayerAttribute.count') do
      post :create, player_attribute: { key: @player_attribute.key, player: @player_attribute.player, value: @player_attribute.value }
    end

    assert_redirected_to player_attribute_path(assigns(:player_attribute))
  end

  test "should show player_attribute" do
    get :show, id: @player_attribute
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @player_attribute
    assert_response :success
  end

  test "should update player_attribute" do
    patch :update, id: @player_attribute, player_attribute: { key: @player_attribute.key, player: @player_attribute.player, value: @player_attribute.value }
    assert_redirected_to player_attribute_path(assigns(:player_attribute))
  end

  test "should destroy player_attribute" do
    assert_difference('PlayerAttribute.count', -1) do
      delete :destroy, id: @player_attribute
    end

    assert_redirected_to player_attributes_path
  end
end
