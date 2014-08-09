require 'test_helper'

class CardPilesControllerTest < ActionController::TestCase
  setup do
    @card_pile = card_piles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:card_piles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create card_pile" do
    assert_difference('CardPile.count') do
      post :create, card_pile: { name: @card_pile.name }
    end

    assert_redirected_to card_pile_path(assigns(:card_pile))
  end

  test "should show card_pile" do
    get :show, id: @card_pile
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @card_pile
    assert_response :success
  end

  test "should update card_pile" do
    patch :update, id: @card_pile, card_pile: { name: @card_pile.name }
    assert_redirected_to card_pile_path(assigns(:card_pile))
  end

  test "should destroy card_pile" do
    assert_difference('CardPile.count', -1) do
      delete :destroy, id: @card_pile
    end

    assert_redirected_to card_piles_path
  end
end
